package App::SpamcupNG::Error::LoginFailed;
use strict;
use warnings;
use parent 'App::SpamcupNG::Error';

our $VERSION = '0.018'; # VERSION

=head1 NAME

App::SpamcupNG::Error::LoginFailed - an Error subclass that represents a login
attempt that failed.

=head1 SYNOPSIS

See L<App::SpamcupNG::Error::Factory> instead of creating it manually.

=head1 DESCRIPTION

A login failed means there is a problem with your Spamcop account credentials.

=head1 METHODS

=head2 new

Creates a new instance.

Expects as parameter an array reference containing the bounce error message.

A instance of this class is always considered as fatal.

=cut

sub new {
    my ( $class, $message_ref ) = @_;
    return $class->SUPER::new( $message_ref, 1 );
}

=head2 message

Overrided from the parent class, adding required behavior.

=cut

sub message {
    my $self = shift;
    my $additional =
        ' Also consider obtaining a password to Spamcop.net instead of using '
      . 'the old-style authorization token.';

    return join( '.', ( $self->{message}->[0], $additional ) );
}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>glasswalk3r@yahoo.com.brE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>glasswalk3r@yahoo.com.brE<gt>

This file is part of App-SpamcupNG distribution.

App-SpamcupNG is free software: you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation, either version 3 of the License, or (at your option) any later
version.

App-SpamcupNG is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
App-SpamcupNG. If not, see <http://www.gnu.org/licenses/>.

=cut

1;
