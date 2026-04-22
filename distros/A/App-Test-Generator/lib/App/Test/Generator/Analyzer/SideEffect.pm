package App::Test::Generator::Analyzer::SideEffect;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Purity classification labels
# --------------------------------------------------
Readonly my $PURITY_PURE         => 'pure';
Readonly my $PURITY_SELF_MUTATING => 'self_mutating';
Readonly my $PURITY_IMPURE       => 'impure';

# --------------------------------------------------
# IO operation keywords — print/say/warn/open etc.
# NOTE: this list is not exhaustive; low-level sysread
# and syswrite are included but higher-level abstractions
# like Log::Any calls are not detected.
# --------------------------------------------------
Readonly my $IO_PATTERN =>
	qr/\b(?:print|say|printf|warn|open|close|syswrite|sysread|readline|read|write)\b/;

# --------------------------------------------------
# External execution patterns — system calls and
# backtick/qx operators
# --------------------------------------------------
Readonly my $EXEC_PATTERN =>
	qr/\b(?:system|exec)\b|qx\(|`/;

# --------------------------------------------------
# Global variable patterns — %ENV, %SIG, @ARGV and
# common Perl special variables.
# NOTE: does not detect all possible globals; mutation
# of $_, $/, $! etc. would require deeper analysis.
# --------------------------------------------------
Readonly my $GLOBAL_PATTERN =>
	qr/\$(?:GLOBAL|ENV|SIG|ARGV|_|\/|!|0)\b|%ENV\b|%SIG\b|@ARGV\b/;

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Analyses the source body of a method and produces a side effect report
describing whether the method mutates C<$self>, mutates global state,
performs IO, or calls external commands. Used by
L<App::Test::Generator> to classify methods by purity and guide test
generation strategy.

=head2 new

Construct a new SideEffect analyser.

    my $analyser = App::Test::Generator::Analyzer::SideEffect->new;

=head3 Arguments

None.

=head3 Returns

A blessed hashref.

=head3 API specification

=head4 input

    {}

=head4 output

    {
        type => OBJECT,
        isa  => 'App::Test::Generator::Analyzer::SideEffect',
    }

=cut

sub new { bless {}, shift }

=head2 analyze

Analyse the source body of a method and return a side effect report
hashref.

    my $analyser = App::Test::Generator::Analyzer::SideEffect->new;
    my $report   = $analyser->analyze($method);

    if ($report->{purity_level} eq 'pure') {
        print "Method is side-effect free\n";
    }

=head3 Arguments

=over 4

=item * C<$method>

A hashref with a C<body> key containing the raw source text of the
method to analyse.

=back

=head3 Returns

A hashref with the following keys:

=over 4

=item * C<mutates_self> — 1 if the method assigns to C<$self-E<gt>{field}>.

=item * C<mutates_globals> — 1 if the method modifies global variables.

=item * C<performs_io> — 1 if the method performs IO operations.

=item * C<calls_external> — 1 if the method calls external commands.

=item * C<mutation_fields> — arrayref of C<$self> field names assigned
to (deduplicated).

=item * C<purity_level> — one of C<pure>, C<self_mutating>, or
C<impure>.

=back

=head3 Notes

Detection is based on regex pattern matching against the raw source
text and will not catch dynamically constructed calls or aliased
operations. The global variable pattern covers common Perl specials
but is not exhaustive.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Analyzer::SideEffect' },
        method => { type => HASHREF },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            mutates_self    => { type => SCALAR },
            mutates_globals => { type => SCALAR },
            performs_io     => { type => SCALAR },
            calls_external  => { type => SCALAR },
            mutation_fields => { type => ARRAYREF },
            purity_level    => { type => SCALAR },
        },
    }

=cut

sub analyze {
	my ($self, $method) = @_;

	# Method argument is a raw hashref from SchemaExtractor
	my $body = $method->{body} // '';

	my %result = (
		mutates_self    => 0,
		mutates_globals => 0,
		performs_io     => 0,
		calls_external  => 0,
		mutation_fields => [],
	);

	# --------------------------------------------------
	# Detect assignment to $self->{field} — any such
	# assignment means the method mutates its own state
	# --------------------------------------------------
	my %seen_fields;
	while($body =~ /\$self->\{(\w+)\}\s*=/g) {
		$result{mutates_self} = 1;

		# Deduplicate field names in case the same field
		# is assigned more than once in the method body
		push @{ $result{mutation_fields} }, $1
			unless $seen_fields{$1}++;
	}

	# --------------------------------------------------
	# Detect mutation of global variables — %ENV, %SIG,
	# @ARGV and common Perl special variables.
	# NOTE: does not catch all possible globals.
	# --------------------------------------------------
	if($body =~ $GLOBAL_PATTERN) {
		$result{mutates_globals} = 1;
	}

	# --------------------------------------------------
	# Detect IO operations — print, say, warn, open etc.
	# Higher-level logging abstractions are not detected.
	# --------------------------------------------------
	if($body =~ $IO_PATTERN) {
		$result{performs_io} = 1;
	}

	# --------------------------------------------------
	# Detect external command execution via system(),
	# exec(), qx() or backtick operators
	# --------------------------------------------------
	if($body =~ $EXEC_PATTERN) {
		$result{calls_external} = 1;
	}

	# --------------------------------------------------
	# Classify purity level based on detected side effects.
	# pure         — no side effects of any kind
	# self_mutating — only mutates own state, no external effects
	# impure       — any external side effect present
	# --------------------------------------------------
	my $has_external = $result{mutates_globals}
		|| $result{performs_io}
		|| $result{calls_external};

	$result{purity_level} =
		!$result{mutates_self} && !$has_external ? $PURITY_PURE         :
		$result{mutates_self}  && !$has_external ? $PURITY_SELF_MUTATING :
		                                           $PURITY_IMPURE;

	return \%result;
}

1;
