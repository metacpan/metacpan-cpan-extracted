package App::SpamcupNG::Error::Mailhost;
use strict;
use warnings;
use parent 'App::SpamcupNG::Error';

our $VERSION = '0.011'; # VERSION

=head1 NAME

App::SpamcupNG::Error::Mailhost - representation of a Spamcop mailhost
configuration error.

=head1 SYNOPSIS

See L<App::SpamcupNG::Error::Factory> to create an instance of this class.

=head1 DESCRIPTION

=head1 METHODS

=head2 new

Creates a new instance. Expects as parameter an array reference which every
index is a string of the message.

=cut

sub new {
    my ( $class, $message_ref ) = @_;
    die 'message must be an array reference with size = 3'
        unless ( ( ref($message_ref) eq 'ARRAY' )
        and ( scalar( @{$message_ref} ) == 3 ) );

    return $class->SUPER::new($message_ref);
}

=head2 message

Overrided from superclass, with required additional parsing.

=cut

sub message {
    my $self = shift;
    my @temp = @{ $self->{message} };
    $temp[0] = $temp[0] . '.';
    $temp[2] = lc( $temp[2] ) . '.';
    return join( ' ', @temp );
}

=head1 AUTHOR

Alceu Rodrigues de Freitas Junior, E<lt>arfreitas@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2018 of Alceu Rodrigues de Freitas Junior,
E<lt>arfreitas@cpan.orgE<gt>

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
