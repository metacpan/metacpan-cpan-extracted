package Data::FormValidator::Constraints::Business::DK::CVR;

use strict;
use warnings;
use vars qw(@ISA $VERSION @EXPORT_OK);
use Business::DK::CVR qw(validate);
use Scalar::Util qw(blessed);
use Carp qw(croak);

use base 'Exporter';

@EXPORT_OK = qw(valid_cvr match_valid_cvr);

use constant VALID   => 1;
use constant INVALID => undef;

$VERSION = '0.09';

sub valid_cvr {
    return sub {
        my $dfv = shift;

        if ( !blessed $dfv || !$dfv->isa('Data::FormValidator::Results') ) {
            croak('Must be called using \'constraint_methods\'!');
        }

        my $cvr = $dfv->get_current_constraint_value;

        if ( ref $dfv ) {
            $dfv->name_this('valid_cvr');
        }

        if ( validate($cvr) ) {
            return VALID;
        } else {
            return INVALID;
        }
        }
}

sub match_valid_cvr {
    my $dfv = shift;

    # if $dfv is a ref then we are called as 'constraint_method'
    # else as 'constraint'

    my $cvr = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    #my $cvr = $dfv->get_current_constraint_value;

    my ($untainted_cvr) = $cvr =~ m/\b(\d{8})\b/smx;

    return $dfv->untainted_constraint_value($untainted_cvr);
}

1;

__END__

=pod

=head1 NAME

Data::FormValidator::Constraints::Business::DK::CVR - constraint for Danish CVR

=head1 VERSION

The documentation describes version 0.09 of Data::FormValidator::Constraints::Business::DK::CVR

=head1 SYNOPSIS

  use Data::FormValidator;
  use Data::FormValidator::Constraints::Business::DK::CVR qw(valid_cvr);

    my $dfv_profile = {
        required => [qw(cvr)],
        constraint_methods => {
            cvr => valid_cvr(),
        }
    };

    my $dfv_profile = {
        required => [qw(cvr)],
        constraint_methods => {
            cvr => valid_cvr(),
        },
        untaint_all_constraints => 1,
    };


=head1 DESCRIPTION

This module exposes a set of subroutines which are compatible with
L<Data::FormValidator>. The module implements contraints as specified in
L<Data::FormValidator::Constraints>.

=head1 SUBROUTINES AND METHODS

=head2 valid_cvr

Checks whether a CVR is valid (see: SYNOPSIS) and L<Business::DK::CVR>

=head2 match_valid_cvr

Untaints a given CVR (see: SYNOPSIS and BUGS AND LIMITATIONS)

=head1 EXPORTS

Data::FormValidator::Constraints::Business::DK::CVR exports on request:

=over

=item L</valid_dk_cvr>

=item L</match_valid_cvr>

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

=item * L<Business::DK::CVR>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The tests seem to reflect that untainting takes place, but the L</match_valid_cvr> is not called at all, so
how this untaiting is expected integrated into L<Data::FormValidator> is still not settled (SEE: TODO)

=head1 TEST AND QUALITY

Coverage of the test suite is at 81.8%

=head1 TODO

=over

=item * Get the untaint functionality tested thoroughly, that would bring the coverage to 100%, the L</match_valid_cvr> does not seem to be run.

=item * Comply with Data::FormValidator, especially for
untainting

=back

=head1 SEE ALSO

=over

=item * L<Data::FormValidator>

=item * L<Data::FormValidator::Constraints>

=item * L<Data::FormValidator::Result>

=item * L<Business::DK::CVR>

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-CVR

or by sending mail to

  bug-Business-DK-CVR@rt.cpan.org
  
=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-CVR and related is (C) by Jonas B. Nielsen, (jonasbn) 2006-2014

=head1 LICENSE

Business-DK-CVR and related is released under the artistic license

The distribution is licensed under the Artistic License, as specified
by the Artistic file in the standard perl distribution
(http://www.perl.com/language/misc/Artistic.html).

=cut
