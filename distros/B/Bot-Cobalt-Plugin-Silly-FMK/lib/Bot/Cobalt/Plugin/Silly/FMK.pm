package Bot::Cobalt::Plugin::Silly::FMK;
# ABSTRACT: Bot::Cobalt plugin for asking who the bot would F, M, or K
$Bot::Cobalt::Plugin::Silly::FMK::VERSION = '0.001';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use List::AllUtils qw(shuffle uniq);

sub new      { bless {}, shift }
sub copulate { shift->{copulate} }

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   my $cfg  = $core->get_plugin_cfg($self);

   $self->{copulate} = $cfg->{censor} ? $cfg->{censor} : 'Fuck';

   register( $self, 'SERVER', 'public_cmd_fmk' );

   logger->info("Registered, commands: !fmk");

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;

   logger->info("Unregistered");

   return PLUGIN_EAT_NONE;
}

sub Bot_public_cmd_fmk {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   my $context = $msg->context;
   my $channel = $msg->target;

   my @split = split(/ /, $msg->stripped);

   shift @split; # shift off the command

   my $data  = join(' ', @split);
   my @names = uniq( split(/,\s*/, $data) );

   if (@names == 3) {
      @names = shuffle(@names);

      my $resp = sprintf(
         '%s: [%s] - Marry: [%s] - Kill: [%s]',
         ucfirst($self->copulate),
         @names,
      );

      broadcast('message', $context, $channel, $resp);
   }
   else {
      my $resp = sprintf( 
         'You must provide three unique names (seperated by commas) %s-%s-%s',
         $self->copulate, 'marry', 'kill',         
      );
      
      broadcast('message', $context, $channel, $resp); 
   }

   return PLUGIN_EAT_ALL;
}

no List::AllUtils;

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::Silly::FMK - Bot::Cobalt plugin for asking who the bot would F, M, or K

=head1 VERSION

version 0.001

=head1 SYNOPSIS

Because the "game" that this plugin is based on contains a somewhat offensive
word, you can change the word the bot uses to refer to it.

   ## In plugins.conf
   FMK:
      Module: Bot::Cobalt::Plugin::Silly::FMK
      Opts:
         censor: hug

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

Play the game of F-Marry-Kill with the bot.  Essentially you just give it
three names in a comma separated list, and it randomizes them.  A very stupid,
trivial plugin, that people seem to enjoy nonetheless.

   #mychannel> !fmk Scott, Ann, Barry
   < mybot> Hug: [Ann] - Marry: [Barry] - Kill: [Scott]

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
