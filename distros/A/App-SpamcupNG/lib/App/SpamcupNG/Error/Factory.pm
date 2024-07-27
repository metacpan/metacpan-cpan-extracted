package App::SpamcupNG::Error::Factory;
use strict;
use warnings;
use Carp qw(confess);
use Exporter 'import';
use Log::Log4perl 1.57 qw(get_logger :levels);

use App::SpamcupNG::Error;
use App::SpamcupNG::Error::Mailhost;
use App::SpamcupNG::Error::Bounce;
use App::SpamcupNG::Error::LoginFailed;

our $VERSION = '0.020'; # VERSION

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

my $mailhost_regex     = qr/Mailhost\sconfiguration\sproblem/;
my $bounce_regex       = qr/bounce/;
my $login_failed_regex = qr/^Login\sfailed/;
my @fatal_errors       = ( qr/email\sis\stoo\sold/, qr/^Nothing/ );

=head1 FUNCTIONS

=head2 create_error

Creates new error from a given message string.

The type of error is identified from this message.

Expects as parameters:

=over

=item *

An array reference where each index is a string line from the original error
message.

=item *

A optional integer, being 0 if the error message is not fatal, 1 otherwise.

It defaults to 0.

=back

Returns an instance of L<App::SpamcupNG::Error> or one of it's subclasses.

=cut

sub create_error {
    my ( $message_ref, $is_fatal ) = @_;
    $is_fatal //= 0;
    my $logger = get_logger('SpamcupNG');

    if ( $logger->is_debug ) {
        $logger->debug('message reference received:');
        $logger->debug( join( ' - ', @{$message_ref} ) );
        $logger->debug("is_fatal: $is_fatal");
    }

    confess 'message must be an no empty array reference'
      unless ( ( ref($message_ref) eq 'ARRAY' )
        and ( scalar( @{$message_ref} ) > 0 ) );

    if ( $message_ref->[0] =~ $mailhost_regex ) {
        $logger->debug('Message is a App::SpamcupNG::Error::Mailhost instance')
          if ( $logger->is_debug );
        return App::SpamcupNG::Error::Mailhost->new($message_ref);
    }

    if ( $message_ref->[0] =~ $bounce_regex ) {
        $logger->debug('Message is a App::SpamcupNG::Error::Bounce instance')
          if ( $logger->is_debug );
        return App::SpamcupNG::Error::Bounce->new( $message_ref, 1 );
    }

    if ( $message_ref->[0] =~ $login_failed_regex ) {
        $logger->debug(
            'Message is a App::SpamcupNG::Error::LoginFailed instance')
          if ( $logger->is_debug );
        return App::SpamcupNG::Error::LoginFailed->new($message_ref);
    }

    if ($is_fatal) {
        $logger->debug(
'Message is a App::SpamcupNG::Error instance because it is classified as fatal'
        ) if ( $logger->is_debug );
        return App::SpamcupNG::Error->new( $message_ref, $is_fatal );
    }

    foreach my $regex (@fatal_errors) {
        if ( $message_ref->[0] =~ $regex ) {
            $is_fatal = 1;
            $logger->debug("Message matches '$regex', so is considered fatal")
              if ( $logger->is_debug );
            last;
        }
    }

    $logger->info('Message is not any subclass of App::SpamcupNG::Error');
    return App::SpamcupNG::Error->new( $message_ref, $is_fatal );
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
