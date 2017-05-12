package Bot::Cobalt::Plugin::Twitter;
# ABSTRACT: Bot::Cobalt plugin for automatic tweeting
$Bot::Cobalt::Plugin::Twitter::VERSION = '0.001';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use HTML::Entities    qw(decode_entities);
use Net::Twitter;
use Text::Unidecode   qw(unidecode);
use URI::Title        qw(title);
use URI::Find::Simple qw(list_uris);

my $status_rx = qr/twitter\.com\/\w+\/status\/(\d+)/;

sub new     { bless {}, shift  }
sub twitter { shift->{twitter} }

sub tweet_topics   { shift->{tweet_topics}   }
sub tweet_links    { shift->{tweet_links}    } 
sub retweet_tweets { shift->{retweet_tweets} }

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   my $conf = $core->get_plugin_cfg($self);

   $self->{tweet_topics}   = $conf->{tweet_topics} // 1;
   $self->{tweet_links}    = $conf->{tweet_links};
   $self->{retweet_tweets} = $conf->{retweet_tweets};

   eval {
      $self->{twitter} = Net::Twitter->new(
         traits              => [ qw(API::RESTv1_1 RetryOnError) ],
         consumer_key        => $conf->{consumer_key},
         consumer_secret     => $conf->{consumer_secret},
         access_token        => $conf->{access_token},
         access_token_secret => $conf->{access_token_secret},
         ssl                 => 1,
      );      
   };

   if (my $err = $@) {
      logger->warn("Unable to create Net::Twitter object: $err");
   }

   register( $self, 'SERVER', qw(public_msg public_cmd_tweet topic_changed) );
   logger->info("Registered, commands: !tweet");

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;

   logger->info("Unregistered");
   
   return PLUGIN_EAT_NONE;
}

sub Bot_topic_changed {
   my $self  = shift;
   my $core  = shift;
   my $topic = ${ shift() };

   return PLUGIN_EAT_NONE if not $self->tweet_topics;

   my $new_topic = $topic->stripped;
   my $status = substr($new_topic, 0, 139);

   $self->twitter->update($status);

   return PLUGIN_EAT_NONE;
}

sub Bot_public_cmd_tweet {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   my $context = $msg->context;
   my $channel = $msg->target;
   my $nick    = $msg->src_nick;

   my @split = split(/ /, $msg->stripped);

   shift @split; # shift off the command

   my $status = substr( join(' ', @split), 0, 139);

   $self->twitter->update($status);

   return PLUGIN_EAT_ALL;
}

sub Bot_public_msg {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   return PLUGIN_EAT_NONE unless $self->tweet_links or $self->retweet_tweets;

   my $context = $msg->context;
   my $channel = $msg->target;

   foreach my $uri ( list_uris($msg->message) ) {
      next if not $uri;

      # There's probably a less fragile way to do this...
      if ($self->retweet_tweets and $uri =~ $status_rx ) {
         my $id = $1;

         if ($self->retweet_tweets) {
            eval { $self->twitter->retweet($id) };
            if (my $err = $@) {
               logger->warn(
                  "Failed to retweet [$id] - " . $err->twitter_error_text,
               );
            }
         }
      }
      elsif ($self->tweet_links) {         
         my $title = decode_entities(title($uri)) or next;         
         my $uni   = unidecode($title) || $title;
         my $short = substr($uni, 0, 100);

         if (length($short) < length($uni)) {
            $short = "$short...";
         }

         eval { $self->twitter->update("$short - $uri") };

         if (my $err = $@) {
            logger->warn(
               "Failed to tweet URL [$uri]: " . $err->twitter_error_text,
            );
         }
      }
   }
   return PLUGIN_EAT_NONE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::Twitter - Bot::Cobalt plugin for automatic tweeting

=head1 VERSION

version 0.001

=head1 SYNOPSIS

   ## In plugins.conf
   Twitter:
      Module: Bot::Cobalt::Plugin::Twitter
      Config: plugins/twitter.conf
      Opts:
         retweet_tweets: 0
         tweet_links: 0
         tweet_topics: 1

   ## In plugins/twitter.conf
   ---
   consumer_key:        <twitter consumer key>
   consumer_secret:     <twitter consumer secret>
   access_token:        <twitter access token>
   access_token_secret: <twitter access token secret>

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

This plugin does a handful of twitter-related functions.

=over 4

=item tweet_links (default: off)

Whenever a link is tweeted, tweet it (with title).

=item retweet_tweets (default: off)

Whenever a tweet is linked, retweet it.

=item tweet_topics (default: on)

Whenever a topic changes, tweet it.

=item !tweet

Finally a command, !tweet that will tweet the message you provide it.

=back

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
