package Data::FormValidator::Constraints::Business::DK::Phonenumber;

use strict;
use warnings;
use vars qw($VERSION @EXPORT_OK);
use Business::DK::Phonenumber qw(validate render);
use base qw(Exporter);

$VERSION   = '0.10';
@EXPORT_OK = qw(valid_dk_phonenumber match_dk_phonenumber);

use constant VALID   => 1;
use constant INVALID => undef;

sub valid_dk_phonenumber {
    return sub {
        my $dfv = shift;

        $dfv->name_this('valid_dk_phonenumber');

        my $phonenumber = $dfv->get_current_constraint_value();

        if ( validate($phonenumber) ) {
            return VALID;
        } else {
            return INVALID;
        }
        }
}

sub match_dk_phonenumber {
    my ( $dfv, $format ) = @_;

    my $phonenumber = ref $dfv ? $dfv->get_current_constraint_value : $dfv;

    my ($untainted_phonenumber) = render($phonenumber);

    return $untainted_phonenumber;
}

1;

__END__

=pod

=head1 NAME

Data::FormValidator::Constraints::Business::DK::Phonenumber - a DFV constraints wrapper

=head1 VERSION

This documentation describes version 0.10

=head1 SYNOPSIS

    use Data::FormValidator::Business::DK::Phonenumber qw(valid_dk_phonenumber);

    my $dfv_profile = {
        required => [qw(phonenumber)],
        constraint_methods => {
            phonenumber => valid_dk_phonenumber(),
        }
    };

    my $input_hash;
    my $result;

    $input_hash = {
        phonenumber  => 1234567,
    };

    $result = Data::FormValidator->check($input_hash, $dfv_profile);

=head1 DESCRIPTION

This module implements experimental L<Data::FormValidator> constraints.

=head1 SUBROUTINES AND METHODS

=head2 valid_dk_phonenumber

This method validates a string for resemblance to a valid Danish telephone number.

=head2 match_dk_phonenumber

This subroutine can be used for untainting a parameter.

=head1 DIAGNOSTICS

=over

=item * Please refer to L<Data::FormValidator>

=back

=head1 CONFIGURATION AND ENVIRONMENT

The module is intended for use with L<Data::FormValidator>.

=head1 DEPENDENCIES

=over

=item * L<Business::DK::Phonenumber>

=item * L<Data::FormValidator>

=back

=head1 INCOMPATIBILITIES

No known incompatibilities at this time.

=head1 BUGS AND LIMITATIONS

No known bugs or limitations at this time.

=head1 TEST AND QUALITY

=over

=item * The L<Perl::Critic::Policy::ValuesAndExpressions::RequireNumberSeparators>
policy has been disabled. We are working with phonenumbers, strings consisting primarily of number, so not special interpretation or calculative behaviour is needed.

=item * L<Perl::Critic::Policy::ValuesAndExpressions::ProhibitConstantPragma> policy has been disabled. I like constants.

=item * L<Perl::Critic::Policy::InputOutput::RequireBracedFileHandleWithPrint> policy has been disabled for now should be revisited at some point.

=back

=head1 TODO

=over

=item * Please refer to the distribution TODO file

=back

=head1 SEE ALSO

=over

=item * L<Data::FormValidator>

=item * L<Data::FormValidator::Constraints>

=item * L<Business::DK::Phonenumber>

=item * L<Class::Business::DK::Phonenumber>

=back

=head1 BUG REPORTING

Please report issues via CPAN RT:

http://rt.cpan.org/NoAuth/Bugs.html?Dist=Business-DK-Phonenumber

or by sending mail to

bug-Business-DK-Phonenumber@rt.cpan.org

=head1 MOTIVATION

I have been working in Telco for a long time. So validation and formatting of
telephone numbers is something I have seen at lot of. This module is an attempt
to sort of consolidate the numerous different regular expression solutions
I have seen scathered over large code bases.

=head1 AUTHOR

Jonas B. Nielsen, (jonasbn) - C<< <jonasbn@cpan.org> >>

=head1 COPYRIGHT

Business-DK-Phonenumber and related is (C) by Jonas B. Nielsen, (jonasbn) 2008-2014

=head1 LICENSE

Business-DK-Phonenumber and related is released under the Artistic License 2.0

=cut
