package App::Maisha::Plugin::Twitter;

use strict;
use warnings;

our $VERSION = '0.21';

#----------------------------------------------------------------------------
# Library Modules

use base qw(App::Maisha::Plugin::Base);
use base qw(Class::Accessor::Fast);
use File::Path;
use Net::Twitter;
use Storable;

#----------------------------------------------------------------------------
# Accessors

__PACKAGE__->mk_accessors($_) for qw(api users config);

#----------------------------------------------------------------------------
# Public API

#Request token URL
#https://api.twitter.com/oauth/request_token

#Access token URL
#https://api.twitter.com/oauth/access_token

#Authorize URL
#https://api.twitter.com/oauth/authorize

# http://dev.twitter.com/apps/347040

sub new {
    my $class = shift;
    my $self = {
        consumer_key    => 'ifCuNOQXA5KTnKVXVcZg',
        consumer_secret => 'OXyHE1PSgfy66gbCu3QshXgP9RNA1fOVLdqv4afPDug',
    };

    bless $self, $class;
    return $self;
}

sub login {
    my ($self,$config) = @_;
    my $api;

    unless($config->{username}) { warn "No username supplied\n"; return }

    eval {
        $api = Net::Twitter->new(
            traits              => [qw/API::Search API::REST OAuth/],
            consumer_key        => $self->{consumer_key},
            consumer_secret     => $self->{consumer_secret},
            ssl                 => 1
        );
    };

    unless($api) {
        warn "Unable to establish connection to Twitter API\n";
        return 0;
    }

    # for testing purposes we don't want to login
    if(!$config->{test}) {
        eval {
            my $datafile = $config->{home} . '/.maisha/twitter.dat';
            my $access_tokens = eval { retrieve($datafile) } || {};

            if ( $access_tokens && $access_tokens->{$config->{username}}) {
                $api->access_token($access_tokens->{$config->{username}}->[0]);
                $api->access_token_secret($access_tokens->{$config->{username}}->[1]);
            } else {
                my $auth_url = $api->get_authorization_url;
                print " Authorize this application at: $auth_url\nThen, enter the PIN# provided to continue: ";

                my $pin = <STDIN>; # wait for input
                chomp $pin;

                unless($pin) {
                    warn "No PIN provided, Maisha will not be able to access Twitter account until authorized to do so\n";
                    return 0;
                }

                # request_access_token stores the tokens in $nt AND returns them
                my $access_tokens = {};
                my @access_tokens;
                eval { @access_tokens = $api->request_access_token(verifier => $pin) };
                unless(@access_tokens) {
                    warn "Invalid PIN provided, Maisha will not be able to access your Twitter account until authorized to do so\n";
                    return 0;
                }
                $access_tokens->{$config->{username}} = \@access_tokens;

                mkpath( $config->{home} . '/.maisha' );

                # save the access tokens
                store $access_tokens, $datafile;
                chmod 0640, $datafile;  # make sure it has reasonable permissions
            }
        };

        if($@) {
            warn "Unable to login to Twitter\n";
            return 0;
        }
    }

    $self->api($api);
    $self->config($config);

    if(!$config->{test}) {
        print "...building user cache for Twitter\n";
        $self->_build_users();
    }

    return 1;
}

sub _build_users {
    my $self = shift;
    my %users;

    eval {
        my $f = $self->api->friends();
        if($f && @$f)   { for(@$f) { next unless($_); $users{$_->{screen_name}} = 1 } }
        $f = $self->api->followers();
        if($f && @$f)   { for(@$f) { next unless($_); $users{$_->{screen_name}} = 1 } }
    };

    if($@) {
        warn "Error retrieving friends/followers from Twitter: $@\n";
        return;
    }

    $self->users(\%users);
}

sub api_reauthorize {
    my $self    = shift;
    my $config  = $self->config;
    my $api     = $self->api;

    # for testing purposes we don't want to login
    if(!$config->{test}) {
        eval {
            my $datafile = $config->{home} . '/.maisha/twitter.dat';

            my $auth_url = $api->get_authorization_url;
            print "Please re-authorize this application at: $auth_url\nThen, enter the PIN# provided to continue: ";

            my $pin = <STDIN>; # wait for input
            chomp $pin;

            unless($pin) {
                warn "No PIN provided, Maisha will not be able to access direct messages until reauthorization is completed\n";
                return 0;
            }

            # request_access_token stores the tokens in $nt AND returns them
            my $access_tokens = {};
            my @access_tokens;
            eval { @access_tokens = $api->request_access_token(verifier => $pin) };
            unless(@access_tokens) {
                warn "Invalid PIN provided, Maisha will not be able to access direct messages until reauthorization is completed\n";
                return 0;
            }
            $access_tokens->{$config->{username}} = \@access_tokens;

            unlink $datafile;
            mkpath( $config->{home} . '/.maisha' );

            # save the access tokens
            store $access_tokens, $datafile;
            chmod 0640, $datafile;  # make sure it has reasonable permissions
        };

        if($@) {
            warn "Unable to login to Twitter\n";
            return 0;
        }
    }

    return 1;
}

