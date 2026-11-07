package App::WebPerimeterScan::Findings;

use strict;
use warnings;
use autodie qw(:all);

use Params::Get qw(get_params);
use Params::Validate::Strict qw(validate_strict);
use Readonly;
use Scalar::Util qw(refaddr);
use Sub::Private { mode => 'enforce' };

use App::WebPerimeterScan::I18N ();
use parent -norequire, 'App::WebPerimeterScan::I18N';

our $VERSION = '0.001.0';

# Worst first.  Exported by name because the report formats walk it.
Readonly::Array our @SEVERITIES => qw(critical high medium low info);

# Every field a finding carries, in report order.  The JSON report uses the
# same list, so the two can never disagree about what a finding is.
Readonly::Array our @FIELDS => qw(id severity host url title detail evidence fix reference file source);

# Numeric rank of each severity, for sorting and thresholds.
Readonly::Hash my %RANK => (
	critical => 5,
	high     => 4,
	medium   => 3,
	low      => 2,
	info     => 1,
);

# What an unknown or missing severity becomes, and the id of a finding that
# was added without one.
Readonly::Scalar my $DEFAULT_SEVERITY => 'info';
Readonly::Scalar my $DEFAULT_ID       => 'finding';

# Fields annotate() may change after a finding is recorded: the source-aware
# pass fills them in once the whole scan is known.
Readonly::Hash my %ANNOTATABLE => (file => 1, source => 1);

# Joins the parts of a de-duplication key.  NUL cannot occur in any of them.
Readonly::Scalar my $KEY_SEPARATOR => "\0";

# Input schema for add(); report() accepts the same keys minus the text.
Readonly::Hash my %ADD_SCHEMA => (
	id        => { type => 'string', optional => 1 },
	severity  => { type => 'string', optional => 1 },
	host      => { type => 'string', optional => 1 },
	url       => { type => 'string', optional => 1 },
	key       => { type => 'string', optional => 1 },
	title     => { type => 'string', optional => 1 },
	detail    => { type => 'string', optional => 1 },
	evidence  => { type => 'string', optional => 1 },
	fix       => { type => 'string', optional => 1 },
	reference => { type => 'string', optional => 1 },
	file      => { type => 'string', optional => 1 },
	source    => { type => 'string', optional => 1 },
);

=encoding utf8

=head1 NAME

App::WebPerimeterScan::Findings - collect and order scan results

=head1 VERSION

Version 0.001.0

=head1 SYNOPSIS

Record a finding whose text comes from the message catalogue.  This is what
the scanner's own rules do:

	use App::WebPerimeterScan::Findings;

	my $findings = App::WebPerimeterScan::Findings->new;

	$findings->report('csp-missing',
		severity => 'medium',
		host     => 'example.com',
		vars     => { url => 'https://example.com/' },
	);

Record a finding with your own text, for example from a site-specific
check that has no catalogue entry:

	$findings->add(
		id       => 'staging-banner',
		severity => 'low',
		host     => 'example.com',
		title    => 'The staging banner is visible in production',
		fix      => 'Remove the banner from the production template.',
	);

Print a summary, worst finding first:

	printf "%d finding(s), %d medium\n",
		$findings->count, $findings->counts->{medium};

	for my $finding (@{ $findings->sorted }) {
		print "$finding->{severity}  $finding->{title}\n";
	}

Use the findings as a gate in a deployment script:

	my $serious = $findings->at_or_above('high');
	if(@{$serious}) {
		print STDERR scalar(@{$serious}), " serious finding(s); stopping\n";
		exit 1;
	}

=head1 DESCRIPTION

This module holds the results of a scan.  Each result is called a
I<finding>: one problem, on one host, with a severity, a title and advice
on how to fix it.

The collection does two jobs:

=over 4

=item * It removes duplicates.  Two findings are the same when they have
the same rule id, host, URL and C<key>.  The second one is ignored.

=item * It sorts.  The worst severity comes first.  Findings with the same
severity are sorted by host, then by title, then by URL.  The order is
always the same, so the reports from two runs can be compared line by line.

=back

Each finding is a hash reference.  It has every field named in
C<@App::WebPerimeterScan::Findings::FIELDS>, and every field is a string.
A field that does not apply is the empty string, never C<undef>, so code
that reads a finding never has to test for C<undef>.

The severities, from worst to least, are C<critical>, C<high>, C<medium>,
C<low> and C<info>.

=head1 SUBROUTINES/METHODS

=head2 new

Purpose: create an empty collection.

