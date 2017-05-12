#!/usr/bin/perl -w

# This bot should not be run by any sane person. Really. The original idea
# was to join to a channel a bot for every module in CPAN, and have them
# announce when new versions of themselves were released, etc, etc. I can't
# remember who had this insane idea, probably sky. Anyway, this is proof of
# concept code, and inspired the changes in the source that let you put >1
# BasicBot in a single POE session.

# The problem is that with more than 30 or 40 running bots, even on the same
# machine as the IRC server, the latencies get insane. You just can't keep
# them all alive enough to stay connected and not time-out. So the idea was
# a non-starter, because I'm not running a process on the server for every
# module on CPAN. But I can think of some cases where you'd want to run 2 or
# 3 bots in a single session, to bridge networks, say, that sort of thing,
# and so heere's how I'd do it...

# Probably, this does not work.

# The bot moudle itself.

package CPANBot;
use Bot::BasicBot;
use strict;
use warnings::register;
use base 'Bot::BasicBot';

sub create {
  my $class = shift;
  my $nick = shift;
  print STDERR "Creating $nick\n";
  my $self = bless Bot::BasicBot->new( nick => $nick,
                                   server => 'london.irc.perl.org',
                                   no_run => 1, # don't run the bot automatically
                                 ), $class;
  $self->{_delay} = shift || 1;
  return $self;
}

sub connected {
  my $self = shift;
  print STDERR $self->nick." connected\n";
  $self->join('#jerakeen');
  $self->say(channel => '#jerakeen', body => 'lo, I am '.$self->nick);
}

sub said {
  my $self = shift;
  my $mess = shift;
  print STDERR $self->nick." : ".$mess->{body}."\n";
  my $nick = $self->nick;
  if ($mess->{body} =~ /$nick/i) {
    $self->say(channel => $mess->{channel}, body => 'I 0wnz0r you');
  }
  if ($nick =~ /$mess->{body}/i) {
    $self->say(channel => $mess->{channel}, body => 'you 0wnz0r me');
  }
}




package main;
use POE;
use CPANPLUS::Backend;
use Data::Dumper;

my $cp = new CPANPLUS::Backend;
#$cp->reload_indices(update_source => 1);
my $modules = $cp->module_tree;
#print Dumper($modules);

my @names = keys(%$modules);
my @bots;

for (@names) {
  s/:+/_/g;
  s/\W//g;
#  next unless length($_) < 19;
  next unless /^Bot/;
  push @bots, $_;
  print STDERR "$_!\n";
}

my $bot = {};

my $i = 0;

for (@bots) {

  # this next line needs a code change to Bot::Basicbot - take the
  # $poe_kernel->run line out of the run method, we don't want the bots to
  # run themselves.

  $bot->{$_} = CPANBot->create($_, $i)->run;
  $i+= 11;
}

$poe_kernel->run();
