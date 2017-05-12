package Bot::Cobalt::Plugin::URLTitle;
# ABSTRACT: Bot::Cobalt plugin for printing the title of a URL
$Bot::Cobalt::Plugin::URLTitle::VERSION = '0.002';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use HTML::Entities    qw(decode_entities);
use Text::Unidecode   qw(unidecode);
use URI::Title        qw(title);
use URI::Find::Simple qw(list_uris);

sub new     { bless {}, shift  }
sub twitter { shift->{twitter} }

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   my $conf = $core->get_plugin_cfg($self);

   eval {
      require Net::Twitter;

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

   register( $self, 'SERVER', 'public_msg' );
   logger->info("Registered");

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;

   logger->info("Unregistered");
   
   return PLUGIN_EAT_NONE;
}

sub Bot_public_msg {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   my $context = $msg->context;
   my $channel = $msg->target;

   foreach my $uri ( list_uris($msg->message) ) {
      next if not $uri;

      # There's probably a less fragile way to do this...
      if ($uri =~ /twitter\.com\/\w+\/status\/(\d+)/ and $self->twitter) {
         my $id = $1;

         my $tweet = $self->twitter->show_status($id);
         my $text  = $tweet->{text};
         my $name  = $tweet->{user}->{name};
         my $sname = $tweet->{user}->{screen_name};
         my $user  = sprintf '%s (@%s)', $name, $sname;

         $text = unidecode(decode_entities($text));
         my @lines  = split /\n/, $text;

         if (@lines == 1) {
            broadcast( 'message', $context, $channel, "$user - $lines[0]" );
         }
         else {
            broadcast( 'message', $context, $channel, $user );
            broadcast( 'message', $context, $channel, " - $_" )
               foreach @lines;
         }
      }
      else {
         my $title = decode_entities(title($uri)) or next;         
         my $uni   = unidecode($title);
         my $resp  = sprintf('[ %s ]', $uni ? $uni : $title);
         broadcast( 'message', $context, $channel, $resp );
      }
   }

   return PLUGIN_EAT_NONE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::URLTitle - Bot::Cobalt plugin for printing the title of a URL

=head1 VERSION

version 0.002

=head1 SYNOPSIS

   ## In plugins.conf
   URLTitle:
      Module: Bot::Cobalt::Plugin::URLTitle
      Config: plugins/twitter.conf # optional

   ## In plugins/twitter.conf
   ---
   consumer_key:        <twitter consumer key>
   consumer_secret:     <twitter consumer secret>
   access_token:        <twitter access token>
   access_token_secret: <twitter access token secret>

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

This plugin retrieves the title of any URL in a message using 
L<URI::Title> and prints the message to the channel. 

It has optional support for links of tweets via L<Net::Twitter> in which it
will print the contents of the tweet rather than the title.

   #mychannel> https://twitter.com/twitter/status/145344012
   < mybot> Twitter (@twitter) - working on iphones via 'hahlo' and 'pocket tweets' - fun!

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
