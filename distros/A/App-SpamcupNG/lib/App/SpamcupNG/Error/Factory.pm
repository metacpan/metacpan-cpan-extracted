package App::SpamcupNG::Error::Factory;
use strict;
use warnings;
use Exporter 'import';

use App::SpamcupNG::Error;
use App::SpamcupNG::Error::Mailhost;
use App::SpamcupNG::Error::Bounce;

our $VERSION = '0.010'; # VERSION

=head1 NAME

App::SpamcupNG::Error::Factory - factory design pattern to create new instances
of errors parsed from Spamcop website HTML.

=head1 SYNOPSIS

    use App::SpamcupNG::Error::Factory qw(create_error);

=head1 DESCRIPTION

=head1 EXPORTS

The function C<create_error> is the only things exported by this module.

=cut

our @EXPORT_OK = qw(create_error);

my $mailhost_regex = qr/Mailhost\sconfiguration\sproblem/;
my $bounce_regex   = qr/bounce/;
my @fatal_errors   = ( qr/email\sis\stoo\sold/, qr/^Nothing/ );

=head1 FUNCTIONS

=head2 create_error

Creates new error from a given message string.

The type of error is identified from this message.

Expects as parameters:

- an array reference where each index is a string line from the original error
message.

- a integer, being 0 if the error message is not fatal, 1 otherwise.

Returns an instance of App::SpamcupNG::Error or one of it's subclasses.

=cut

sub create_error {
    my ( $message_ref, $is_fatal ) = @_;
    $is_fatal //= 0;

    die 'message must be an no empty array reference'
        unless ( ( ref($message_ref) eq 'ARRAY' )
        and ( scalar( @{$message_ref} ) > 0 ) );

    return App::SpamcupNG::Error::Mailhost->new($message_ref)
        if ( $message_ref->[0] =~ $mailhost_regex );

    return App::SpamcupNG::Error::Bounce->new( $message_ref, 1 )
        if ( $message_ref->[0] =~ $bounce_regex );

    return App::SpamcupNG::Error->new( $message_ref, $is_fatal )
        if ($is_fatal);

    foreach my $regex (@fatal_errors) {
        if ( $message_ref->[0] =~ $regex ) {
            $is_fatal = 1;
            last;
        }
    }

    return App::SpamcupNG::Error->new( $message_ref, $is_fatal );
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

