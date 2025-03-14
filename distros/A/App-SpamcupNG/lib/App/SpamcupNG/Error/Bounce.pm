package App::SpamcupNG::Error::Bounce;
use strict;
use warnings;
use parent 'App::SpamcupNG::Error';

our $VERSION = '0.020'; # VERSION

=head1 NAME

App::SpamcupNG::Error::Bounce - an Error subclass that represents a bounce
error.

=head1 SYNOPSIS

See L<App::SpamcupNG::Error::Factory> instead of creating it manually.

=head1 DESCRIPTION

A bounce error means that some issue with your Spamcop account is happening.
This is a fatal error that needs to be fixed before trying to report SPAM
again.

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
    my @temp = @{ $self->{message} };
    $temp[0] =~ s/\:$/,/;
    $temp[1] .= ',';
    $temp[2] .= '.';
    $temp[3] =
'Please, access manually the Spamcop website and fix this before trying to run spamcup again.';
    return join( ' ', @temp );
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
