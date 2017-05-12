package Data::FormValidator::Constraints::Business::DK::FI;

use strict;
use warnings;
use vars qw(@ISA $VERSION @EXPORT_OK);
use Business::DK::FI qw(validateFI);
use Scalar::Util qw(blessed);
use Carp qw(croak);

use base 'Exporter';

@EXPORT_OK = qw(valid_fi match_valid_fi);

use constant VALID   => 1;
use constant INVALID => undef;

$VERSION = '0.09';

sub valid_fi {
    return sub {
        my $dfv = shift;

        if ( !blessed $dfv || !$dfv->isa('Data::FormValidator::Results') ) {
            croak('Must be called using \'constraint_methods\'!');
        }

        my $fi = $dfv->get_current_constraint_value;

        if ( ref $dfv ) {
            $dfv->name_this('valid_fi');
        }

        if ( validateFI($fi) ) {
            return VALID;
        }
        else {
            return INVALID;
        }
        }
}

sub match_valid_fi {
    my $dfv = shift;

    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constraint'

    my $fi = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    my ($untainted_fi) = $fi =~ m/\A(\d+)\Z/msx;

    return $dfv->untainted_constraint_value($untainted_fi);
}

1;

__END__

=pod

=head1 NAME

Data::FormValidator::Constraints::Business::DK::FI - constraint for Danish FI

=head1 VERSION

The documentation describes version 0.09 of Data::FormValidator::Constraints::Business::DK::FI

=head1 SYNOPSIS

  use Data::FormValidator;
  use Data::FormValidator::Constraints::Business::DK::FI qw(valid_fi);

    my $dfv_profile = {
        required => [qw(fi)],
        constraint_methods => {
            fi => valid_fi(),
        }
    };

    my $dfv_profile = {
        required => [qw(fi)],
        constraint_methods => {
            fi => valid_fi(),
        },
        untaint_all_constraints => 1,
    };


=head1 DESCRIPTION

This module exposes a set of subroutines which are compatible with
L<Data::FormValidator>. The module implements contraints as specified in
L<Data::FormValidator::Constraints>.

=head1 SUBROUTINES AND METHODS

=head2 valid_fi

Checks whether a FI number is valid (see: SYNOPSIS) and L<Business::DK::FI>.

=head2 match_valid_fi

Untaints a given FI number (see: SYNOPSIS and BUGS AND LIMITATIONS).

=head1 EXPORTS

Data::FormValidator::Constraints::Business::DK::FI exports on request:

=over

=item * L</valid_dk_fi>

=item * L</match_valid_fi>

=back

=head1 DIAGNOSTICS

=over

=item * Please refer to L<Data::FormValidator> for documentation

=back

=head1 CONFIGURATION AND ENVIRONMENT

This module requires no special configuration or environment to run.

It is intended to integrate with L<Data::FormValidator> profiles in general.

=head1 DEPENDENCIES

=over

=item * L<Data::FormValidator>

=item * L<Business::DK::FI>

=item * L<Scalar::Util>

=item * L<Carp>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The tests seem to reflect that untainting takes place, but the L</match_valid_fi> is not called at all, so how this untaiting is expected integrated into L<Data::FormValidator> is still not settled (SEE: L</TODO>).

=head1 TEST AND QUALITY

The module is generally well tested, apart for the I<untainting> facility implemented in: L</match_valid_fi>, please see L</BUGS AND LIMITATIONS> and L</TODO>.

=head2 TEST COVERAGE

    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    File                           stmt   bran   cond    sub    pod   time  total
    ---------------------------- ------ ------ ------ ------ ------ ------ ------
    blib/lib/Business/DK/FI.pm    100.0  100.0    n/a  100.0  100.0   35.1  100.0
    ...b/Class/Business/DK/FI.pm  100.0  100.0   66.7  100.0  100.0   64.9   98.4
    Total                         100.0  100.0   66.7  100.0  100.0  100.0   99.3
    ---------------------------- ------ ------ ------ ------ ------ ------ ------

=head1 QUALITY AND CODING STANDARD

This is a plugin for L<Data::FormValidator> it follows the de facto standard of
code layout and naming used in other L<Data::FormValidator> plugins and meets requirements defined by L<Data::FormValidator>.

The code passes L<Perl::Critic> tests at severity 1 (I<brutal>) with a set of policies disabled. please see F<t/perlcriticrc> and the list below:

=over

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma>

=item * L<Perl::Critic::Policy::Documentation::RequirePodLinksIncludeText>

=back

=head2 Perl::Critic Tests

Are enabled using the environment variable:

    TEST_CRITIC

Please see the documentation in: F<t/critic.t>.

=head2 POD Tests

Are enabled using the environment variable:

    TEST_POD

=head2 Author Tests

Are enabled using the environment variable:

    TEST_AUTHOR

=head1 BUG REPORTING

Please report issues via CPAN RT:

=over

=item * L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-FI>

=back

or by sending mail to

=over

=item * C<< <bug-Business-DK-FI@rt.cpan.org> >>

=back

=head1 TODO

=over

=item * Get the untaint functionality tested thoroughly, that would bring the coverage to 100%, the L</match_valid_fi> does not seem to be run. This patterns is however an issue for all of the logicLAB Business::DK::* distributions.

=item * Comply with Data::FormValidator, especially for untainting. This is an issue for all of the logicLAB Business::DK::* distributions.

=back

Please see the distribution F<TODO> file also and the distribution road map at:
    L<http://logiclab.jira.com/browse/BDKFI#selectedTab=com.atlassian.jira.plugin.system.project%3Aroadmap-panel>

=head1 SEE ALSO

=over

=item * L<Data::FormValidator>

=item * L<Data::FormValidator::Constraints>

=item * L<Data::FormValidator::Result>

=item * L<Business::DK::FI>

=item * L<Business::DK::CVR>

=item * L<Business::DK::CPR>

=item * L<Business::DK::PO>

=item * L<Business::DK::Postalcode>

=item * L<Business::DK::Phonenumber>

=back

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-FI and related is (C) by Jonas B. Nielsen, (jonasbn) 2009-2016

=head1 LICENSE

Business-DK-FI and related is released under the Artistic License 2.0

See the included license file for details

=cut
