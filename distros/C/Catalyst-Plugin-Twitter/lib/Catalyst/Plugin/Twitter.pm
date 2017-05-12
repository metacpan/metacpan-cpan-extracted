package Catalyst::Plugin::Twitter;
use base qw/Class::Accessor::Fast/;

use strict;
use warnings;

use MRO::Compat;
use Net::Twitter;
use Data::Dumper;

our $VERSION = '0.01';

BEGIN {
    __PACKAGE__->mk_accessors(
        '_twitter',                  # cached Net::Twitter object
        '_twitter_queued_tweets',    # tweets to send at end of request
    );
}

=head1 NAME

Catalyst::Plugin::Twitter - simple sending of tweets from within Catalyst

=head1 SYNOPSIS

    # configure your app in MyApp.pm
    MyApp->config(
        name    => 'TestApp',
        twitter => {
            username => 'twitter_account_username',
            password => 'twitter_account_password',
        }
    );
    
    # then somewhere in your controllers:
    sub register : Local {
        my ( $self, $c ) = @_;
    
        # --- register new user here ---
    
        # Send a twitter update about the new user
        $c->tweet("We've got another member - $username just registered!");
    
        return 1;
    }

=head1 DESCRIPTION

Twitter (L<http://www.twitter.com>) is a micro-blogging service that lets you
post little updates (up to 140 characters) about yourself. It is used for everything from
documenting the trivial events of a person's day to providing instantanous
updates on road traffic conditions.

This module makes it trivial to send twitter updates (or 'tweets') from within a
Catalyst application. It also attempts to do this is an efficient manner.

=head1 METHODS

=head2 tweet

    $c->tweet('Hello World');
    $c->tweet(
        {   status => 'Hello World',
            # ...any other arguments that Net::Twitter::update accepts
        }
    );

Send out a tweet.

The arguments can either be a simple string (in which case it is used as the
'status') or a hashref of arguments that the L<Net::Twitter> C<update> method
would accept.

The tweet is actually added to a queue and is sent at the end of the request.
This means that any delay caused by sending the tweet should not stall your
request.

=cut

sub tweet {
    my $c    = shift;
    my $args = shift;

    # Convert the args to a hashref if they are a string
    $args = { status => $args } if !ref $args;

    # get the queue, or create it if it does not exist
    my $queue = $c->_twitter_queued_tweets
        || $c->_twitter_queued_tweets( [] );

    # add these argumentns to the queue
    push @$queue, $args;

    return 1;
}

=head2 twitter

    my $net_twitter_object = $c->twitter();

Returns the twitter object. Created the first time it is called and then cached
for the duration of the request.

NOTE: If you manipulate the object returned then you may affect where the stored
tweets are sent at the end of the request so don't do that. Even calling
C<clone> on the object may not do what you expect - see the L<Net::Twitter>
documentation for more details. If you must amnipulate it and want to make sure
that there are no side effects clear the cache afterwards
(C<$C->_twitter(undef)>) and a new object will be created as required.

=cut

sub twitter {
    my $c = shift;

    my $twitter = $c->_twitter;

    if ( !$twitter ) {
        $twitter = Net::Twitter->new( $c->config->{twitter} );
        $c->_twitter($twitter);
    }

    return $twitter;

}

=head1 PRIVATE METHODS

You should not ned to use these methods directly - but they are documented here
so that you know what they are and what they do.

=head2 setup

Check that the required username and password have been provided. Does not check
that the username or password are actually valid.

=cut

sub setup {
    my $c = shift;

    my $config = $c->config->{twitter};

    my $err
        = !$config             ? "Could not find 'twitter' section in config"
        : !$config->{username} ? "Must supply a 'username' in config->twitter"
        : !$config->{password} ? "Must supply a 'password' in config->twitter"
        :                        '';

    if ($err) {
        $c->log->fatal($err);
        Catalyst::Exception->throw($err);
    }

    return $c->next::method(@_);
}

=head2 finalize

Send any tweets that have been queued up after the request is finalized.

=cut

sub finalize {
    my $c = shift;

    # process the request
    my $result = $c->next::method(@_);

    # send the queued tweets
    $c->_twitter_send_queued_tweets;

    return $result;
}

=head2 _twitter

Accessor to the cached L<Net::Twitter> object for this request.

=cut

=head2 _twitter_queued_tweets

Accessor to the array of tweets that were generated during this request.

=cut

=head2 _twitter_send_queued_tweets

    my $count = $c->_twitter_send_queued_tweets;

Method to send all the queued tweets and clear the queue. Returns the number of
tweets that were successfully sent.

=cut

sub _twitter_send_queued_tweets {
    my $c     = shift;
    my $count = 0;

    # get the queue of tweets and then clear it
    my $queue = $c->_twitter_queued_tweets || [];
    $c->_twitter_queued_tweets(undef);

    foreach my $args (@$queue) {

        # Send the actual tweet.
        if ( $c->twitter->update($args) ) {
            $count++;
            next;
        }

        # something went wrong
        warn "ERROR with tweet:\n";
        warn Dumper( $c->twitter->get_error );
        warn "---";

    }

    return $count;
}

=head1 SEE ALSO

L<Net::Twitter> for the documentation of the object returned by C<$c->twitter>.

L<Text::Variations> for ways to make your twitter updates less repetitive.

=head1 AUTHOR

Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>. 

L<http://www.ecclestoad.co.uk/>

=head1 LICENCE AND COPYRIGHT

Copyright (c) 2009, Edmund von der Burg C<< <evdb@ecclestoad.co.uk> >>.
All rights reserved.

This module is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

1;
