package Data::FormValidator::Constraints::Business::DK::CPR;

# $Id$

use strict;
use warnings;
use vars qw(@ISA $VERSION @EXPORT_OK);
use Business::DK::CPR qw(validate);
use Scalar::Util qw(blessed);
use Carp qw(croak);
use 5.008;    #5.8.0

use base 'Exporter';

@EXPORT_OK = qw(valid_cpr match_valid_cpr);

use constant VALID   => 1;
use constant INVALID => undef;

$VERSION = '0.13';

sub valid_cpr {
    return sub {
        my $dfv = shift;

        if ( !blessed $dfv || !$dfv->isa('Data::FormValidator::Results') ) {
            croak('Must be called using \'constraint_methods\'!');
        }

        my $cpr = $dfv->get_current_constraint_value;

        if ( ref $dfv ) {
            $dfv->name_this('valid_cpr');
        }

        if ( validate($cpr) ) {
            return VALID;
        }
        else {
            return INVALID;
        }
    };
}

sub match_valid_cpr {
    my $dfv = shift;

    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constraint'

    my $cpr = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    my ($untainted_cpr) = $cpr =~ m/\A(\d{10})\Z/msx;

    return $dfv->untainted_constraint_value($untainted_cpr);
}

1;

__END__

=pod

=head1 NAME

Data::FormValidator::Constraints::Business::DK::CPR - constraint for Danish CPR

=head1 VERSION

The documentation describes version 0.01 of Data::FormValidator::Constraints::Business::DK::CPR

=head1 SYNOPSIS

  use Data::FormValidator;
  use Data::FormValidator::Constraints::Business::DK::CPR qw(valid_cpr);

    my $dfv_profile = {
        required => [qw(cpr)],
        constraint_methods => {
            cpr => valid_cpr(),
        }
    };

    my $dfv_profile = {
        required => [qw(cpr)],
        constraint_methods => {
            cpr => valid_cpr(),
        },
        untaint_all_constraints => 1,
    };


=head1 DESCRIPTION

This module exposes a set of subroutines which are compatible with
L<Data::FormValidator>. The module implements contraints as specified in
L<Data::FormValidator::Constraints>.

=head1 SUBROUTINES AND METHODS

=head2 valid_cpr

Checks whether a CPR is valid (see: SYNOPSIS) and L<Business::DK::CPR>

=head2 match_valid_cpr

Untaints a given CPR (see: SYNOPSIS and BUGS AND LIMITATIONS)

=head1 EXPORTS

Data::FormValidator::Constraints::Business::DK::CPR exports on request:

=over

=item L</valid_dk_cpr>

=item L</match_valid_cpr>

=back

=head1 DIAGNOSTICS

=over

=item * Please refer to L<Data::FormValidator> for documentation on this

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module requires no special configuration or environment to run.

=head1 DEPENDENCIES

=over

=item * L<Data::FormValidator>

=item * L<Business::DK::CPR>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The tests seem to reflect that untainting takes place, but the L</match_valid_cpr> is not called at all, so
how this untaiting is expected integrated into L<Data::FormValidator> is still not settled (SEE: TODO)

=head1 TEST AND QUALITY

Coverage of the test suite is at 57.6%

=head1 TODO

=over

=item * Get the untaint functionality tested thoroughly, that would bring the coverage to 100%, the L</match_valid_cpr> does not seem to be run.

=item * Comply with Data::FormValidator, especially for untainting

=back

=head1 SEE ALSO

=over

=item * L<Data::FormValidator>

=item * L<Data::FormValidator::Constraints>

=item * L<Data::FormValidator::Result>

=item * L<Business::DK::CPR>

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-CPR

or by sending mail to

  bug-Business-DK-CPR@rt.cpan.org
  
=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-CPR and related is (C) by Jonas B. Nielsen, (jonasbn) 2006-2014

=head1 LICENSE

Business-DK-CPR and related is released under the artistic license

The distribution is licensed under the Artistic License, as specified
by the Artistic file in the standard perl distribution
(L<http://www.perl.com/language/misc/Artistic.html>).

=cut