Args: none.

Returns: the new object.

Side Effects: none.

Usage: C<< my $findings = App::WebPerimeterScan::Findings->new; >>

=head3 EXAMPLE

	my $findings = App::WebPerimeterScan::Findings->new;
	print $findings->count, "\n";	# 0

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Findings' }

=head3 MESSAGES

	Message                          Meaning / resolution
	-------------------------------  -----------------------------------
	Unknown parameter 'X'            new() takes no arguments.

=cut

sub new
{
	my $class = shift;

	# No arguments are accepted; an unknown one croaks.
	validate_strict(schema => {}, input => get_params(undef, \@_) // {});

	return bless { items => [], seen => {} }, $class;
}

=head2 add

Purpose: record one finding with its text already rendered.

Args: named: C<id>, C<severity> (one of C<@SEVERITIES>), C<host>, C<url>,
C<key> (an extra de-duplication component, not stored), C<title>,
C<detail>, C<evidence>, C<fix>, C<reference>, C<file>, C<source>.  All are
optional strings.

Returns: 1 if the finding was recorded, 0 if it duplicated one already held.

Side Effects: appends to the collection.  An unknown severity is recorded as
C<info> with a warning, so a typo cannot silently hide a finding below the
C<--fail-on> threshold without anyone noticing.

Usage: C<< $findings->add(id => 'x', severity => 'low', title => 'X') >>

=head3 EXAMPLE

	my $added = $findings->add(
		id => 'trace-enabled', severity => 'medium',
		host => 'example.com', url => 'https://example.com/',
		title => 'HTTP TRACE is enabled',
	);
	# A second identical call returns 0

=head3 API SPECIFICATION

=head4 INPUT

	{
		id        => { type => 'string', optional => 1 },
		severity  => { type => 'string', optional => 1 },
		host      => { type => 'string', optional => 1 },
		url       => { type => 'string', optional => 1 },
		key       => { type => 'string', optional => 1 },
		title     => { type => 'string', optional => 1 },
		detail    => { type => 'string', optional => 1 },
		evidence  => { type => 'string', optional => 1 },
		fix       => { type => 'string', optional => 1 },
		reference => { type => 'string', optional => 1 },
		file      => { type => 'string', optional => 1 },
		source    => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

	Message                                    Meaning / resolution
	-----------------------------------------  -------------------------------
	Unknown severity 'S' for finding 'I';      The severity is not one of
	recorded as info (warning)                 critical/high/medium/low/info.
	Unknown parameter 'X' (fatal)              A misspelt argument name.

=head3 PSEUDOCODE

	validate the arguments
	default the id; warn and default an unknown severity to info
	build the de-duplication key from id, host, url and key
	return 0 if the key has been seen
	store every field, empty string where not given
	return 1

=cut

sub add
{
	my $self = shift;

	my $args = validate_strict(schema => \%ADD_SCHEMA, input => get_params(undef, \@_) // {});

	my $id = $args->{id} // $DEFAULT_ID;
	my $severity = $args->{severity} // $DEFAULT_SEVERITY;
	unless(exists $RANK{$severity}) {
		$self->_warn('findings.unknown_severity', { severity => $severity, id => $id });
		$severity = $DEFAULT_SEVERITY;
	}

	# The same id on the same host/url/key is one finding, however many
	# pages or probes produced it.
	my $dedupe = join $KEY_SEPARATOR, $id, map { $args->{$_} // '' } qw(host url key);
	return 0 if $self->{seen}{$dedupe}++;

	# Every field is present and a string, so the report formats never
	# have to test for undef.
	my %finding = map { $_ => $args->{$_} // '' } @FIELDS;
	@finding{qw(id severity)} = ($id, $severity);
	$finding{title} = $id unless length $finding{title};

	push @{ $self->{items} }, \%finding;

	return 1;
}

=head2 report

Purpose: record a finding whose text comes from the message catalogue, so a
rule only states its id, severity and the values that vary.

Args: C<$id> (the rule id), then named: C<severity>, C<host>, C<url>,
C<key>, C<reference>, C<vars> (hashref of placeholder values),
C<evidence> (raw evidence; overrides the C<.evidence> template),
C<message> (the catalogue base key, when it differs from C<$id> - for
example C<port-open> for C<port-open-3306>) and C<rule> (a hash reference
with default C<severity> and C<reference>, overridden by those arguments).

Returns: as C<add>.

Side Effects: as C<add>.  C<confess>es if the catalogue has no C<.title> or
C<.detail> for the rule.

Usage: C<< $findings->report('tls-expired', severity => 'high', host => $h, vars => { days => 3 }) >>

=head3 EXAMPLE

	$findings->report('port-open-3306',
		message  => 'port-open',
		severity => 'high',
		host     => 'db.example.com',
		vars     => { port => 3306, has_banner => 'no' },
	);

=head3 API SPECIFICATION

=head4 INPUT

	{
		id        => { type => 'string', min => 1, position => 0 },
		severity  => { type => 'string', optional => 1 },
		host      => { type => 'string', optional => 1 },
		url       => { type => 'string', optional => 1 },
		key       => { type => 'string', optional => 1 },
		reference => { type => 'string', optional => 1 },
		evidence  => { type => 'string', optional => 1 },
		message   => { type => 'string', optional => 1 },
		vars      => { type => 'hashref', optional => 1 },
		rule      => { type => 'hashref', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'integer', memberof => [ 0, 1 ] }

=head3 MESSAGES

	Message                              Meaning / resolution
	-----------------------------------  -----------------------------------
	No message is defined for "K"        The rule has no catalogue text; add
	(fatal, with stack trace)            K to App::WebPerimeterScan::Messages.

=cut

sub report
{
	my ($self, $id, @rest) = @_;

	my $args = validate_strict(
		schema => {
			severity  => { type => 'string', optional => 1 },
			host      => { type => 'string', optional => 1 },
			url       => { type => 'string', optional => 1 },
			key       => { type => 'string', optional => 1 },
			reference => { type => 'string', optional => 1 },
			evidence  => { type => 'string', optional => 1 },
			message   => { type => 'string', optional => 1 },
			vars      => { type => 'hashref', optional => 1 },
			rule      => { type => 'hashref', optional => 1 },
		},
		input => get_params(undef, \@rest) // {},
	);

	my $base = $args->{message} // $id;
	my $vars = $args->{vars} // {};

	# A rule table supplies the usual severity and reference; an explicit
	# argument wins, for rules whose severity depends on what was found.
	my $rule = $args->{rule} || {};
	$args->{$_} //= $rule->{$_} for qw(severity reference);

	# Evidence that was captured (a banner, a body excerpt) is data and is
	# passed raw; evidence that is a sentence comes from the catalogue.
	my $evidence = $args->{evidence} // $self->_optional_text("$base.evidence", $vars);

	return $self->add(
		(map { defined $args->{$_} ? ($_ => $args->{$_}) : () } qw(severity host url key reference)),
		id       => $id,
		title    => $self->i18n("$base.title", $vars),
		detail   => $self->i18n("$base.detail", $vars),
		fix      => $self->_optional_text("$base.fix", $vars),
		evidence => $evidence,
	);
}

=head2 annotate

Purpose: attach the file on disk or the line of source behind a finding,
once the scan is complete.

Args: C<$finding> (a hash reference from C<all> or C<sorted>), then named
C<file> and/or C<source> (strings).

Returns: C<$self>, for chaining.

Side Effects: changes the finding in place.  Only C<file> and C<source> can
be changed; the identifying fields are fixed once recorded.

Usage: C<< $findings->annotate($finding, file => '/srv/www/.env') >>

=head3 EXAMPLE

	for my $finding (@{ $findings->all }) {
		$findings->annotate($finding, source => 'lib/App.pm:42')
			if $finding->{url} =~ m{/api/};
	}

=head3 API SPECIFICATION

=head4 INPUT

	{
		finding => { type => 'hashref', position => 0 },
		file    => { type => 'string', optional => 1 },
		source  => { type => 'string', optional => 1 },
	}

=head4 OUTPUT

	{ type => 'object', isa => 'App::WebPerimeterScan::Findings' }

=head3 MESSAGES

	Message                                   Meaning / resolution
	----------------------------------------  -------------------------------
	annotate() was given a finding that this  Pass a finding obtained from this
	collection did not record (fatal)         object's all() or sorted().

=cut

sub annotate
{
	my ($self, $finding, @rest) = @_;

	my $args = validate_strict(
		schema => { map { $_ => { type => 'string', optional => 1 } } keys %ANNOTATABLE },
		input  => get_params(undef, \@rest) // {},
	);

	# Identity, not equality: a copy of a finding must not be annotated as
	# though it were the original.
	my $address = ref $finding eq 'HASH' ? refaddr($finding) : -1;
	$self->_throw('findings.foreign')
		unless grep { refaddr($_) == $address } @{ $self->{items} };

	$finding->{$_} = $args->{$_} for grep { defined $args->{$_} } keys %ANNOTATABLE;

	return $self;
}

=head2 all

Purpose: the findings in the order they were recorded.

Args: none.

Returns: an array reference (a new array; the findings inside are shared).

Side Effects: none.

Usage: C<< for my $f (@{ $findings->all }) { ... } >>

=head3 EXAMPLE

	my @hosts = map { $_->{host} } @{ $findings->all };

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref', element_type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub all
{
	my ($self) = @_;

	return [ @{ $self->{items} } ];
}

=head2 count

Purpose: the number of findings held.

Args: none.

Returns: a non-negative integer.

Side Effects: none.

Usage: C<< print $findings->count >>

=head3 EXAMPLE

	printf "%d finding(s)\n", $findings->count;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'integer', min => 0 }

=head3 MESSAGES

None.

=cut

sub count
{
	my ($self) = @_;

	return scalar @{ $self->{items} };
}

=head2 sorted

Purpose: the findings worst first, then by host, title and URL, so the
output of two runs can be diffed.

Args: none.

Returns: an array reference.

Side Effects: none.

Usage: C<< for my $f (@{ $findings->sorted }) { ... } >>

=head3 EXAMPLE

	my $worst = $findings->sorted->[0];
	print "Worst: $worst->{title}\n" if $worst;

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'arrayref', element_type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub sorted
{
	my ($self) = @_;

	return [ sort {
		$RANK{ $b->{severity} } <=> $RANK{ $a->{severity} }
			|| $a->{host} cmp $b->{host}
			|| $a->{title} cmp $b->{title}
			|| $a->{url} cmp $b->{url}
	} @{ $self->{items} } ];
}

=head2 counts

Purpose: how many findings there are at each severity.

Args: none.

Returns: a hash reference with every severity as a key, zero where none.

Side Effects: none.

Usage: C<< my $high = $findings->counts->{high}; >>

=head3 EXAMPLE

	my $counts = $findings->counts;
	print "$counts->{critical} critical\n";

=head3 API SPECIFICATION

=head4 INPUT

	{}

=head4 OUTPUT

	{ type => 'hashref' }	# keys: critical high medium low info

=head3 MESSAGES

None.

=cut

sub counts
{
	my ($self) = @_;

	my %counts = map { $_ => 0 } @SEVERITIES;
	$counts{ $_->{severity} }++ for @{ $self->{items} };

	return \%counts;
}

=head2 rank

Purpose: the numeric rank of a severity name, higher is worse.

Args: C<$severity> (string).  A function, not a method.

Returns: 5 for C<critical> down to 1 for C<info>; 0 for anything else.

Side Effects: none.

Usage: C<< App::WebPerimeterScan::Findings::rank('high') >>

=head3 EXAMPLE

	my @worst_first = sort {
		App::WebPerimeterScan::Findings::rank($b) <=> App::WebPerimeterScan::Findings::rank($a)
	} qw(low critical medium);

=head3 API SPECIFICATION

=head4 INPUT

	{ severity => { type => 'string', optional => 1, position => 0 } }

=head4 OUTPUT

	{ type => 'integer', min => 0, max => 5 }

=head3 MESSAGES

None.

=cut

sub rank
{
	my ($severity) = @_;

	return defined $severity ? ($RANK{$severity} // 0) : 0;
}

=head2 at_or_above

Purpose: the findings at or above a severity, which is what decides the exit
status of the command-line tool.

Args: C<$threshold>, a severity name.

Returns: an array reference; empty for an unknown threshold.

Side Effects: none.

Usage: C<< exit 1 if @{ $findings->at_or_above('high') }; >>

=head3 EXAMPLE

	my $failing = $findings->at_or_above('medium');
	printf "%d finding(s) at medium or worse\n", scalar @{$failing};

=head3 API SPECIFICATION

=head4 INPUT

	{ threshold => { type => 'string', position => 0 } }

=head4 OUTPUT

	{ type => 'arrayref', element_type => 'hashref' }

=head3 MESSAGES

None.

=cut

sub at_or_above
{
	my ($self, $threshold) = @_;

	# An unknown threshold matches nothing rather than everything.
	my $limit = rank($threshold);

	return $limit ? [ grep { $RANK{ $_->{severity} } >= $limit } @{ $self->{items} } ] : [];
}

# _optional_text
# Purpose:     render a catalogue key that a rule may leave out (.fix,
#              .evidence).
# Entry:       $key is a full key; $vars a hashref.
# Exit:        the rendered text, or '' when the key does not exist.
# Side effects: none.
sub _optional_text :Private
{
	my ($self, $key, $vars) = @_;

	return $self->has_message($key) ? $self->i18n($key, $vars) : '';
}

1;

__END__

=head1 COMMON PITFALLS

=over 4

=item * B<A misspelt threshold matches nothing.>  C<at_or_above('hihg')>
returns an empty list, with no warning, so a gate written as
C<exit 1 if @{ $findings-E<gt>at_or_above($level) }> would pass.  Check
the level first with C<rank($level)>, which returns 0 for an unknown
severity.  The F<webperimeter> command does this for C<--fail-on>.

=item * B<A misspelt severity becomes C<info>.>  C<add> and C<report>
record a finding with an unknown severity as C<info> and print a warning.
The finding is kept, but it is now below most C<--fail-on> levels.

=item * B<C<undef> is stored as the empty string.>  Passing
C<< host => undef >> is the same as not passing C<host>.  The only field
that is filled in for you is C<title>, which becomes the rule id when it
is empty.

=item * B<An C<undef> placeholder value is shown, not hidden.>  In
C<report>, C<< vars => { url => undef } >> leaves the text C<{url}> in the
message.  This is on purpose: a visible C<{url}> shows that a value was
missing.

=item * B<C<all> and C<sorted> return a new list, but the same findings.>
Adding to or removing from the returned array does not change the
collection.  Changing a field of a finding in that array I<does> change the
finding in the collection.  Use C<annotate> to change C<file> and
C<source>, and do not change other fields.

=item * B<The de-duplication key is exact.>  C<https://example.com/> and
C<https://example.com> are different URLs, so the same problem on both is
two findings.  The C<key> argument is part of the key but is not stored.

=back

=head1 ENCODING

This module does not decode or encode text.  It stores exactly the strings
it is given.

=over 4

=item * Any byte string is safe in any field, including UTF-8 text in any
language and emoji.  The scanner itself always passes byte strings: text
taken from a web page is the bytes the server sent.

=item * Perl character strings (text with characters above 255, for
example after C<decode('UTF-8', ...)>) are also stored correctly, but the
report functions in L<App::WebPerimeterScan::Report> then return a
character string.  Printing it to a handle with no C<:encoding> layer gives
a "Wide character" warning.  Either encode the text to UTF-8 bytes before
C<add>, or set C<binmode STDOUT, ':encoding(UTF-8)'> before printing.

=item * Do not mix the two kinds of string in one collection.  A report
that joins UTF-8 bytes with character strings encodes the bytes a second
time, and C<E<eacute>> is printed as C<E<Atilde>E<copy>>.

=item * Sorting compares strings with Perl's C<cmp>, which orders by
character number, not by the rules of any language.

=back

=head1 LIMITATIONS

=over 4

=item * Findings are plain hash references, so code holding one can change
any field, not only through C<annotate>.  Returning copies would stop that
but would also break C<annotate>, which needs the original; a finding class
with read-only accessors is the complete fix and is left for a later
release.

=item * De-duplication is exact: the same problem reported under two URLs is
two findings, which is deliberate for page-level rules and noisy for
host-level ones.  Rules that are about the host pass an empty C<url>.

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


=head2 new

	┌─ InitFindings ──────────────────────────────────────
	│ Findings'
	├─────────────────────────────────────────────────────
	│ items' = ⟨⟩ ∧ seen' = ∅
	└─────────────────────────────────────────────────────

=head2 add

	┌─ Add ───────────────────────────────────────────────
	│ ΔFindings
	│ id?, severity?, host?, url?, key? : STRING; result! : {0, 1}
	├─────────────────────────────────────────────────────
	│ k = (id?, host?, url?, key?)
	│ sev = if severity? ∈ SEVERITY then severity? else info
	│ k ∈ seen ⇒ items' = items ∧ seen' = seen ∧ result! = 0
	│ k ∉ seen ⇒ items' = items ⁀ ⟨finding(id?, sev, …)⟩
	│          ∧ seen' = seen ∪ {k} ∧ result! = 1
	└─────────────────────────────────────────────────────

=head2 report

	┌─ Report ────────────────────────────────────────────
	│ ΔFindings; ΞCatalogue
	│ id?, base? : KEY; vars? : NAME ⇸ VALUE
	├─────────────────────────────────────────────────────
	│ b = if base? defined then base? else id?
	│ b ⁀ ".title" ∈ dom catalogue ∧ b ⁀ ".detail" ∈ dom catalogue
	│ Add[title? := i18n(b ⁀ ".title", vars?),
	│     detail? := i18n(b ⁀ ".detail", vars?)]
	└─────────────────────────────────────────────────────

=head2 annotate

	┌─ Annotate ──────────────────────────────────────────
	│ ΔFindings; f? : FINDING; file?, source? : STRING
	├─────────────────────────────────────────────────────
	│ f? ∈ ran items
	│ items' = items ⊕ {f? ↦ f? ⊕ {file ↦ file?, source ↦ source?}}
	└─────────────────────────────────────────────────────

=head2 all

	┌─ All ───────────────────────────────────────────────
	│ ΞFindings; result! : seq FINDING
	├─────────────────────────────────────────────────────
	│ result! = items
	└─────────────────────────────────────────────────────

=head2 count

	┌─ Count ─────────────────────────────────────────────
	│ ΞFindings; result! : ℕ
	├─────────────────────────────────────────────────────
	│ result! = #items
	└─────────────────────────────────────────────────────

=head2 sorted

	┌─ Sorted ────────────────────────────────────────────
	│ ΞFindings; result! : seq FINDING
	├─────────────────────────────────────────────────────
	│ items bag_of result! ∧ #result! = #items
	│ ∀ i : 1 .. #result! − 1 • key(result! i) ≤ key(result! (i + 1))
	│ key(f) = (−rank(f.severity), f.host, f.title, f.url)
	└─────────────────────────────────────────────────────

=head2 counts

	┌─ Counts ────────────────────────────────────────────
	│ ΞFindings; result! : SEVERITY → ℕ
	├─────────────────────────────────────────────────────
	│ ∀ s : SEVERITY • result! s = #{ f : ran items | f.severity = s }
	└─────────────────────────────────────────────────────

=head2 rank

	┌─ Rank ──────────────────────────────────────────────
	│ severity? : STRING; result! : 0 .. 5
	├─────────────────────────────────────────────────────
	│ severity? ∈ dom RANK ⇒ result! = RANK(severity?)
	│ severity? ∉ dom RANK ⇒ result! = 0
	└─────────────────────────────────────────────────────

=head2 at_or_above

	┌─ AtOrAbove ─────────────────────────────────────────
	│ ΞFindings; threshold? : STRING; result! : seq FINDING
	├─────────────────────────────────────────────────────
	│ threshold? ∉ dom RANK ⇒ result! = ⟨⟩
	│ threshold? ∈ dom RANK ⇒
	│     result! = items ↾ { f | RANK(f.severity) ≥ RANK(threshold?) }
	└─────────────────────────────────────────────────────

=head1 STATE DIAGRAM

A collection has one piece of state: the list of findings it holds, and the
set of de-duplication keys it has seen.  It is either empty or it holds one
or more findings.  Nothing ever removes a finding.

	                     new()
	                       |
	                       v
	              +-----------------+
	              |      EMPTY      |   count = 0
	              +-----------------+
	                |      |      |
	                |      |      |  all, sorted, counts, count,
	                |      |      |  at_or_above, rank
	                |      |      +-----> (no change; empty results)
	                |      |
	                |      |  annotate(any finding)
	                |      +-----> croak: the finding is not in this
	                |              collection (no change)
	                |
	                |  add / report with a new key
	                |  -> finding appended; key remembered; returns 1
	                v
	              +-----------------+
	        +---->|     HOLDING     |   count = n, n >= 1
	        |     +-----------------+
	        |       |    |    |    |
	        |       |    |    |    +--- all, sorted, counts, count,
	        |       |    |    |         at_or_above, rank
	        |       |    |    |         -> (no change; new list returned)
	        |       |    |    |
	        |       |    |    +-------- annotate(a held finding)
	        |       |    |              -> file / source fields set;
	        |       |    |                 returns the collection
	        |       |    |
	        |       |    +------------- add / report with a key already seen
	        |       |                   -> (no change); returns 0
	        |       |
	        +-------+  add / report with a new key
	                   -> finding appended (count = n + 1); returns 1

	Unknown severity on add / report: a warning is printed and the
	finding is recorded as 'info'.  The state change is otherwise the
	same as for a new key.

=head1 AUTHOR

Nigel Horne, C<< <njh at nigelhorne.com> >>

=head1 LICENCE AND COPYRIGHT

Copyright 2026 Nigel Horne.

Usage is subject to the GPL2 licence terms.
If you use it,
please let me know.

=cut
