package App::Test::Generator::Analyzer::ReturnMeta;

use strict;
use warnings;
use Carp qw(croak);
use Readonly;

# --------------------------------------------------
# Scoring penalties and bonuses applied to stability
# and consistency based on detected return patterns.
# Scores are clamped to [0, 100] after all adjustments.
# --------------------------------------------------
Readonly my $PENALTY_CONTEXT_SENSITIVE_STABILITY   => 25;
Readonly my $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY => 15;
Readonly my $PENALTY_MIXED_RETURN_CONSISTENCY      => 30;
Readonly my $PENALTY_IMPLICIT_UNDEF_STABILITY      => 20;
Readonly my $PENALTY_EXPLICIT_UNDEF_STABILITY      => 10;
Readonly my $PENALTY_EMPTY_LIST_CONSISTENCY        => 15;
Readonly my $PENALTY_EXCEPTION_SWALLOW_STABILITY   => 20;
Readonly my $BONUS_BOOLEAN_STABILITY               => 5;

our $VERSION = '0.33';

=head1 VERSION

Version 0.33

=head1 DESCRIPTION

Analyses the return metadata of a schema's output section and produces
stability and consistency scores along with a list of risk flags. This
is used by L<App::Test::Generator> to assess how reliably a function's
return value can be tested.

=head2 new

Construct a new ReturnMeta analyser.

    my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new;

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
        isa  => 'App::Test::Generator::Analyzer::ReturnMeta',
    }

=cut

sub new { bless {}, shift }

=head2 analyze

Analyse the C<output> section of a schema hashref and return a scoring
report covering stability, consistency, and risk flags.

    my $analyser = App::Test::Generator::Analyzer::ReturnMeta->new;
    my $report   = $analyser->analyze($schema);

    printf "Stability:   %d\n", $report->{stability_score};
    printf "Consistency: %d\n", $report->{consistency_score};
    printf "Risks:       %s\n", join(', ', @{ $report->{risk_flags} });

=head3 Arguments

=over 4

=item * C<$schema>

A hashref with an optional C<output> key containing return metadata.
The C<output> hashref may include any of the following keys:

=over 4

=item C<_context_aware> — true if the function returns differently in
list vs scalar context.

=item C<_returns_self> — true if the function returns C<$self>.

=item C<type> — the declared return type string e.g. C<object>,
C<boolean>, C<string>.

=item C<_error_handling> — a hashref with boolean keys C<implicit_undef>,
C<empty_list>, and C<exception_handling>.

=item C<_error_return> — the value returned on error e.g. C<undef>.

=back

=back

=head3 Returns

A hashref with three keys:

=over 4

=item * C<stability_score> — integer in [0, 100]. Higher is more stable.

=item * C<consistency_score> — integer in [0, 100]. Higher is more
consistent.

=item * C<risk_flags> — arrayref of string risk identifiers detected
during analysis.

=back

=head3 Notes

Both scores start at 100 and are reduced by penalties for each detected
risk pattern. A small bonus is applied to stability for boolean return
types. All scores are clamped to [0, 100] after adjustments.

=head3 API specification

=head4 input

    {
        self   => { type => OBJECT, isa => 'App::Test::Generator::Analyzer::ReturnMeta' },
        schema => { type => HASHREF },
    }

=head4 output

    {
        type    => HASHREF,
        keys    => {
            stability_score   => { type => SCALAR },
            consistency_score => { type => SCALAR },
            risk_flags        => { type => ARRAYREF },
        },
    }

=cut

sub analyze {
	my ($self, $schema) = @_;

	my $output      = $schema->{output} || {};
	my @risk;
	my $stability   = 100;
	my $consistency = 100;

	# --------------------------------------------------
	# Context sensitivity — function returns differently
	# in list vs scalar context, making it harder to test
	# predictably
	# --------------------------------------------------
	if($output->{_context_aware}) {
		push @risk, 'context_sensitive';
		$stability   -= $PENALTY_CONTEXT_SENSITIVE_STABILITY;
		$consistency -= $PENALTY_CONTEXT_SENSITIVE_CONSISTENCY;
	}

	# --------------------------------------------------
	# Mixed return types — function claims to return self
	# but is not typed as object, suggesting inconsistent
	# return paths
	# --------------------------------------------------
	if($output->{_returns_self} && ($output->{type} // '') ne 'object') {
		push @risk, 'mixed_return_types';
		$consistency -= $PENALTY_MIXED_RETURN_CONSISTENCY;
	}

	# --------------------------------------------------
	# Implicit undef returns — function falls off the end
	# without an explicit return, making error paths hard
	# to distinguish from successful empty returns
	# --------------------------------------------------
	if($output->{_error_handling}{implicit_undef}) {
		push @risk, 'implicit_error_return';
		$stability -= $PENALTY_IMPLICIT_UNDEF_STABILITY;
	}

	# --------------------------------------------------
	# Explicit undef on error — function explicitly returns
	# undef on failure; lower penalty than implicit since
	# the intent is at least documented in the code
	# --------------------------------------------------
	if($output->{_error_return} && $output->{_error_return} eq 'undef') {
		push @risk, 'undef_on_error';
		$stability -= $PENALTY_EXPLICIT_UNDEF_STABILITY;
	}

	# --------------------------------------------------
	# Empty list error pattern — function returns () on
	# error, which is indistinguishable from a successful
	# call that found no results
	# --------------------------------------------------
	if($output->{_error_handling}{empty_list}) {
		push @risk, 'empty_list_error';
		$consistency -= $PENALTY_EMPTY_LIST_CONSISTENCY;
	}

	# --------------------------------------------------
	# Exception swallowing — function catches exceptions
	# without rethrowing, hiding failures from the caller
	# --------------------------------------------------
	if($output->{_error_handling}{exception_handling}) {
		push @risk, 'exception_swallowing';
		$stability -= $PENALTY_EXCEPTION_SWALLOW_STABILITY;
	}

	# --------------------------------------------------
	# Boolean return bonus — boolean returns are the most
	# predictable and easiest to assert, so a small boost
	# is applied. Only has effect if stability was already
	# reduced below 95 by earlier penalties.
	# --------------------------------------------------
	if($output->{type} && $output->{type} eq 'boolean') {
		$stability += $BONUS_BOOLEAN_STABILITY;
	}

	# Clamp both scores to the valid [0, 100] range
	$stability   = 0   if $stability   < 0;
	$stability   = 100 if $stability   > 100;
	$consistency = 0   if $consistency < 0;
	$consistency = 100 if $consistency > 100;

	return {
		stability_score   => $stability,
		consistency_score => $consistency,
		risk_flags        => \@risk,
	};
}

1;
