package App::SpamcupNG::Error;
use strict;
use warnings;

our $VERSION = '0.011'; # VERSION

=head1 NAME

App::SpamcupNG::Error - base class for Spamcop website errors

=head1 SYNOPSIS

    use parent 'App::SpamcupNG::Error';

=head1 DESCRIPTION

This is a base class to represent error messages after parsing Spamcop HTML.

=head1 METHODS

=head2 new

Creates a new instance. Instances of C<App::Spamcup::Error> shouldn't be
created directly, use one of the subclasses of it.

Expect as parameters:

- an array reference containing all the strings from the original message. - a
scalar with 0 or 1 to indicate that the message should be considered fatal or
not.

A message parsed from Spamcop website HTML that should stop the SPAM processing
should be considered as fatal.

=cut

sub new {
    my ( $class, $message_ref, $is_fatal ) = @_;
    $is_fatal //= 0;

    die 'message must be an non empty array reference'
        unless ( ( ref($message_ref) eq 'ARRAY' )
        and ( scalar( @{$message_ref} ) > 0 ) );

    for ( my $i = 0; $i < scalar( @{$message_ref} ); $i++ ) {
        $message_ref->[$i] =~ s/^\s+//;
        $message_ref->[$i] =~ s/\s+$//;
    }

    my $self = {
        message  => $message_ref,
        is_fatal => $is_fatal
        };

    bless( $self, $class );
    return $self;
}

=head2 message

Returns the message associated with the error.

=cut

sub message {
    my $self = shift;
    return $self->{message}->[0];
}

=head2 is_fatal

Returns 0 if the error is not fatal, 1 otherwise.

=cut

sub is_fatal {
    my $self = shift;
    return $self->{is_fatal};
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
