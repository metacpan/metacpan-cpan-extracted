package Data::FormValidator::Constraints::Business::DK::Postalcode;

use strict;
use warnings;
use vars qw(@ISA $VERSION @EXPORT_OK);
use Business::DK::Postalcode qw(validate);
use Scalar::Util qw(blessed);
use Carp qw(croak);

use base 'Exporter';

@EXPORT_OK
    = qw(valid_postalcode match_postalcode postalcode danish_postalcode postalcode_denmark);

use constant INVALID => undef;

our $VERSION = '0.10';

sub postalcode {
    return sub {
        return match_postalcode(@_);
        }
}

sub valid_postalcode {
    return sub {
        return match_postalcode(@_);
        }
}

sub match_postalcode {
    my $dfv = shift;

    my $postalcode = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    if ( ref $dfv ) {
        $dfv->name_this('match_postalcode');
    }

    if ( my $untainted_postalcode = validate($postalcode) ) {
        if ( ref $dfv ) {
            $dfv->untainted_constraint_value($untainted_postalcode);
        }

        return $untainted_postalcode;
    } else {
        return INVALID;
    }
}

1;

__END__

=pod

=head1 NAME

Data::FormValidator::Constraints::Business::DK::Postalcode - constraint for Danish Postal codes

=head1 VERSION

The documentation describes version 0.10 of Data::FormValidator::Constraints::Business::DK::Postalcode

=head1 SYNOPSIS

  use Data::FormValidator;
  use Data::FormValidator::Constraints::Business::DK::Postalcode qw(valid_postalcode);

    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => valid_postalcode(),
        }
    };

    my $dfv_profile = {
        required => [qw(postalcode)],
        constraint_methods => {
            postalcode => valid_postalcode(),
        },
        untaint_all_constraints => 1,
    };


=head1 DESCRIPTION

This module exposes a set of subroutines which are compatible with
L<https://metacpan.org/pod/Data::FormValidator>. The module implements contraints as specified in
L<https://metacpan.org/pod/Data::FormValidator::Constraints>.

For a more through description of Danish postal codes please see: L<https://metacpan.org/pod/Business::DK::Postalcode>.

=head1 SUBROUTINES AND METHODS

=head2 valid_postalcode

Checks whether a Postalcode is valid (see: SYNOPSIS) and L<https://metacpan.org/pod/Business::DK::Postalcode>

=head2 match_postalcode

Untaints a given Postalcode (see: SYNOPSIS and BUGS AND LIMITATIONS)

=head2 postalcode

A simple wrapper for L</match_postalcode>

=head1 EXPORTS

Data::FormValidator::Constraints::Business::DK::Postalcode exports on request:

=over

=item * L</valid_postalcode>

=item * L</match_postalcode>

=back

=head1 DIAGNOSTICS

=over

=item * Please refer to L<https://metacpan.org/pod/Data::FormValidator> for documentation on this

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module requires no special configuration or environment to run.

=head1 DEPENDENCIES

=over

=item * L<https://metacpan.org/pod/Data::FormValidator>

=item * L<https://metacpan.org/pod/Business::DK::Postalcode>

=back

=head1 INCOMPATIBILITIES

The module has no known incompatibilities.

=head1 BUGS AND LIMITATIONS

The tests seem to reflect that untainting is taking place, but the L</match_postalcode>
is not called at all, so how this untaiting is expected to be integrated into L<https://metacpan.org/pod/Data::FormValidator>
is still not clear to ne (SEE: TODO)

=head1 TEST AND QUALITY

Coverage of the test suite is at 57.6%

=head1 TODO

=over

=item * Get the untaint functionality tested thoroughly, that would bring the coverage to 100%, the L</match_valid_postalcode> does not seem to be run.

=item * Comply with Data::FormValidator, especially for untainting

=back

=head1 SEE ALSO

=over

=item * L<https://metacpan.org/pod/Data::FormValidator>

=item * L<https://metacpan.org/pod/Data::FormValidator::Constraints>

=item * L<https://metacpan.org/pod/Data::FormValidator::Result>

=item * L<https://metacpan.org/pod/Business::DK::Postalcode>

=item * L<https://metacpan.org/pod/Data::FormValidator::Constraints::Business::DK::CVR>

=item * L<https://metacpan.org/pod/Data::FormValidator::Constraints::Business::DK::CPR>

=item * L<https://metacpan.org/pod/Data::FormValidator::Constraints::Business::DK::FI>

=item * L<https://metacpan.org/pod/Data::FormValidator::Constraints::Business::DK::PO>

=item * L<https://metacpan.org/pod/Data::FormValidator::Constraints::Business::DK::Phonenumber>

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

  http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-Postalcode

or by sending mail to

  bug-Business-DK-Postalcode@rt.cpan.org

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Data::FormValidator::Constraints::Business::DK::Postalcode is (C) by
Jonas B. Nielsen, (jonasbn) 2006-2015

=head1 LICENSE

Business-DK-Postalcode and related is released under the Artistic License 2.0

=over

=item * http://www.opensource.org/licenses/Artistic-2.0

=back

=cut