sub api_follow {
    my $self = shift;
    $self->api->create_friend(@_);
}

sub api_unfollow {
    my $self = shift;
    $self->api->destroy_friend(@_);
}

sub api_user {
    my $self = shift;
    $self->api->show_user(@_);
}

sub api_user_timeline {
    my $self = shift;
    $self->api->user_timeline(@_);
}

sub api_friends {
    my $self = shift;
    $self->api->following(@_);
}

sub api_friends_timeline {
    my $self = shift;
    $self->api->following_timeline(@_);
}

sub api_public_timeline {
    my $self = shift;
    $self->api->public_timeline(@_);
}

sub api_followers {
    my $self = shift;
    $self->api->followers(@_);

    # below is meant to be the same as the above, but it isn't :(
    #$self->api->lookup_users( { user_id => $self->api->followers_ids() } );
}

sub api_update {
    my $self = shift;
    $self->api->update(@_);
}

sub api_replies {
    my $self = shift;
    $self->api->replies(@_);
}

sub api_send_message {
    my $self = shift;
    $self->api->new_direct_message(@_);
}

sub api_direct_messages_to {
    my $self = shift;
    $self->api->direct_messages(@_);
}

sub api_direct_messages_from {
    my $self = shift;
    $self->api->sent_direct_messages(@_);
}

sub api_search {
    my $self = shift;
    $self->api->search(@_);
}

1;

__END__

=head1 NAME

App::Maisha::Plugin::Twitter - Maisha interface to Twitter

=head1 SYNOPSIS

   maisha
   maisha> use Twitter
   use ok

=head1 DESCRIPTION

App::Maisha::Plugin::Twitter is the gateway for Maisha to access the Twitter
API.

=head1 METHODS

=head2 Constructor

=over 4

=item * new

=back

=head2 Process Methods

=over 4

=item * login

Login to the service. See Authentication below.

=back

=head2 API Methods

The API methods are used to interface to with the Twitter API.

=over 4

=item * api_reauthorize

=item * api_follow

=item * api_unfollow

=item * api_user

=item * api_user_timeline

=item * api_friends

=item * api_friends_timeline

=item * api_public_timeline

=item * api_followers

=item * api_update

=item * api_replies

=item * api_send_message

=item * api_direct_messages_to

=item * api_direct_messages_from

=item * api_search

=back

=head1 AUTHENTICATION

On 31st August 2010, Twitter disabled Basic Authentication to access their API.
Instead they have introduce the OAuth method of authrntication, which now 
requires application developers to request the user to authenticate themselves 
and provide a PIN (Personal Identification Number) to allow the application to
retrieve access tokens.

With this new method of authentication, the application will provide a URL,
which the user needs to cut-n-paste into a browser to logging in to the 
service, using your regular username/password, then 'Allow' Maisha to access 
your account. This will then allow Maisha to post to your account. You will 
then be given a PIN, which should then be entered at the prompt on the Maisha
command line.

Once you have completed authentication, the application will then store your 
access tokens permanently under your profile on your computer. Then when you
next use the application it will retrieve these access tokens automatically and
you will no longer need to register the application.

=head1 SEE ALSO

For further information regarding the commands and configuration, please see
the 'maisha' script included with this distribution.

L<App::Maisha>

L<Net::Twitter>

=head1 WEBSITES

=over 4

=item * Main Site: L<http://maisha.grango.org>

=item * Git Repo:  L<http://github.com/barbie/maisha/tree/master>

=item * RT Queue:  L<RT: http://rt.cpan.org/Public/Dist/Display.html?Name=App-Maisha>

=back

=head1 AUTHOR

  Barbie, <barbie@cpan.org>
  for Miss Barbell Productions <http://www.missbarbell.co.uk>.

=head1 COPYRIGHT AND LICENSE

  Copyright (C) 2009-2014 by Barbie

  This distribution is free software; you can redistribute it and/or
  modify it under the Artistic License v2.

=cut
