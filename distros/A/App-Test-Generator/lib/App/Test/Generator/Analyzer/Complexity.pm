package App::Test::Generator::Analyzer::Complexity;

use strict;
use warnings;
use Carp    qw(croak);
use Readonly;

# --------------------------------------------------
# Base cyclomatic complexity score before any analysis
# --------------------------------------------------
Readonly my $CYCLOMATIC_BASE => 1;

# --------------------------------------------------
# Complexity level thresholds — scores at or below
# LOW_THRESHOLD are low, at or below HIGH_THRESHOLD
# are moderate, above HIGH_THRESHOLD are high
# --------------------------------------------------
Readonly my $LOW_THRESHOLD  => 3;
Readonly my $HIGH_THRESHOLD => 7;

# --------------------------------------------------
# Complexity level labels
# --------------------------------------------------
Readonly my $LEVEL_LOW      => 'low';
Readonly my $LEVEL_MODERATE => 'moderate';
Readonly my $LEVEL_HIGH     => 'high';

# --------------------------------------------------
# Keywords that introduce branching decision points
# --------------------------------------------------
Readonly my @BRANCH_TOKENS => qw(
	if elsif unless for foreach while until given when
);

# --------------------------------------------------
# Keywords that introduce exception or error paths
# --------------------------------------------------
Readonly my @EXCEPTION_TOKENS => qw(
	die croak confess try catch eval
);

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Analyses the source body of a method and produces a complexity report
including cyclomatic score, branching points, early returns, exception
paths, and nesting depth. Used by L<App::Test::Generator> to guide test
planning — higher complexity methods are prioritised for more thorough
test generation.

=head2 new

Construct a new Complexity analyser.

    my $analyser = App::Test::Generator::Analyzer::Complexity->new;

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
        isa  => 'App::Test::Generator::Analyzer::Complexity',
    }

=cut

sub new { bless {}, shift }

=head2 analyze

Analyse the source of a method and return a complexity report hashref.

    my $analyser = App::Test::Generator::Analyzer::Complexity->new;
    my $report   = $analyser->analyze($method);

    printf "Cyclomatic score: %d\n", $report->{cyclomatic_score};
    printf "Complexity level: %s\n", $report->{complexity_level};

=head3 Arguments

=over 4

=item * C<$method>

An L<App::Test::Generator::Model::Method> object. The method source is
read via C<source()>.

=back

=head3 Returns

A hashref with the following keys:

=over 4

=item * C<cyclomatic_score> — integer starting at 1, incremented for
each branching point, logical operator, early return, and exception path.

=item * C<branching_points> — count of branching keywords found.

=item * C<early_returns> — number of C<return> statements beyond the
first (each additional return adds a path).

=item * C<exception_paths> — count of exception-related keywords found.

=item * C<nesting_depth> — maximum brace nesting depth observed.

=item * C<complexity_level> — one of C<low>, C<moderate>, or C<high>
based on the cyclomatic score.

=back

=head3 Notes

Nesting depth is computed by naive brace counting and will be
inaccurate if the source contains braces inside strings or regexes.
This is a known limitation and is acceptable for dashboard display
purposes.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Analyzer::Complexity' },
        method => { type => OBJECT, isa => 'App::Test::Generator::Model::Method' },
    }

=head4 output

    {
        type => HASHREF,
        keys => {
            cyclomatic_score  => { type => SCALAR },
            branching_points  => { type => SCALAR },
            early_returns     => { type => SCALAR },
            exception_paths   => { type => SCALAR },
            nesting_depth     => { type => SCALAR },
            complexity_level  => { type => SCALAR },
        },
    }

=cut

sub analyze {
	my ($self, $method) = @_;

	# The method argument is a raw hashref from SchemaExtractor,
	# not a Model::Method object — access the body key directly
	my $body = $method->{body} // '';

	my %result = (
		cyclomatic_score => $CYCLOMATIC_BASE,
		branching_points => 0,
		early_returns    => 0,
		exception_paths  => 0,
		nesting_depth    => 0,
	);

	# --------------------------------------------------
	# Count branching keywords — each one introduces a
	# new decision point that increases cyclomatic complexity
	# --------------------------------------------------
	for my $token (@BRANCH_TOKENS) {
		my $count = () = $body =~ /\b$token\b/g;
		$result{branching_points} += $count;
		$result{cyclomatic_score} += $count;
	}

	# Logical operators also introduce implicit branches
	my $logic_count = () = $body =~ /&&|\|\||\?/g;
	$result{cyclomatic_score} += $logic_count;

	# --------------------------------------------------
	# Early returns — each return beyond the first adds
	# an additional exit path through the method
	# --------------------------------------------------
	my $return_count = () = $body =~ /\breturn\b/g;
	$result{early_returns}    = $return_count > 1 ? $return_count - 1 : 0;
	$result{cyclomatic_score} += $result{early_returns};

	# --------------------------------------------------
	# Exception paths — die/croak/eval etc. each introduce
	# a path that must be tested separately
	# --------------------------------------------------
	for my $token (@EXCEPTION_TOKENS) {
		my $count = () = $body =~ /\b$token\b/g;
		$result{exception_paths} += $count;
		$result{cyclomatic_score} += $count;
	}

	# --------------------------------------------------
	# Nesting depth — count brace depth by scanning chars.
	# NOTE: this is naive and will overcount if braces
	# appear inside strings or regexes. Acceptable for
	# dashboard display purposes.
	# --------------------------------------------------
	my $depth     = 0;
	my $max_depth = 0;
	for my $char (split //, $body) {
		if($char eq '{') {
			$depth++;
			$max_depth = $depth if $depth > $max_depth;
		} elsif($char eq '}') {
			$depth-- if $depth > 0;
		}
	}
	$result{nesting_depth} = $max_depth;

	# --------------------------------------------------
	# Classify complexity level based on cyclomatic score
	# --------------------------------------------------
	my $score = $result{cyclomatic_score};
	$result{complexity_level} =
		$score <= $LOW_THRESHOLD  ? $LEVEL_LOW      :
		$score <= $HIGH_THRESHOLD ? $LEVEL_MODERATE :
		                            $LEVEL_HIGH;

	return \%result;
}

1;
