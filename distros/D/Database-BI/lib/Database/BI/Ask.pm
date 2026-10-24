package Database::BI::Ask;

use strict;
use warnings;

our $VERSION = '0.016.0';

use Carp                qw(croak);
use Database::BI::Util  qw(urlencode);
use Readonly;
use Scalar::Util        qw(looks_like_number);

Readonly my %SUPPORTED_KINDS => map { $_ => 1 }
	qw( bar pie line graph scatter heatmap stacked combo treemap histogram map table );

Readonly my %KIND_ROUTE => (
	pie       => 'pie',
	bar       => 'bar',
	line      => 'graph',
	graph     => 'graph',
	scatter   => 'scatter',
	heatmap   => 'heatmap',
	stacked   => 'stacked',
	combo     => 'combo',
	treemap   => 'treemap',
	histogram => 'histogram',
	map       => 'map',
	table     => '',
);

Readonly my @MEASURE_FUNCTIONS => qw( sum avg min max count count_distinct );

# ---------------------------------------------------------------------------
# ask(%args) -> { spec, url, valid => 1 } | { error => 'code_or_code:detail' }
#
# args:
#   question   -- natural language question (required)
#   spec_key   -- l= spec, e.g. "table:sales" (required for URL construction)
#   label      -- human-readable dataset name
#   columns    -- arrayref of { name, type } hashrefs (from infer_column_types)
#   ai_config  -- hashref { provider, api_key, model }
# ---------------------------------------------------------------------------
sub ask {
	my (%args) = @_;

	my $question  = $args{question}  // '';
	my $spec_key  = $args{spec_key}  // '';
	my $label     = $args{label}     // 'dataset';
	my $columns   = $args{columns}   // [];
	my $ai_config = $args{ai_config} // {};

	return { error => 'ask_no_question' }
		unless length $question;

	return { error => 'ask_unavailable' }
		unless length($ai_config->{api_key} // '');

	my $raw = eval { _call_llm($question, $label, $columns, $ai_config) };
	return { error => 'ask_provider_error' } if $@;

	my $visual = eval { _parse_visual($raw) };
	return { error => 'ask_unparseable' } unless ref $visual eq 'HASH';

	my %col_set = map { $_->{name} => 1 } @$columns;
	my $val_err = _validate_encode($visual, \%col_set);
	return { error => "ask_invalid_spec:$val_err" } if defined $val_err;

	my $url  = _build_url($visual, $spec_key);
	my $spec = _build_spec($visual, $label, $spec_key);

	return { spec => $spec, url => $url, valid => 1 };
}

# ---------------------------------------------------------------------------
# infer_column_types($records, $columns_aref) -> [{ name, type }, ...]
#
# Type is one of: 'number', 'date', 'string'
# ---------------------------------------------------------------------------
sub infer_column_types {
	my ($records, $columns) = @_;
	return [] unless ref $records eq 'ARRAY' && ref $columns eq 'ARRAY';

	my @result;
	for my $col (@$columns) {
		my @vals = grep { defined $_ && length $_ } map { $_->{$col} } @$records;
		push @result, { name => $col, type => _infer_type(\@vals) };
	}
	return \@result;
}

# ---------------------------------------------------------------------------
# Internal helpers
# ---------------------------------------------------------------------------

sub _infer_type {
	my ($vals) = @_;
	return 'string' unless @$vals;

	my $n       = scalar @$vals;
	my $numeric = grep { looks_like_number($_) } @$vals;
	return 'number' if $numeric / $n > 0.5;

	my $date = grep {
		/\A\d{4}-\d{2}-\d{2}\z/ || /\A\d{1,2}\/\d{1,2}\/\d{4}\z/
	} @$vals;
	return 'date' if $date / $n > 0.5;

	return 'string';
}

sub _call_llm {
	my ($question, $label, $columns, $ai_config) = @_;

	require LWP::UserAgent;
	require HTTP::Request;
	require JSON::PP;	# core since Perl 5.013009; MIN_PERL_VERSION is 5.020000

	my $col_lines = join("\n", map { "- $_->{name} ($_->{type})" } @$columns);
	my $kinds_str = join(', ', sort keys %SUPPORTED_KINDS);
	my $mfns_str  = join(', ', @MEASURE_FUNCTIONS);

	my $prompt = <<"PROMPT";
You are a data analysis assistant. Given a dataset and a question, return ONLY a JSON object describing one visualization. Do not include any explanation, markdown, or surrounding text -- just the JSON object.

Dataset: "$label"
Columns:
$col_lines

Available chart kinds: $kinds_str
Available measure functions: $mfns_str

Encode key rules per kind:
- pie: cat (required), val (optional)
- bar: cat (required), val (optional)
- line/graph: x (required), y (required), series (optional)
- scatter: x (required), y (required), series (optional), size (optional)
- heatmap: x (required), y (required), val (optional)
- stacked: cat (required), series (required), val (optional)
- combo: cat (required), bar_val (required), line_val (required)
- treemap: group (required), size (optional)
- histogram: col (required)
- map: lat+lon (required pair) or loc (required)
- table: no encode keys

Question: "$question"

Return ONLY valid JSON with this exact structure (no other text):
{"kind":"<kind>","title":"<short descriptive title>","encode":{"<key>":"<column name>"}}

Use only column names from the list above. Choose the most informative chart kind for the question.
PROMPT

	my $body = JSON::PP::encode_json({
		model      => ($ai_config->{model} // 'claude-haiku-5-5'),
		max_tokens => 256,
		messages   => [{ role => 'user', content => $prompt }],
	});

	my $ua  = LWP::UserAgent->new(timeout => 30);
	my $req = HTTP::Request->new(
		'POST',
		'https://api.anthropic.com/v1/messages',
		[
			'Content-Type'      => 'application/json',
			'x-api-key'         => $ai_config->{api_key},
			'anthropic-version' => '2023-06-01',
		],
		$body,
	);

	my $resp = $ua->request($req);
	croak sprintf('Provider error: %s', $resp->status_line) unless $resp->is_success;

	my $data = JSON::PP::decode_json($resp->decoded_content);
	my $text = eval { $data->{content}[0]{text} };
	croak 'No text in provider response' unless defined $text && length $text;
	return $text;
}

sub _parse_visual {
	my ($text) = @_;
	require JSON::PP;

	# Try the full text first (clean LLM response).
	my $v = eval { JSON::PP::decode_json($text) };

	# Fall back: LLM added preamble/suffix text around the JSON object.
	# A bracket-depth counter locates the first complete balanced {..} block.
	# This is safer than a greedy /\{.*\}/s regex, which captures from the
	# first '{' all the way to the LAST '}' in the string -- if the LLM
	# produced multiple JSON-like constructs the greedy form spans them all
	# and returns unparseable input.  The depth counter handles nested objects
	# and stops exactly at the matching brace.
	if (!ref $v) {
		my $start = index($text, '{');
		if ($start >= 0) {
			my ($depth, $end) = (0, -1);
			for my $i ($start .. length($text) - 1) {
				my $ch = substr($text, $i, 1);
				$depth++ if $ch eq '{';
				if ($ch eq '}') {
					$depth--;
					if ($depth == 0) { $end = $i; last }
				}
			}
			if ($end >= 0) {
				$v = eval { JSON::PP::decode_json(
					substr($text, $start, $end - $start + 1)
				) };
			}
		}
	}

	return undef unless ref $v eq 'HASH';
	return undef unless exists $v->{kind} && $SUPPORTED_KINDS{ $v->{kind} };
	return undef if defined $v->{encode} && ref $v->{encode} ne 'HASH';
	$v->{encode} //= {};
	return $v;
}

sub _validate_encode {
	my ($visual, $col_set) = @_;
	my $encode = $visual->{encode};
	return undef unless %$encode;

	for my $key (sort keys %$encode) {
		my $col = $encode->{$key};
		next unless defined $col && length $col;
		return $col unless $col_set->{$col};
	}
	return undef;
}

sub _build_url {
	my ($visual, $spec_key) = @_;
	my $kind   = $visual->{kind};
	my $encode = $visual->{encode} // {};

	if ($kind eq 'table') {
		if ($spec_key =~ /\Atable:(.+)\z/) {
			return "/view/$1";
		}
		(my $path = $spec_key) =~ s/\Apath://;
		return '/open?path=' . urlencode($path);
	}

	my $route  = $KIND_ROUTE{$kind} // $kind;
	my @params = ('l=' . urlencode($spec_key));
	for my $key (sort keys %$encode) {
		my $val = $encode->{$key};
		next unless defined $val && length $val;
		push @params, "$key=" . urlencode($val);
	}
	return "/$route?" . join('&', @params);
}

sub _build_spec {
	my ($visual, $label, $spec_key) = @_;
	return {
		name     => ($visual->{title} || "$label analysis"),
		datasets => [{ spec => $spec_key }],
		version  => 1,
		visuals  => [{
			kind    => $visual->{kind},
			title   => ($visual->{title} // ''),
			encode  => ($visual->{encode} // {}),
			options => {},
		}],
	};
}


1;

__END__

=head1 NAME

Database::BI::Ask - Natural language to analysis spec (Phase 5.1)

=head1 SYNOPSIS

  use Database::BI::Ask;

  my $typed = Database::BI::Ask::infer_column_types(\@records, \@columns);

  my $result = Database::BI::Ask::ask(
      question  => 'show me sales by region as a pie chart',
      spec_key  => 'table:sales',
      label     => 'sales',
      columns   => $typed,
      ai_config => { provider => 'anthropic', api_key => $key, model => 'claude-haiku-5-5' },
  );
  # $result = { spec => {...}, url => '/pie?l=...&cat=region', valid => 1 }

=head1 DESCRIPTION

Translates a plain-English question into a Phase 3 analysis spec by calling
the Anthropic Messages API.  The model receives only column names and types
-- never raw row data, file paths, or credentials.

The returned spec is validated before being returned to the caller: every
column name in the C<encode> section must appear in the supplied column list,
and the C<kind> must be a supported chart type.  An invalid spec is returned
as C<{ error =E<gt> 'ask_invalid_spec:...' }> and never executed.

The feature is entirely absent (returns C<ask_unavailable>) when no
C<api_key> is supplied, keeping the app functional with no AI configured.

=head1 FUNCTIONS

=head2 ask(%args)

Returns C<{ spec, url, valid =E<gt> 1 }> on success, or C<{ error =E<gt> 'code' }>
on failure.  Error codes: C<ask_no_question>, C<ask_unavailable>,
C<ask_provider_error>, C<ask_unparseable>, C<ask_invalid_spec:col>.

=head2 infer_column_types($records, $columns)

Infers each column's type (C<'number'>, C<'date'>, C<'string'>) from a
sample of records.  A column is C<'number'> when more than half its
non-empty values pass C<Scalar::Util::looks_like_number>.  It is C<'date'>
when more than half match C<YYYY-MM-DD> or C<M/D/YYYY>.  Otherwise C<'string'>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
