package Bot::Cobalt::Plugin::SeenURL;
# ABSTRACT: Bot::Cobalt plugin for detecting re-linked URLs
$Bot::Cobalt::Plugin::SeenURL::VERSION = '0.003';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;
use Bot::Cobalt::DB;

use DateTime::Tiny;
use File::Spec;
use URI::Find::Simple qw(list_uris);

sub new { bless {}, shift }

sub db           { shift->{db}           }
sub allow_relink { shift->{allow_relink} }

sub linked {
   my $self    = shift;
   my $url     = shift;
   my $nick    = shift;
   my $channel = shift;

   my $links;
   my $linked;

   $self->db->dbopen;

   if ( $links = $self->db->get($url) ) {
      foreach my $link (@$links) {         
         if ($link->{channel} eq $channel) {            
            $linked = $link;
            last;
         }
      }
   }

   if ( not defined $linked ) {
      my $link = {
         datetime => DateTime::Tiny->now->as_string,
         channel  => $channel,
         nick     => $nick,
      };

      if ( defined $links ) {
         push @$links, $link;         
      }
      else {         
         $links = [ $link ];
      }      
      $self->db->put($url => $links);      
   }

   $self->db->dbclose;

   return $linked;
}

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   my $conf = $core->get_plugin_cfg($self);

   $self->{allow_relink} = $conf->{allow_relink} // 1;

   my $dbfile = $conf->{dbfile} || 'seenurl.db';
   my $db     = File::Spec->catfile( $core->var, $dbfile );

   $self->{db} = Bot::Cobalt::DB->new( File => $db ); 

   register( $self, 'SERVER', 'public_msg' );

   logger->info("Registered");

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;
   return PLUGIN_EAT_NONE;
}

sub Bot_public_msg {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   my $context = $msg->context;
   my $channel = $msg->target;
   my $nick    = $msg->src_nick;

   my $relink = 0;

   foreach my $uri ( list_uris($msg->message) ) {
      next if not $uri;

      if ( my $link = $self->linked($uri, $nick, $channel) ) {
         if ( $nick eq $link->{nick} ) {
            $relink++;
            next if $self->allow_relink;
         }

         my $dt = DateTime::Tiny->from_string($link->{datetime});

         my $resp = sprintf( 
            "OLD! ( linked on %04d-%02d-%02d at %02d:%02d:%02d by %s )",
            $dt->year, $dt->month,  $dt->day,
            $dt->hour, $dt->minute, $dt->second,
            $link->{nick},
         );
            
         broadcast( 'message', $context, $channel, $resp );
         $relink++;
         next;
      }
   }

   return $relink ? PLUGIN_EAT_ALL : PLUGIN_EAT_NONE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::SeenURL - Bot::Cobalt plugin for detecting re-linked URLs

=head1 VERSION

version 0.003

=head1 SYNOPSIS

   ## In plugins.conf
   SeenURL:
      Module: Bot::Cobalt::Plugin::SeenURL
      Opts:
         allow_relink: 1
         dbfile: seenurl.db
      Priority: 2

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

This plugin will watch for URLs linked and inform the linker (and the channel)
it has already been linked.

Two options are provided, 'allow_relink' which will not issue an OLD message 
if the same person relinks (defaults to true), and 'dbfile' which states where
the database file will sit under the cobalt 'var' directory.

   #mychannel> https://metacpan.org/pod/distribution/Bot-Cobalt-Plugin-SeenURL
   < mybot> OLD! ( linked on 2014-05-24 at 21:09:46 by sjm )

Because this module is useful for preventing other URL-based modules from
firing, you may wish to give it a higher priority than the default '1'

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
