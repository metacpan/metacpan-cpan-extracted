package Bot::Cobalt::Plugin::Figlet;
# ABSTRACT: Bot::Cobalt plugin for displaying figlets
$Bot::Cobalt::Plugin::Figlet::VERSION = '0.001';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use List::AllUtils qw(shuffle);
use Path::Tiny;
use Text::FIGlet;

sub new     { bless {}, shift }
sub fontdir { path( shift->{fontdir} )->absolute }
sub width   { shift->{maxwidth} }
sub prev    { shift->{previous} }

sub fonts {
   my $self  = shift;
   my $extrx = qr/\.[tf]lf$/;
   
   return map { $_->basename($extrx) } $self->fontdir->children($extrx);
}

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   my $conf = $core->get_plugin_cfg($self);

   $self->{fontdir}  = $conf->{fontdir}  || '/usr/games/lib/figlet';
   $self->{maxwidth} = $conf->{maxwidth} || -1;

   if (not -d $self->fontdir) {
      logger->warn("Unable to find figlet fonts at " . $self->fontdir);
      return PLUGIN_EAT_NONE;
   }

   register( $self, 'SERVER', 'public_cmd_figlet', 'public_cmd_prev_figlet' );

   logger->info("Registered, commands: !figlet, !prev_figlet");

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;

   logger->info("Unregistered");

   return PLUGIN_EAT_NONE;
}

sub Bot_public_cmd_prev_figlet {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   broadcast( 'message', $msg->context, $msg->channel, $self->prev )
      if $self->prev;

   return PLUGIN_EAT_ALL;
}

sub Bot_public_cmd_figlet {
   my $self = shift;
   my $core = shift;

   my $msg     = ${ shift() };
   my $context = $msg->context;
   my $channel = $msg->target;
   my @split   = split(/ /, $msg->stripped);

   shift @split;

   my $str    = join(' ', @split);
   my $font   = (shuffle($self->fonts))[0];
   my $figlet = Text::FIGlet->new(-d => $self->fontdir, -f => $font);
   my $text   = $figlet->figify(-A => $str, -w => $self->width);

   $self->{previous} = $font;

   broadcast( 'message', $context, $channel, $_) 
      foreach split /\n/, $text;

   return PLUGIN_EAT_ALL;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::Figlet - Bot::Cobalt plugin for displaying figlets

=head1 VERSION

version 0.001

=head1 SYNOPSIS

   ## In plugins.conf
   Figlet:
      Module: Bot::Cobalt::Plugin::Figlet
      Opts:
         fontdir: var/fonts # default: /usr/games/lib/figlet
         maxwidth: 160      # default: -1 (no maxwidth)

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

This plugin provides commands to turn text into figlets and broadcast
them in the channel.

It has two commands:

=over 4

=item !figlet Hello, world!

This command text a message, randomly chooses a figlet from the font directory
and uses it to 'figify' the message via L<Text::FIGlet>.

=item !prev_figlet

Broadcasts the name of the previous figlet used.

=back

=head1 TROUBLESHOOTING

As of L<Bot::Cobalt> 0.016002 there is a problem with L<Bot::Cobalt::IRC> and 
it's use of L<POE::Component::IRC::State>. Since figlets are multiple lines of
text the flood check limits the figlet's broadcast pretty significantly, to 
the point of unusability.  

A workaround is to modify L<Bot::Cobalt::IRC> to turn pass in flood => 1 to 
the spawning of L<POE::Component::IRC::State>:

At around line 213 of L<Bot::Cobalt::IRC> simply change:

   my %spawn_opts = (
      resolver => core->resolver,
   +  flood    => 1,

Thanks to Jon Portnoy <avenj@cobaltirc.org> for tracking this down.

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
