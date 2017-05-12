###########################################
package Bot::Webalert;
###########################################
use strict;
use warnings;
use Bot::BasicBot;
use Log::Log4perl 1.05 qw(:easy);
use POE;
use POE::Component::Client::HTTP;
use HTTP::Cookies;
use base qw( Bot::BasicBot );

our $VERSION = "0.01";

###########################################
sub new {
###########################################
    my($class, %options) = @_;

    %options = (
        nick => "webalert-bot",
        %options,
    );

    if(! exists $options{server} or
       ! exists $options{channels} or
       ! exists $options{ua_request} ) {
       LOGDIE "Missing mandatory parameters server/channels/ua_request";
    }

    my $self = $class->SUPER::new(
        map { $_ => $options{ $_ } } qw(server channels nick),
    );

    $self = {
        alias                   => "webalert-bot",
        ua_fetch_interval       => 60*60, # every hour
        ua_timeout              => 60,
        ua_alias                => "webalert-bot-fetcher",
        ua_callback             => \&default_callback,
        ua_request              => undef,
        default_callback_status => undef,
        %options,
        %$self,
    };

    # re-bless
    bless($self, $class);

    if(! defined $self->{ua_request}) {
       LOGDIE "Missing mandatory parameters ua_callback/ua_request";
    }

    $self->spawn();

    return $self;
}

###########################################
sub spawn {
###########################################
    my($self) = @_;

  if( POE::Kernel->alias_resolve( $self->{ua_alias} ) ) {
      DEBUG "Not spawning $self->{ua_alias} session (there's one already)";
      return 1;
  }

  DEBUG "Spawning POE::Component::Client::HTTP aliased '$self->{ua_alias}'";

      # Spawn the UA with a cookie jar
  POE::Component::Client::HTTP->spawn(
    Alias     => $self->{ua_alias},
    Timeout   => $self->{ua_timeout},
    CookieJar => HTTP::Cookies->new(),
  );

  POE::Session->create(
    object_states => [
      $self => {
        _start     => "_start",
        http_start => "http_start",
        http_ready  => "http_ready",
      }
    ]
  );
}

###########################################
sub _start {
###########################################
    my($self) = @_;

      # Wait 20 secs before the first fetch
    POE::Kernel->delay('http_start', 20);
}
  
###########################################
sub http_start {
###########################################
    my($self) = @_;

    DEBUG "Fetching url ", $self->{ua_request}->url->as_string();
    POE::Kernel->post($self->{ua_alias}, "request",
        "http_ready", $self->{ua_request});
    POE::Kernel->delay('http_start',
        $self->{ua_fetch_interval});
}
  
###########################################
sub http_ready {
###########################################
    my($self) = @_;

    DEBUG "http_ready ", $self->{ua_request}->url->as_string();
    my $resp= $_[ARG1]->[0];

    my $cb_string = $self->{ua_callback}->( $resp, $self );

    if(defined $cb_string) {
        INFO "Sending '$cb_string' to $self->{channels}->[0]";
        $self->say(channel => $self->{channels}->[0],
            body    => $cb_string,
        );
    } else {
        DEBUG "Callback returned undef (no message to IRC)";
    }

    POE::Kernel->alias_set( $self->{alias} );
}

###########################################
sub default_callback {
###########################################
    my($response, $bot) = @_;

    if($response->is_success()) {
        if(! defined $bot->{default_callback_status} or
           $bot->{default_callback_status} ne $response->content()) {
           $bot->{default_callback_status} = $response->content();
           return $response->request->url->as_string() . " has changed!";
       }
    }

    return undef;
}

###########################################
sub log {
###########################################
    my($self, @msgs) = @_;

    local $Log::Log4perl::caller_depth;
    $Log::Log4perl::caller_depth++;

    DEBUG @msgs;
}

1;

__END__

=head1 NAME

Bot::Webalert - IRC bot watches Web sites and reports changes to IRC channels

=head1 SYNOPSIS

    use Bot::Webalert;
    use HTTP::Request::Common;

    my $bot = Bot::Webalert->new(
        server      => 'irc.example.com',
        channels    => ["#friends_of_webalert"],
        ua_request  => GET("http://somewhere/changes.rss"),
    );

    $bot->run();

=head1 DESCRIPTION

Bot::Webalert implements an IRC bot that periodically checks the
content of a web page and sends a message to an IRC channel if there
are interesting changes. 

Changes are determined by a user-defined callback function that gets
called by the bot with the HTTP response object and either returns
undef or a string with the message it wants the bot to send to the
IRC channel. Typically, this is some explanatory text and the URL of
the watched web page, so channel users can click on the link to see
what's new.

The easiest way to write a web-watching bot is to let Bot::Webalert use
its default response handler, which posts a message whenever the watched
web page changes:

    use Bot::Webalert;
    use HTTP::Request::Common;

    my $bot = Bot::Webalert->new(
        server      => 'irc.example.com',
        channels    => ["#friends_of_webalert"],
        ua_request  => GET("http://somewhere/changes.rss"),
    );

    $bot->run();

This will fetch the URL specified once per hour and call
Bot::Webalert's default response handler, which triggers a message to
the IRC channel the first time it is run and then whenever the
web server's response is different from the previous one. The message 
sent by the default handler looks like

    webalert-bot says: http://foobar.com has changed!

and will be sent to all channels specified in the C<channels> option.
If you'd like to customize the message or have better control over what kind
of changes are reported, write your own response handler:

    use Bot::Webalert;
    use HTTP::Request::Common;

    my $bot = Bot::Webalert->new(
            server   => 'irc.freenode.net',
            channels => ["#friends_of_webalert"],
            ua_request  => GET("http://somewhere/changes.rss"),
            ua_fetch_interval => 60, # check every minute
            ua_callback       => \&response_handler,
    );

    my $old_content = "";

    sub response_handler {
        my($resp) = @_;

        if( $resp->is_success() ) {
            my $new_content = $resp->content();
            if($old_content ne $new_content) {
                $old_content = $new_content;
                return "Ladies and Gentlemen, new content on " .
                    $resp->request->url->as_string() . " !";
            }
        }
        return undef;
    }

    $bot->run();

The response handler above returns a customized message if the fetch
was successful and the web content has changed since the last call.
Bot::Webalert will send the string returned by the response handler to
the channel. If the response handler returns undef, no message will
be sent.

=head2 Bot::BasicBot

Bot::Webalert ist a subclass of Tom Insam's excellent Bot-BasicBot package
on CPAN. It uses POE under the hood, and Bot::Webalert adds further 
POE components like the POE::Component::Client::HTTP component to 
fetch web pages.

=head2 Logging

Bot::Webalert is Log4perl-enabled, so you can enable its embedded
logging statements simply by initializing Log4perl:

    use Log::Log4perl qw(:easy);
    Log::Log4perl->easy_init($DEBUG);

As usual with Log4perl, you can enable logging in different parts of
the system by initializing it differently, check log4perl.com for details.

=head1 LEGALESE

Copyright 2009 by Mike Schilli, all rights reserved.
This program is free software, you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 AUTHOR

2009, Mike Schilli <cpan@perlmeister.com>
