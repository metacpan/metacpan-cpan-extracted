#==============================================================================
#
# Bot::BasicBot::Pluggable::Module::TwitterFriendsStatus
#
# DESCRIPTION
#
#   Adds ability for Bot::BasicBot::Pluggable IRC bots to check for comments
#   posted to Twitter for a list of users and echo them into a channel.
#
# AUTHORS
#   Gryphon Shafer <gryphon@cpan.org>
#   David Precious <davidp@preshweb.co.uk>
#
# COPYRIGHT
#   Copyright (C) 2008 by Gryphon Shafer
#
#   This library is free software; you can redistribute it and/or modify it
#   under the same terms as Perl itself.
#
#==============================================================================

package Bot::BasicBot::Pluggable::Module::TwitterFriendsStatus;
use strict;
use warnings;
use LWP::UserAgent;
use XML::Simple 'XMLin';
use Bot::BasicBot::Pluggable::Module;
use base 'Bot::BasicBot::Pluggable::Module';

our $VERSION = 0.2;

use constant {
    CREDENTIALS => {
        'netloc' => 'twitter.com:80',
        'realm'  => 'Twitter API',
    },
    URL => {
        'verify_credentials' => 'http://twitter.com/account/verify_credentials.xml',
        'friends_status'     => 'http://twitter.com/statuses/friends_timeline.xml',
        'friend_add'         => [ 'http://twitter.com/friendships/create/',  '.xml' ],
        'friend_remove'      => [ 'http://twitter.com/friendships/destroy/', '.xml' ],
    },
    TICK_INTERVAL => 60,
};

my $tick_counter = TICK_INTERVAL;

my $ua = LWP::UserAgent->new(
    'agent'        => 'Bot::BasicBot::Pluggable::Module::TwitterFriendsStatus/0.1 ',
    'max_redirect' => 7,
    'parse_head'   => 1,
);

sub help {
    return join( ', ',
        'twitter add <twittername>',
        'twitter remove <twittername>',
        '!twitterauth <username> <password>',
    );
}

sub init {
    my ($self) = @_;
    my ( $username, $password ) = ( $self->get('username'), $self->get('password') );

    if ( $username and $password ) {
        print "Twitter authentication previously successful. Using auth for $username\n";

        $ua->credentials(
            CREDENTIALS->{'netloc'},
            CREDENTIALS->{'realm'},
            $username,
            $password,
        );
    }

    _twitter_friends_status( $self, 0 );
}

sub said {
    my ( $self, $message, $priority ) = @_;
    return unless ( $priority == 2 );

    if (my($user,$pass) = $message->{'body'} =~ /^\s*!\s*twitter\s*auth\s*(\S+)\s+(\S+)/ ) {
        $ua->credentials( CREDENTIALS->{'netloc'}, CREDENTIALS->{'realm'}, $user, $pass );
        my $response = $ua->get( URL->{'verify_credentials'} );
	my $credentials = XMLin($response->content());
        use Data::Dumper;
	warn Dumper($credentials);
	if ( $credentials->{name} eq $user) {
            $self->reply(
                $message,
                "You have properly authenticated to Twitter as $user\n" .
                "This authentication will be saved in the bot memory storage.\n" .
		"$user has $credentials->{followers_count} followers and" .
		"follows $credentials->{friends_count} users.\n"
            );
            $self->set( 'username' => $1 );
            $self->set( 'password' => $2 );
        }
        else {
            $self->reply(
                $message,
                "You have failed to properly authenticate with Twitter as $user",
            );
            $self->set( 'username' => '' );
            $self->set( 'password' => '' );
        }
    }

    elsif ( $message->{'body'} =~ /^\s*twitter\s*add\s*(\S+)/ ) {
        my $response = $ua->post( URL->{'friend_add'}[0] . $1 . URL->{'friend_add'}[1] );
        $self->reply(
            $message,
            "Added $1 to my Twitter following list.",
        );
    }

    elsif ( $message->{'body'} =~ /^\s*twitter\s*remove\s*(\S+)/ ) {
        my $response = $ua->post( URL->{'friend_remove'}[0] . $1 . URL->{'friend_remove'}[1] );
        $self->reply(
            $message,
            "Removed $1 from my Twitter following list.",
        );
    }

    return;
}

