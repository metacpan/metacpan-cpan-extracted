package App::WebPerimeterScan::Report;

use strict;
use warnings;
use autodie qw(:all);

use HTML::Entities qw(encode_entities);
use JSON::PP ();
use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Sub::Private { mode => 'enforce' };

use App::WebPerimeterScan::I18N ();
use App::WebPerimeterScan::Findings ();
use parent -norequire, 'App::WebPerimeterScan::I18N';

our $VERSION = '0.001.0';

# Term::ANSIColor attributes per severity.
Readonly::Hash my %COLOR => (
	critical => 'bold red',
	high     => 'red',
	medium   => 'yellow',
	low      => 'cyan',
	info     => 'white',
);
Readonly::Scalar my $DEFAULT_COLOR => 'white';

# The rules drawn around each host in the text report.
Readonly::Scalar my $RULE_WIDTH => 60;
Readonly::Scalar my $HOST_RULE  => '=' x $RULE_WIDTH;
Readonly::Scalar my $LINE_RULE  => '-' x $RULE_WIDTH;

# Characters escaped in the HTML report: the markup set plus both quotes,
# because values are interpolated into attributes as well as text.
Readonly::Scalar my $HTML_UNSAFE => q{<>&"'};

# The finding columns of the HTML table, in order, and which of them are
# machine values shown in <code>.
Readonly::Array my @HTML_COLUMNS => qw(severity id title url file source detail evidence fix);
Readonly::Hash my %HTML_CODE     => map { $_ => 1 } qw(id url file source evidence);
Readonly::Hash my %HTML_HEADING  => (
	severity => 'html.col.severity', id => 'html.col.rule', title => 'html.col.title',
	url => 'html.col.url', file => 'html.col.file', source => 'html.col.source',
	detail => 'html.col.detail', evidence => 'html.col.evidence', fix => 'html.col.fix',
);

# The scan metadata every format takes.
Readonly::Hash my %META_SCHEMA => (
	version      => { type => 'string', optional => 1 },
	generated    => { type => 'string', optional => 1 },
	scope_source => { type => 'string', optional => 1 },
	requests     => { type => 'integer', min => 0, optional => 1 },
	hosts        => { type => 'arrayref', optional => 1 },
	color        => { type => 'boolean', optional => 1 },
);

Readonly::Scalar my $STYLE => <<'CSS';
  body { font-family: system-ui, sans-serif; margin: 2rem; color: #1b1b1b; }
  table { border-collapse: collapse; width: 100%; margin-bottom: 2rem; }
  th, td { border: 1px solid #d5d5d5; padding: 0.5rem; text-align: left; vertical-align: top; font-size: 0.9rem; }
  th { background: #f2f2f2; }
  code { font-family: ui-monospace, monospace; font-size: 0.85em; overflow-wrap: anywhere; }
  .pill { display: inline-block; padding: 0.25rem 0.75rem; border-radius: 999px; margin-right: 0.5rem; font-weight: 600; }
  .pills { list-style: none; padding: 0; }
  .critical { background: #7f1d1d; color: #fff; }
  .high { background: #fee2e2; }
  .medium { background: #fef3c7; }
  .low { background: #e0f2fe; }
  .info { background: #f1f5f9; }
  h1 { margin-bottom: 0.25rem; }
  .meta { color: #555; margin-bottom: 1.5rem; }
CSS

=encoding utf8

=head1 NAME

App::WebPerimeterScan::Report - text, JSON and HTML output

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Print a text report after a scan:

	use App::WebPerimeterScan::Report;

	my %meta = (
		version      => $App::WebPerimeterScan::VERSION,
		generated    => '2026-11-05T10:00:00Z',
		scope_source => 'scope.txt',
		requests     => $scanner->http->requests,
		hosts        => $scanner->host_reports,
	);
	print App::WebPerimeterScan::Report::as_text($scanner->findings, %meta);

Write the text report to a file, without colour codes:

	open my $out, '>', 'report.txt';
	print $out App::WebPerimeterScan::Report::as_text($findings, %meta, color => 0);
	close $out;

Save a JSON report for another program:

	open my $json, '>', 'report.json';
	print $json App::WebPerimeterScan::Report::as_json($findings, %meta);
	close $json;

Make an HTML page to send by e-mail:

	my $page = App::WebPerimeterScan::Report::as_html($findings, %meta);

The metadata is optional.  The smallest call is:

	print App::WebPerimeterScan::Report::as_text($findings);

=head1 DESCRIPTION

This module turns the findings of a scan into a report.  There are three
formats:

=over 4

=item * B<Text> (C<as_text>), for a terminal or a log.  It can use colour.

=item * B<JSON> (C<as_json>), for other programs.  The keys are always in
the same order, so two reports can be compared with C<diff>.

=item * B<HTML> (C<as_html>), a single page with its own style sheet and no
JavaScript, safe to open from an e-mail.

=back

Each function takes the findings collection first, then optional
I<metadata>, given as name =E<gt> value pairs:

	version       the version of the scanner
	generated     when the scan ran, as text
	scope_source  the name of the scope file
	requests      how many HTTP requests were sent
	hosts         the list from App::WebPerimeterScan->host_reports
	color         text only: 1 for colour, 0 for none

All three formats list the same findings in the same order, because the
order comes from L<App::WebPerimeterScan::Findings>.  The labels (such as
"Fix:") come from the message catalogue.  The text of each finding was
written when the finding was recorded.

=head1 REQUIREMENTS

C<JSON::PP> 4.00 for the JSON report and C<HTML::Entities> (part of
C<HTML::Parser>) for the HTML report.  C<Term::ANSIColor> is loaded only
when colour is used.

=head1 SUBROUTINES/METHODS

=head2 as_text

Purpose: the report for a terminal or a plain-text file.

Args: C<$findings>, then the named metadata above.  C<color> forces colour
on or off; when it is not given, colour is used only if STDOUT is a terminal.

Returns: the report as a string.

Side Effects: none (reads whether STDOUT is a terminal when C<color> is
not given).

Usage: C<< print as_text($findings, %meta); >>

=head3 EXAMPLE

	my $text = App::WebPerimeterScan::Report::as_text(
		$findings, version => '0.001.0', generated => '2026-11-05T00:00:00Z',
		scope_source => 'scope.txt', color => 0,
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		findings     => { type => 'object', isa => 'App::WebPerimeterScan::Findings', position => 0 },
		version      => { type => 'string', optional => 1 },
		generated    => { type => 'string', optional => 1 },
		scope_source => { type => 'string', optional => 1 },
		requests     => { type => 'integer', min => 0, optional => 1 },
		hosts        => { type => 'arrayref', optional => 1 },
		color        => { type => 'boolean', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'string' }

=head3 MESSAGES

	Message                                   Meaning / resolution
	----------------------------------------  -------------------------------
	Parameter 'findings' must be an object    Pass an App::WebPerimeterScan::
	... (fatal)                               Findings as the first argument.

=head3 PSEUDOCODE

	write the header: tool, version, time, scope, request count
	for each host: TLS line, certificate, open ports, pages scanned
	if there are no findings, say so (and that it is not proof) and stop
	for each finding, worst first
		start a new severity section when the severity changes
		write the id (coloured), title, URL, file, source, detail,
		evidence, fix and reference
	write the summary counts

=cut

sub as_text
{
	my ($findings, @rest) = @_;

	my $meta  = _meta($findings, \@rest);
	my $color = defined $meta->{color} ? $meta->{color} : (-t STDOUT ? 1 : 0);

	my @lines = (
		_t('report.header', { version => $meta->{version} // '', generated => $meta->{generated} // '' }),
		_t('report.scope', { scope => $meta->{scope_source} // '' }),
		defined $meta->{requests} ? _t('report.requests', { requests => $meta->{requests} }) : (),
		map { @{ _text_host($_) } } @{ $meta->{hosts} || [] },
	);
	push @lines, '';

	my $sorted = $findings->sorted;
	return join("\n", @lines, _t('report.clean')) . "\n" unless @{$sorted};

	my $counts = $findings->counts;
	my $current = '';
	for my $finding (@{$sorted}) {
		# A heading each time the severity changes, underlined to its width.
		if($current ne $finding->{severity}) {
			$current = $finding->{severity};
			my $heading = _t('report.section', { severity => uc $current, count => $counts->{$current} });
			push @lines, '', $heading, '-' x length $heading;
		}
		push @lines, @{ _text_finding($finding, $color) };
	}

	push @lines, _t('report.summary', { summary => join(', ',
		map { _t('report.summary_item', { count => $counts->{$_}, severity => $_ }) } @App::WebPerimeterScan::Findings::SEVERITIES
	) });

	return join("\n", @lines) . "\n";
}

=head2 as_json

Purpose: the machine-readable report.

Args: C<$findings>, then the named metadata above (C<color> is ignored).

Returns: canonical, pretty-printed JSON, with keys C<tool>, C<version>,
C<generated>, C<scope>, C<requests>, C<summary> (counts by severity),
C<hosts> and C<findings> (worst first, each with every field in
C<@App::WebPerimeterScan::Findings::FIELDS>).

Side Effects: none.

Usage: C<< print as_json($findings, %meta); >>

=head3 EXAMPLE

	my $data = JSON::PP::decode_json(App::WebPerimeterScan::Report::as_json($findings, %meta));
	print "$data->{summary}{high} high\n";

=head3 API SPECIFICATION

=head4 INPUT

	{
		findings     => { type => 'object', isa => 'App::WebPerimeterScan::Findings', position => 0 },
		version      => { type => 'string', optional => 1 },
		generated    => { type => 'string', optional => 1 },
		scope_source => { type => 'string', optional => 1 },
		requests     => { type => 'integer', min => 0, optional => 1 },
		hosts        => { type => 'arrayref', optional => 1 },
		color        => { type => 'boolean', optional => 1 },	# accepted and ignored
	}

=head4 OUTPUT

	{ type => 'string', matches => qr/\A\{/ }

=head3 MESSAGES

As C<as_text>.

=cut

sub as_json
{
	my ($findings, @rest) = @_;

	my $meta = _meta($findings, \@rest);

	my $data = {
		tool      => 'webperimeter',
		version   => $meta->{version},
		generated => $meta->{generated},
		scope     => $meta->{scope_source},
		requests  => $meta->{requests},
		summary   => $findings->counts,
		hosts     => $meta->{hosts},
		# The field list is the collector's, so the two cannot drift.
		findings  => [ map { my $f = $_; +{ map { $_ => $f->{$_} } @App::WebPerimeterScan::Findings::FIELDS } } @{ $findings->sorted } ],
	};

	return JSON::PP->new->canonical->pretty->encode($data);
}

=head2 as_html

Purpose: a self-contained HTML page for a browser or an e-mail.

Args: C<$findings>, then the named metadata above (C<color> is ignored).

Returns: the page as a string.

Side Effects: none.  Every value interpolated into the page is escaped,
including the version and timestamp, so a host name, a header value or the
caller's metadata cannot inject markup.

Usage: C<< print as_html($findings, %meta); >>

=head3 EXAMPLE

	open my $fh, '>', 'report.html';
	print $fh App::WebPerimeterScan::Report::as_html($findings, %meta);
	close $fh;

=head3 API SPECIFICATION

=head4 INPUT

	{
		findings     => { type => 'object', isa => 'App::WebPerimeterScan::Findings', position => 0 },
		version      => { type => 'string', optional => 1 },
		generated    => { type => 'string', optional => 1 },
		scope_source => { type => 'string', optional => 1 },
		requests     => { type => 'integer', min => 0, optional => 1 },
		hosts        => { type => 'arrayref', optional => 1 },
		color        => { type => 'boolean', optional => 1 },	# accepted and ignored
	}

=head4 OUTPUT

	{ type => 'string', matches => qr/\A<!DOCTYPE html>/ }

=head3 MESSAGES

As C<as_text>.

=head3 PSEUDOCODE

	escape every value before it is placed in the page
	build a pill per severity that has findings
	build a host row per host: TLS summary, open ports, pages scanned
	build a finding row per finding, worst first; one "no findings" row if none
	assemble the page from the catalogue's labels and the fixed stylesheet

=cut

sub as_html
{
	my ($findings, @rest) = @_;

	my $meta   = _meta($findings, \@rest);
	my $counts = $findings->counts;

	my $pills = join '', map {
		qq{<li class="pill $_">} . _escape("$_: $counts->{$_}") . '</li>'
	} grep { $counts->{$_} } @App::WebPerimeterScan::Findings::SEVERITIES;

	my $host_rows = join "\n", map { _html_host($_) } @{ $meta->{hosts} || [] };

	my @rows = map { _html_finding($_) } @{ $findings->sorted };
	my $rows = @rows ? join("\n", @rows)
		: '<tr><td colspan="' . scalar(@HTML_COLUMNS) . '">' . _escape(_t('html.no_findings')) . '</td></tr>';

	my $heads = join '', map { '<th>' . _escape(_t($HTML_HEADING{$_})) . '</th>' } @HTML_COLUMNS;
	my $host_heads = join '', map { '<th>' . _escape(_t($_)) . '</th>' }
		qw(html.col.host html.col.tls html.col.ports html.col.urls);

	# Everything below is escaped text or fixed markup.
	my $title = _escape(_t('html.title', { generated => $meta->{generated} // '' }));
	my $line  = join ' &middot; ', map { _escape($_) } grep { length }
		'webperimeter ' . ($meta->{version} // ''),
		$meta->{generated} // '',
		_t('html.scope', { scope => $meta->{scope_source} // '' }),
		defined $meta->{requests} ? _t('html.requests', { requests => $meta->{requests} }) : '';

	return join "\n",
		'<!DOCTYPE html>',
		'<html lang="' . _escape(App::WebPerimeterScan::I18N->language) . '">',
		'<head>',
		'<meta charset="utf-8">',
		"<title>$title</title>",
		"<style>\n$STYLE</style>",
		'</head>',
		'<body>',
		'<h1>' . _escape(_t('html.heading')) . '</h1>',
		qq{<div class="meta">$line</div>},
		qq{<ul class="pills">$pills</ul>},
		'<h2>' . _escape(_t('html.hosts')) . '</h2>',
		"<table>\n<thead><tr>$host_heads</tr></thead>\n<tbody>$host_rows</tbody>\n</table>",
		'<h2>' . _escape(_t('html.findings')) . '</h2>',
		"<table>\n<thead><tr>$heads</tr></thead>\n<tbody>$rows</tbody>\n</table>",
		'</body>',
		'</html>',
		'';
}

# _meta
# Purpose:     validate the findings and the metadata every format takes.
# Entry:       $rest is the remaining @_ as an arrayref.
# Exit:        the validated metadata hashref.
# Side effects: croaks on a bad argument.
sub _meta :Private
{
	my ($findings, $rest) = @_;

	my $args = validate_strict(
		schema => { %META_SCHEMA, findings => { type => 'object', isa => 'App::WebPerimeterScan::Findings' } },
		input  => { %{ get_params(undef, $rest) // {} }, findings => $findings },
	);
	delete $args->{findings};

	return $args;
}

# _t
# Purpose:     shorthand for a catalogue lookup from a function.
# Entry:       as I18N::i18n.
# Exit:        the rendered text.
# Side effects: none.
sub _t :Private
{
	my ($key, $args) = @_;

	return __PACKAGE__->i18n($key, $args);
}

# _escape
# Purpose:     HTML-escape a value for text or an attribute.
# Entry:       $text may be undef.
# Exit:        the escaped string ('' for undef).
# Side effects: none.
sub _escape :Private
{
	my ($text) = @_;

	return encode_entities($text // '', $HTML_UNSAFE);
}

# _tls_summary
# Purpose:     the facts about a host's TLS that both reports show.
# Entry:       $tls is an inspect() result or undef.
# Exit:        hashref of protocol, cipher, ok, days, not_after, error.
# Side effects: none.
sub _tls_summary :Private
{
	my ($tls) = @_;

	my $unknown = _t('report.unknown');

	return {
		ok        => $tls && $tls->{ok} ? 1 : 0,
		protocol  => $tls->{protocol} // '?',
		cipher    => $tls->{cipher} // '?',
		days      => $tls->{days_left},
		not_after => $tls->{not_after} // $unknown,
		error     => $tls->{error} // $unknown,
	};
}

# _text_host
# Purpose:     the text block for one host.
# Entry:       $host is a host report.
# Exit:        arrayref of lines.
# Side effects: none.
sub _text_host :Private
{
	my ($host) = @_;

	my @lines = ('', $HOST_RULE, $host->{host}, $LINE_RULE);

	if(my $tls = $host->{tls}) {
		my $summary = _tls_summary($tls);
		if($summary->{ok}) {
			my $expiry = defined $summary->{days} ? _t('report.tls_expiry', $summary) : _t('report.unknown');
			push @lines, _t('report.tls', { %{$summary}, expiry => $expiry }),
				_t('report.certificate', { subject => $tls->{subject} // '?', issuer => $tls->{issuer} // '?' });
		} else {
			push @lines, _t('report.tls_failed', $summary);
		}
	}

	if(exists $host->{open_ports}) {
		my $ports = join ', ', map { $_->{port} } @{ $host->{open_ports} || [] };
		push @lines, _t('report.open_ports', { ports => length $ports ? $ports : _t('report.no_open_ports') });
	}

	push @lines, _t('report.urls_scanned', { count => scalar @{ $host->{urls} || [] } });

	return \@lines;
}

# _text_finding
# Purpose:     the text block for one finding.
# Entry:       $finding has every field (Findings guarantees it).
# Exit:        arrayref of lines, ending with a blank line.
# Side effects: loads Term::ANSIColor when $color is true.
sub _text_finding :Private
{
	my ($finding, $color) = @_;

	my $id = "[$finding->{id}]";
	if($color) {
		require Term::ANSIColor;
		$id = Term::ANSIColor::colored($id, $COLOR{ $finding->{severity} } // $DEFAULT_COLOR);
	}

	# Evidence can span lines (a body excerpt); keep it to one.
	(my $evidence = $finding->{evidence}) =~ s/\s+/ /g;

	my @lines = ("$id $finding->{title}");
	push @lines, "  $finding->{url}"                                  if length $finding->{url};
	push @lines, _t('report.file', { file => $finding->{file} })       if length $finding->{file};
	push @lines, _t('report.in_source', { source => $finding->{source} }) if length $finding->{source};
	push @lines, "  $finding->{detail}"                               if length $finding->{detail};
	push @lines, _t('report.evidence', { evidence => $evidence })      if length $evidence;
	push @lines, _t('report.fix', { fix => $finding->{fix} })          if length $finding->{fix};
	push @lines, _t('report.see', { reference => $finding->{reference} }) if length $finding->{reference};

	return [ @lines, '' ];
}

# _html_host
# Purpose:     the HTML table row for one host.
# Entry:       $host is a host report.
# Exit:        the row, every value escaped.
# Side effects: none.
sub _html_host :Private
{
	my ($host) = @_;

	my $summary = _tls_summary($host->{tls});
	my $tls = $summary->{ok}
		? _t('html.tls', $summary) . (defined $summary->{days} ? _t('html.days_left', $summary) : '')
		: _t('html.not_inspected');
	my $ports = exists $host->{open_ports} ? join(', ', map { $_->{port} } @{ $host->{open_ports} || [] }) : '';

	return '<tr>' . join('', map { '<td>' . _escape($_) . '</td>' }
		$host->{host}, $tls, $ports, scalar @{ $host->{urls} || [] }) . '</tr>';
}

# _html_finding
# Purpose:     the HTML table row for one finding.
# Entry:       $finding's severity is one of @SEVERITIES (Findings ensures
#              it), so it is safe as a class name once escaped.
# Exit:        the row, every value escaped.
# Side effects: none.
sub _html_finding :Private
{
	my ($finding) = @_;

	my $cells = join '', map {
		my $value = _escape($finding->{$_});
		'<td>' . ($HTML_CODE{$_} ? "<code>$value</code>" : $value) . '</td>'
	} @HTML_COLUMNS;

	return '<tr class="' . _escape($finding->{severity}) . qq{">$cells</tr>};
}

1;

__END__

=head1 COMMON PITFALLS

=over 4

=item * B<These are functions, not methods.>  Call
C<App::WebPerimeterScan::Report::as_text($findings, ...)>.  Writing
C<< App::WebPerimeterScan::Report->as_text($findings) >> passes the class
name as the first argument, and the call dies.

=item * B<A misspelt metadata name is fatal.>  C<< scope => 'x' >> dies
with "Unknown parameter"; the name is C<scope_source>.

=item * B<Colour codes in a file.>  When C<color> is not given, the text
report uses colour if STDOUT is a terminal, even if you write the report
to a file.  Pass C<< color => 0 >> when the report is not for the screen.

=item * B<C<undef> metadata is the same as leaving it out.>  For example,
C<< requests => undef >> is accepted, and no request count is shown.

=item * B<Without C<hosts>, the per-host details are missing.>  The TLS
summary, the open ports and the list of pages appear only when C<hosts>
is given.  The findings are listed either way.

=item * B<The reports return a string; they do not print.>  Print the result
yourself.

=back

=head1 ENCODING

=over 4

=item * B<The output has the same kind of string as the input.>  The
scanner gives byte strings (UTF-8 from web pages stays as UTF-8 bytes), so
the reports are byte strings with correct UTF-8.  Print them with no
encoding layer.

=item * B<If you give character strings,> the result is a character string;
print it through C<:encoding(UTF-8)>.  Do not mix the two kinds; see
L<App::WebPerimeterScan::Findings/ENCODING>.

=item * B<HTML:> the page declares C<< <meta charset="utf-8"> >>.  Every
value is escaped with L<HTML::Entities>, so C<< < >>, C<< > >>, C<&> and
quotes cannot break the page.  Other characters, including non-ASCII
UTF-8 bytes, are copied unchanged.  The page relies on its charset
declaration to show them correctly.

=item * B<JSON:> non-ASCII bytes are copied into the output unchanged, so
UTF-8 input gives valid UTF-8 JSON, which C<decode_json> reads back.

=item * B<Text:> printed as it is.  A terminal that is not set to UTF-8 shows
non-ASCII text wrongly, but the bytes in the report are correct.

=back

=head1 LIMITATIONS

=over 4

=item * The text report wraps nothing: a long title or evidence line is one
long line.

=item * Colour is decided by whether STDOUT is a terminal, even when the
caller will write the string somewhere else; pass C<color> to be explicit.

=item * The HTML report embeds its stylesheet and has no script, so it is
safe to open from e-mail, but it cannot sort or filter.

=back

=head1 FORMAL SPECIFICATION

This section states exactly what each method does, in the Z notation.  You
do not need it to use the module: the method descriptions above say the same
thing in words.  It is here for reviewers and for anyone who writes tests.

How to read a schema box:

=over 4

=item * The part above the middle line declares names.  A name that ends in
C<?> is an input.  A name that ends in C<!> is an output.

=item * The part below the middle line lists facts that are true after the
call.

=item * A name with a dash after it, such as C<items'>, is the value after
the call.  The same name without the dash is the value before the call.

=item * C<Delta X> (written with the Greek capital delta) means the call
may change the state C<X>.  C<Xi X> (the Greek capital xi) means the call
does not change it.

=back

The symbols used are:

	Δ   may change            Ξ   does not change      •   such that
	∀   for all               ∃   there is             ¬   not
	∧   and                   ∨   or                   ⇒   implies
	⇔   if and only if        ≠   not equal            ≤ ≥ at most, at least
	∈   is in                 ∉   is not in            ⊆   is a subset of
	∪   union                 ∩   intersection         ∅   the empty set
	ℙ X sets of X             ⊥   undefined (undef)    …   and so on
	⟨⟩  the empty sequence    ⁀   join sequences       ⇸   partial mapping
	↦   maps to               ⊕   override a mapping   ↾   keep only these keys
	∘   compose               →   function             × ÷ − times, divide, minus
	ℕ   0, 1, 2, ...          ℕ₁  1, 2, 3, ...         ℝ   real numbers
	𝔹   true or false         ⌊x⌋ x rounded down
	dom M  the keys of M      ran M  the values of M   #S  the size of S


=head2 as_text

	┌─ AsText ────────────────────────────────────────────
	│ ΞFindings; meta? : META; result! : TEXT
	├─────────────────────────────────────────────────────
	│ header(meta?) prefix_of result!
	│ ∀ h ∈ ran meta?.hosts • host_block(h) in result!
	│ items = ⟨⟩ ⇒ clean_message suffix_of result!
	│ items ≠ ⟨⟩ ⇒ ∀ f ∈ ran sorted • "[" ⁀ f.id ⁀ "]" in result!
	│            ∧ summary(counts) suffix_of result!
	└─────────────────────────────────────────────────────

=head2 as_json

	┌─ AsJson ────────────────────────────────────────────
	│ ΞFindings; meta? : META; result! : JSON
	├─────────────────────────────────────────────────────
	│ decode(result!).findings = ⟨ f ↾ FIELDS | f ∈ sorted ⟩
	│ decode(result!).summary = counts
	│ decode(result!).hosts = meta?.hosts
	└─────────────────────────────────────────────────────

=head2 as_html

	┌─ AsHtml ────────────────────────────────────────────
	│ ΞFindings; meta? : META; result! : HTML
	├─────────────────────────────────────────────────────
	│ ∀ v ∈ values(meta?) ∪ values(ran items) •
	│     escape(v) in result! ∧ (v ≠ escape(v) ⇒ ¬ (v in result!))
	│ #rows(result!) = max(1, #items)
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

The module keeps no state.  Each function reads the findings and the
metadata and returns a new string; nothing is changed.  Every format contains
the parts below, but each one lays them out in its own way.

	  findings + metadata
	        |
	        v
	  +----------------+
	  |   VALIDATE     |--- the first argument is not a findings
	  +----------------+    collection, or a metadata name is unknown
	        |                  -> croak
	        v
	  +----------------+
	  |   HEADER       |  tool, version, time, scope file, request count
	  +----------------+
	        |
	        v
	  +----------------+
	  |   HOSTS        |  for each entry in 'hosts': TLS summary,
	  +----------------+  certificate, open ports, pages scanned
	        |
	        v
	  +----------------+
	  |   FINDINGS     |  in the order of findings->sorted; or the
	  +----------------+  "no findings" message
	        |
	        v
	  +----------------+
	  |   SUMMARY      |  the count at each severity
	  +----------------+
	        |
	        +--------------+---------------+
	        | as_text      | as_json       | as_html
	        v              v               v
	   lines of text,   one JSON        one HTML page; every
	   coloured if      object, keys    value escaped
	   'color' is on    sorted

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
