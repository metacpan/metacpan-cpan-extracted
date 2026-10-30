package Database::BI::Summary;

use strict;
use warnings;

our $VERSION = '0.018.0';

use Carp        qw(croak);
use Digest::MD5 qw(md5_hex);
use Readonly;

Readonly my $MAX_SUMMARY_INSIGHTS => 5;
Readonly my $CACHE_TTL_S          => 3600;   # 1 hour

my %_cache;   # fingerprint => { text, source, ts }

# ---------------------------------------------------------------------------
# generate(%args) -> { text, source, cached }
#
# args:
#   insights    arrayref of insight hashrefs (from Insights::compute)
#   spec_key    the l= spec value (used internally; never sent to LLM)
#   label       human-readable dataset name
#   row_count   number of rows analysed
#   ai_config   optional hashref { provider, api_key, model }
#   use_ai      1 to request LLM polish (honoured only when ai_config is set
#               and ai_config->{api_key} is non-empty)
# ---------------------------------------------------------------------------
sub generate {
	my (%args) = @_;
	my $insights  = $args{insights}  // [];
	my $label     = $args{label}     // 'dataset';
	my $row_count = $args{row_count} // 0;
	my $use_ai    = ($args{use_ai} && $args{ai_config}
	                 && length($args{ai_config}{api_key} // ''))
	                ? 1 : 0;
	my $ai_config = $use_ai ? $args{ai_config} : undef;

	my $fp = _fingerprint($insights, $use_ai, $label, $row_count);
	if (my $cached = $_cache{$fp}) {
		if ((time() - $cached->{ts}) < $CACHE_TTL_S) {
			return { text => $cached->{text}, source => $cached->{source}, cached => 1 };
		}
	}

	my ($text, $source);
	if ($use_ai) {
		eval { ($text, $source) = _llm_summary($insights, $label, $row_count, $ai_config) };
		if ($@) {
			$text   = _template_summary($insights, $label, $row_count);
			$source = 'template_fallback';
		}
	} else {
		$text   = _template_summary($insights, $label, $row_count);
		$source = 'template';
	}

	$_cache{$fp} = { text => $text, source => $source, ts => time() };
	return { text => $text, source => $source, cached => 0 };
}

# ---------------------------------------------------------------------------
# _fingerprint(\@insights, $use_ai) -> $hex
# ---------------------------------------------------------------------------
sub _fingerprint {
	my ($insights, $use_ai, $label, $row_count) = @_;
	my $str = ($use_ai ? 'ai:' : 'tmpl:')
	        . "L:${label}:R:${row_count}:"
	        . join('|', map { "$_->{kind}:$_->{headline}" } @$insights);
	return md5_hex($str);
}

# ---------------------------------------------------------------------------
# _template_summary(\@insights, $label, $row_count) -> $text
# ---------------------------------------------------------------------------
sub _template_summary {
	my ($insights, $label, $row_count) = @_;
	my @sentences;
	push @sentences, sprintf('%s: %d row%s analysed.',
		$label, $row_count, ($row_count == 1 ? '' : 's'));

	my %by_kind;
	for my $ins (@$insights) {
		push @{ $by_kind{ $ins->{kind} } }, $ins;
	}

	my $count = 0;
	for my $kind (qw(outlier period_delta top_mover seasonality)) {
		last if $count >= $MAX_SUMMARY_INSIGHTS;
		my $items = $by_kind{$kind} or next;
		my $first = $items->[0];
		if ($kind eq 'outlier') {
			my $n = scalar @$items;
			if ($n == 1) {
				push @sentences, "An unusual value was detected: $first->{headline}.";
			} else {
				push @sentences, "$n outliers detected, including: $first->{headline}.";
			}
		} elsif ($kind eq 'period_delta') {
			push @sentences, "$first->{headline}. $first->{detail}.";
		} elsif ($kind eq 'top_mover') {
			push @sentences, "Top movement: $first->{headline}.";
		} elsif ($kind eq 'seasonality') {
			push @sentences, "A repeating seasonal pattern was detected: $first->{headline}.";
		}
		$count++;
	}

	push @sentences, 'No significant patterns were detected.' if $count == 0;
	return join(' ', @sentences);
}

# ---------------------------------------------------------------------------
# _llm_summary(\@insights, $label, $row_count, $ai_config) -> ($text, 'llm')
#
# Sends only aggregate facts (insight kinds, headlines, details) to the LLM.
# Never sends file paths, raw row data, or the spec_key.
# ---------------------------------------------------------------------------
sub _llm_summary {
	my ($insights, $label, $row_count, $ai_config) = @_;

	my $provider = lc($ai_config->{provider} // 'anthropic');
	croak "Unsupported AI provider: $provider" unless $provider eq 'anthropic';

	my $n = scalar @$insights;
	$n = $MAX_SUMMARY_INSIGHTS if $n > $MAX_SUMMARY_INSIGHTS;
	my @facts = map { "- [$_->{kind}] $_->{headline}. $_->{detail}" }
	            @{$insights}[0 .. $n - 1];

	my $prompt = 'Summarise these data insights about "' . $label . '" ('
	           . $row_count . ' rows) in 2-3 plain-English sentences. '
	           . "Use only the facts provided:\n\n"
	           . join("\n", @facts)
	           . "\n\nSummary:";

	my $response_text = _call_anthropic($prompt, $ai_config);
	$response_text =~ s/\A\s+//;
	$response_text =~ s/\s+\z//;
	return ($response_text, 'llm');
}

# ---------------------------------------------------------------------------
# _call_anthropic($prompt, $ai_config) -> $response_text
# ---------------------------------------------------------------------------
sub _call_anthropic {
	my ($prompt, $ai_config) = @_;

	require LWP::UserAgent;
	require HTTP::Request;
	require JSON::PP;	# core since Perl 5.013009; MIN_PERL_VERSION is 5.028000

	my $model   = $ai_config->{model} // 'claude-haiku-5-5';
	my $api_key = $ai_config->{api_key};

	my $body = JSON::PP::encode_json({
		model      => $model,
		max_tokens => 256,
		messages   => [{ role => 'user', content => $prompt }],
	});

	my $ua  = LWP::UserAgent->new(timeout => 30);
	my $req = HTTP::Request->new(
		'POST',
		'https://api.anthropic.com/v1/messages',
		[
			'Content-Type'      => 'application/json',
			'x-api-key'         => $api_key,
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

1;

__END__

=head1 NAME

Database::BI::Summary - Narrative summary generation for an analysis result

=head1 SYNOPSIS

  use Database::BI::Summary;

  my $result = Database::BI::Summary::generate(
      insights  => $insights_aref,   # from Database::BI::Insights::compute()
      label     => 'sales',
      row_count => 39,
  );
  # $result = { text => "...", source => "template", cached => 0 }

=head1 DESCRIPTION

Generates a 2-4 sentence plain-English summary of an analysis result.  Two
paths are available:

=over 4

=item Template path (default, always offline)

Composes deterministic sentences from the insight kinds and headlines.
No external service required.

=item LLM path (opt-in)

Sends only aggregate facts (insight kinds, headlines, and detail strings)
to the Anthropic Messages API.  Raw row data, file paths, and the spec_key
are never included in the LLM prompt.  The LLM path falls back silently to
the template path if the provider call fails.

=back

Results are cached in a package-level hash keyed by an MD5 fingerprint of the
insight content.  Cached results are served for up to one hour.

=head1 FUNCTIONS

=head2 generate(%args)

  my $result = Database::BI::Summary::generate(
      insights  => \@insights,
      spec_key  => 'table:sales',
      label     => 'sales',
      row_count => 39,
      use_ai    => 0,
      ai_config => undef,
  );

Returns a hashref with keys C<text>, C<source> (C<'template'>,
C<'template_fallback'>, or C<'llm'>), and C<cached> (1 if served from cache,
0 if freshly generated).

C<use_ai> is only honoured when C<ai_config> is provided and
C<ai_config-E<gt>{api_key}> is non-empty.

=head3 API SPECIFICATION

=head4 INPUT

	{
	    insights  => 'arrayref',  # optional; insight hashrefs from Database::BI::Insights::compute (default [])
	    spec_key  => 'string',    # optional; accepted for the caller's bookkeeping, never sent to the LLM
	    label     => 'string',    # optional; dataset name (default "dataset")
	    row_count => 'integer',   # optional; rows analysed (default 0)
	    use_ai    => 'boolean',   # optional; ask for LLM prose
	    ai_config => 'hashref',   # optional; { api_key, model, provider }
	}

=head4 OUTPUT

	{
	    text   => 'string',                                  # 2-4 sentences
	    source => 'template' | 'template_fallback' | 'llm',
	    cached => 0 | 1,
	}

C<generate> does not croak.  A failed provider call gives the template text
with C<source =E<gt> 'template_fallback'>.  The same insights, label, row count
and C<use_ai> within an hour return the cached text with C<cached =E<gt> 1>.

=head1 AUTHOR

Nigel Horne C<< <njh@nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.

=cut