sub tick {
    my ($self) = @_;

    $tick_counter++;
    return if ( $tick_counter < TICK_INTERVAL );
    $tick_counter = 0;

    _twitter_friends_status( $self, 1 );

    foreach ( $self->store_keys() ) {
        $self->unset($_) if ( $_ =~ /^\d+$/ and $self->get($_) + 60 * 60 * 50 < time );
    }
}

sub _twitter_friends_status {
    my ( $self, $do_tell ) = @_;

    my $response       = $ua->get( URL->{'friends_status'} );
    my $friends_status = XMLin(
        $response->content(),
        'ForceArray' => 1,
        'KeyAttr'    => [],
    );

    foreach my $status (
        grep { $_->{'user'}[0]{'name'}[0] ne 'woprircbot' }
        @{ $friends_status->{'status'} }
    ) {
        unless ( $self->get( $status->{'id'}[0] ) || 0 ) {
            $self->set( $status->{'id'}[0], time );
            if ($do_tell) {
                $self->tell(
                    $_,
                    sprintf( "[Twitter %s] %s", $status->{'user'}[0]{'name'}[0], $status->{'text'}[0] ),
                ) foreach ( $self->bot()->channels() );
            }
        }
    }
}

1;
__END__

=pod

=head1 NAME

Bot::BasicBot::Pluggable::Module::TwitterFriendsStatus - Echo Twitter comments

=head1 VERSION

This document describes Bot::BasicBot::Pluggable::Module::TwitterFriendsStatus version 0.0.4

=head1 SYNOPSIS

    use ModuleName;
    my $thing = ModuleName->new;

=head1 DESCRIPTION

This module adds the ability for Bot::BasicBot::Pluggable IRC bots to check
for comments posted to Twitter for a list of users and echo them into a channel.

=head1 IRC INTERFACE

=over 4

=item !twitterauth <username> <password>

This results in the bot authenticating with Twitter using an account that it
will ping for friend status. This authentication is stored and should not
have to be re-entered once added.

=item twitter add <username>

Adds a Twitter user to the list of users that the bot should follow.

=item twitter remove <username>

Removes a users from the list of users the bot is following.

=back

=head1 AUTHOR

Gryphon Shafer E<lt>gryphon@cpan.orgE<gt>

David Precious E<lt>davidp@preshweb.co.ukE<gt>

    code('Perl') || die;

=head1 ACKNOWLEDGEMENTS

Thanks to Larry Wall for Perl, Randal Schwartz for my initial and on-
going Perl education, Damian Conway for mental inspiration, Sam Tregar for
teaching me how to write and upload CPAN modules, and the monks of PerlMonks
for putting up with my foolishness.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2008, Gryphon Shafer E<lt>gryphon@cpan.orgE<gt>.
All rights reserved.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=head1 DISCLAIMER OF WARRANTY

Because this software is licensed free of charge, there is no warranty for
the software to the extent permitted by applicable law. Except when
otherwise stated in writing, the copyright holders and/or other parties
provide the software "as is" without warranty of any kind, either expressed
or implied, including but not limited to the implied warranties of
merchantability and fitness for a particular purpose. The entire risk as to
the quality and performance of the software is with the user. Should the
software prove defective, the user shall assume the cost of all necessary
servicing, repair, or correction.

In no event unless agreed to in writing will any copyright holder or any
other party who may modify and/or redistribute the software as permitted by
the above licence be liable to the user for damages including any general,
special, incidental, or consequential damages arising out of the use or
inability to use the software (including but not limited to loss of data or
data being rendered inaccurate or losses sustained by you or third parties
or a failure of the software to operate with any other software), even if
such holder or other party has been advised of the possibility of such
damages.

=cut
