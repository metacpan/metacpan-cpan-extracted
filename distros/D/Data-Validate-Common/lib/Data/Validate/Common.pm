package Data::Validate::Common;

use 5.8.0;
use Any::Moose;
use Data::Validate::Domain qw//;

=head1 NAME

Data::Validate::Common - Some common validator methods

=head1 VERSION

Version 0.3.3.3.3.2.1.1.1.1.1

=cut

our $VERSION = '0.3';

=head1 SYNOPSIS

Adding one more validator to the vast list of existing ones. I could
have named it Validator::DWIW but went with the Common module as it
should be pretty standard stuff and is normally just one/two regex
changes to the existing ones that mekt it a bit more "real life".


=head1 SUBROUTINES/METHODS

=head2 is_email

Validates a email address (in a sloppy way, but accepts gmail '+' style
addresses). Does not do any validation of the existence.

=cut

sub is_email {
    my ($self, $value) = @_;

    return unless defined $value;

    my @parts = split( /\@/, $value );
    return unless scalar(@parts) == 2;

    my ($user) = $self->is_username( $parts[0] );
    return unless defined $user;
    return unless $user eq $parts[0];

    my $domain = $self->is_domain( $parts[1] );
    return unless defined $domain;
    return unless $domain eq $parts[1];

    return $user . '@' . $domain;
}

=head2 is_valid_email

Calls `is_email` and returns true or false and not the string itself.

=cut

sub is_valid_email {
    my ($self, $email) = @_;
    return ($self->is_email($email) ? 1 : 0);
}

=head2 is_domain

Just calles L<Data::Validate::Domain> for the moment but leaves room for
further modifiers (maybe via a plugin).

=cut

sub is_domain {
    my ($self, $value) = @_;

    return unless defined $value;
    return Data::Validate::Domain::is_domain($value);
}

=head2 is_valid_domain

Calls `is_domain` and returns true or false and not the string itself.

=cut

sub is_valid_domain {
    my ($self, $domain) = @_;
    return ($self->is_domain($domain) ? 1 : 0);
}

=head2 is_hostname

Just calles L<Data::Validate::Domain> for the moment but leaves room for
further modifiers (maybe via a plugin).

=cut

sub is_hostname {
    my ($self, $value) = @_;

    return unless defined $value;
    return Data::Validate::Domain::is_hostname($value);
}

=head2 is_valid_hostname

Calls `is_hostname` and returns true or false and not the string itself.

=cut

sub is_valid_hostname {
    my ($self, $hostname) = @_;
    return ($self->is_hostname($hostname) ? 1 : 0);
}

=head2 is_username

Does the username checking for the is_email function. Very basic regex
checking in the moment.

=cut

sub is_username {
    my ( $self, $value ) = @_;

    return unless defined $value;

    if($value =~ m/^([a-z0-9_\+\-\.]+)$/i){
        return $value;
    }
    return;
}

=head2 is_valid_username

Calls `is_username` and returns true or false and not the string itself.

=cut

sub is_valid_username {
    my ($self, $username) = @_;
    return ($self->is_username($username) ? 1 : 0);
}

=head2 is_phone

Tests for a valid phone number - needs more work done to it though

=cut

sub is_phone {
    my ($self, $phone) = @_;

    return unless defined $phone;
    if ($phone =~ m/^[\w\s+\(\).-]{3,50}$/) {
        return $phone;
    }
    return;
}   

=head2 is_valid_phone

Calls `is_phone` and returns true or false and not the string itself.

=cut

sub is_valid_phone {
    my ($self, $phone) = @_;
    return ($self->is_phone($phone) ? 1 : 0);
}


=head1 AUTHOR

Lenz Gschwendtner, C<< <norbu09 at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-data-validate-common at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Data-Validate-Common>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Data::Validate::Common


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Data-Validate-Common>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Data-Validate-Common>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Data-Validate-Common>

=item * Search CPAN

L<http://search.cpan.org/dist/Data-Validate-Common/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2011 Lenz Gschwendtner.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.


=cut

1;    # End of Data::Validate::Common
