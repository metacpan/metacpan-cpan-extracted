package Bot::Cobalt::Plugin::RandomQuote;
# ABSTRACT: Bot::Cobalt plugin for retrieving random quotes from files
$Bot::Cobalt::Plugin::RandomQuote::VERSION = '0.001';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use Path::Tiny;

sub new { bless {}, shift }

sub quotesdir { shift->{quotesdir} }
sub commands  { shift->{commands}  }

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   my $conf = $core->get_plugin_cfg($self);

   my $quotesdir = $conf->{quotedir} // path( $core->var, 'quotes' );
   $self->{quotesdir} = path($quotesdir)->absolute;
   $self->{commands}  = [];

   my @files = $self->quotesdir->children;

   foreach my $file (@files) {
      next if not $file->is_file;

      my $cmd = lc( $file->basename(qr/\..+$/) );
      my $handler = sub {
         my $self = shift;
         my $core = shift;
         my $msg  = ${ shift() };

         my $channel = $msg->channel;
         my $context = $msg->context;
         my $nick    = $msg->src_nick;

         my @lines = grep { /\W/ } ( $file->lines );
         my $num   = int(rand(@lines));
         my $quote = $lines[$num];
         
         $quote =~ s/\$\{nick\}/$nick/g;
         $quote =~ s/\$\{channel\}/$channel/g;
         
         broadcast( 'message', $context, $channel, $quote );

         return PLUGIN_EAT_ALL;
      };

      {
         no strict 'refs';
         *{__PACKAGE__ . '::Bot_public_cmd_' . $cmd } = $handler;
      }

      logger->info('Registered, command: !' . $cmd);

      push @{ $self->{commands} }, $cmd;

      register( $self, 'SERVER', 'public_cmd_' . $cmd );
   }

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;

   foreach my $cmd (@{ $self->commands }) {      
      unregister($self, 'SERVER', 'public_cmd_' . $cmd);
   }

   logger->info("Unregistered");

   return PLUGIN_EAT_NONE;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::RandomQuote - Bot::Cobalt plugin for retrieving random quotes from files

=head1 VERSION

version 0.001

=head1 SYNOPSIS

   ## In plugins.conf
   RandomQuote:
      Module: Bot::Cobalt::Plugin::RandomQuote
      Opts:
         quotedir: <path to dir with quote files>

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

This plugin takes a directory with text files in it, and then creates commands,
one for each file basename without the extension.  In this file it is assumed
each line is a quote, and will randomly pick one.

For example if I have a file named 'moon.txt' with the contents:

   Say goodbye, cavemen! Go beat rocks together!
   Let’s leave this primitive rock because there's nothing but cavemen here.
   The explosion shall be of extraordinary magnitude. Just hang on.
   If you have a problem with that maybe you should take that up with Mr. Laser.
   Yes, on the moon nerds get their pants pulled down and they are spanked with moon rocks!
   Here on the moon, our weekends are so advanced, they encompass the entire week.

And in the channel:

   #mychannel> !moon
   < mybot> The explosion shall be of extraordinary magnitude. Just hang on.

You may use the special tags ${nick} and ${channel} in your quotes to replace
them with the src_nick and channel the command was executed in, respectively.

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
