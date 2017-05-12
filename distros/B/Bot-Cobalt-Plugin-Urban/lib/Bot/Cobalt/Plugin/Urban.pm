package Bot::Cobalt::Plugin::Urban;
# ABSTRACT: Bot::Cobalt plugin for looking up urban dictionary terms
$Bot::Cobalt::Plugin::Urban::VERSION = '0.001';
use strict;
use warnings;

use Bot::Cobalt;
use Bot::Cobalt::Common;

use HTTP::Tiny;
use JSON qw(decode_json);

my $URBAN_API = 'http://api.urbandictionary.com/v0';

sub new { bless {}, shift }

sub Cobalt_register {
   my $self = shift;
   my $core = shift;
   
   register( $self, 'SERVER', 'public_cmd_urban', 'public_cmd_urban_random' );

   logger->info("Registered, commands: !urban, !urban_random");

   return PLUGIN_EAT_NONE;
}

sub Cobalt_unregister {
   my $self = shift;
   my $core = shift;

   logger->info("Unregistered");

   return PLUGIN_EAT_NONE;
}

sub Bot_public_cmd_urban_random {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   my $context = $msg->context;
   my $channel = $msg->target;
   my $nick    = $msg->src_nick;

   my $url   = "$URBAN_API/random";
   my $resp  = HTTP::Tiny->new->get($url);
   my $json  = decode_json($resp->{content});
   my $total = scalar(@{$json->{list}});
   my $idx   = int(rand($total));
   my $entry = $json->{list}->[$idx];

   my $example = '';
   if ($entry->{example}) {
      $example = sprintf(
         '%sExample: %s', 
         $entry->{definition} =~ /\n/ ? "\n" : '- ',
         $entry->{example},
      );
   }

   my $def = sprintf(
      '[%d/%d] %s: %s %s', 
      $idx + 1, 
      $total, 
      $entry->{word},
      $entry->{definition}, 
      $example,
   );

   broadcast( 'message', $context, $channel, $_ ) 
      foreach split /\n/, $def;

   return PLUGIN_EAT_ALL;
}

sub Bot_public_cmd_urban {
   my $self = shift;
   my $core = shift;
   my $msg  = ${ shift() };

   my $context = $msg->context;
   my $channel = $msg->target;
   my $nick    = $msg->src_nick;

   my $url = "$URBAN_API/define?";
   my @split = split(/ /, $msg->stripped);

   shift @split; # shift off the command

   my $idx  = ($split[-1] =~ m/^\d$/) ? ( pop(@split) - 1) : 0;
   my $term = join('+', @split);
   my $resp  = HTTP::Tiny->new->get($url . "term=$term");
   my $json  = decode_json($resp->{content});
   my $total = scalar(@{$json->{list}});
   my $entry = $json->{list}->[$idx];

   if (not defined $entry) {
      my $no_results =   "$nick: That doesn't even exist in urban dictionary, "
                       . "stop making stuff up.";
      broadcast( 'message', $context, $channel, $no_results );
      return PLUGIN_EAT_ALL;
   }

   my $example = '';
   if ($entry->{example}) {
      $example = sprintf(
         '%sExample: %s', 
         $entry->{definition} =~ /\n/ ? "\n" : '- ',
         $entry->{example},
      );
   }

   my $def = sprintf(
      '[%d/%d] %s: %s %s', 
      $idx + 1, 
      $total, 
      $entry->{word},
      $entry->{definition}, 
      $example,
   );

   broadcast( 'message', $context, $channel, $_ )
      foreach split /\n/, $def;

   return PLUGIN_EAT_ALL;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bot::Cobalt::Plugin::Urban - Bot::Cobalt plugin for looking up urban dictionary terms

=head1 VERSION

version 0.001

=head1 SYNOPSIS

   ## In plugins.conf
   Urban:
      Module: Bot::Cobalt::Plugin::Urban      

=head1 DESCRIPTION

A L<Bot::Cobalt> plugin.

This plugin provides commands to look up terms in Urban Dictionary via their
API.

It has two commands:

=over 4

=item !urban <term> <entry #>

This command retrieves the term and, if provided the specific entry number.

   #mychannel> !urban perl 4
   < mybot> [4/9] perl: random line noise that does something useful most of the time

=item !urban_random

Retrieves a random urban dictionary entry.

=back

=head1 LIMITATIONS

It appears that the Urban Dictonary API currently only provides 10 entries for
a given term, and does not provide a mechanism to retrieve additional ones.

=head1 AUTHOR

Scott Miller <scott.j.miller@gmail.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2014 by Scott Miller.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
