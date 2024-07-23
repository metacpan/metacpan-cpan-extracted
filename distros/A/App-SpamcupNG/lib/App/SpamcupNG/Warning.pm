package App::SpamcupNG::Warning;
use strict;
use warnings;
use Carp qw(confess);

our $VERSION = '0.019'; # VERSION

=head1 NAME

App::SpamcupNG::Warning - representation of warnings messages parsed from
Spamcop website HTML.

=head1 SYNOPSIS

    use parent 'App::SpamcupNG::Warning';

=head1 DESCRIPTION

This is a superclass for warning messages parsed from Spamcop website HTML.

=head1 METHODS

=head2 new

Creates a new instance of a warning. Shouldn't be used directly, instead look
for subclasses of C<App::SpamcupNG::Warning>.

Expects as parameter an array reference containing the associated strings.

=cut

sub new {
    my ( $class, $message_ref ) = @_;

    confess 'message must be an array reference with length of at least 1'
      unless ( ( ref($message_ref) eq 'ARRAY' )
        and ( scalar( @{$message_ref} ) > 0 ) );

    my @trimmed;

    foreach my $msg ( @{$message_ref} ) {
        $msg =~ s/^\s+//;
        $msg =~ s/(\s+)?\.?$//;
        push( @trimmed, $msg );
    }

    my $self = { message => \@trimmed };
    bless( $self, $class );
    return $self;
}

=head2 message

Returns the associated message as a string.

=cut

sub message {
    my $self = shift;
    return join( '. ', @{ $self->{message} } ) . '.';
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
