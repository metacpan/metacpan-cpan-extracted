#!/usr/bin/perl -w
use v5.14;
use warnings;
no warnings 'redefine';

use Test::More tests => 11;
BEGIN { use_ok('App::Devbot') };

use POE;

sub call_poe{
  my ($func, @args)=@_;
  my @arglist;
  $arglist[ARG0 + $_]=$args[$_] for 0 .. $#args;
  $func->(@arglist)
}

sub set_test{
  my ($expected, $testname) = @_;
  *App::Devbot::log_event = sub { shift; is "@_", $expected, $testname };
}

*App::Devbot::mode_char = sub { ' ' };

set_test '< nick> Hello, world!', 'public';
call_poe \&App::Devbot::on_public, 'nick!user@host', ['#channel'], 'Hello, world!';

set_test '* nick nicked', 'action';
call_poe \&App::Devbot::on_ctcp_action, 'nick!user@host', ['#channel'], 'nicked';

set_test '-!- nick [user@host] has joined #channel', 'join';
call_poe \&App::Devbot::on_join, 'nick!user@host', '#channel';

set_test '-!- nick [user@host] has left #channel [Leaving!]', 'part';
call_poe \&App::Devbot::on_part, 'nick!user@host', '#channel', 'Leaving!';

set_test '-!- idiot was kicked from #channel by nick [no reason]', 'kick';
call_poe \&App::Devbot::on_kick, 'nick!user@host', '#channel', 'idiot', 'no reason';

set_test '-!- mode/#channel [+oo mgv mgvx] by ChanServ', 'mode';
call_poe \&App::Devbot::on_mode, 'ChanServ!user@host', '#channel', '+oo', 'mgv', 'mgvx';

set_test '-!- nick changed the topic of #channel to: Go away!', 'topic set';
call_poe \&App::Devbot::on_topic, 'nick!user@host',  '#channel', 'Go away!';

set_test '-!- Topic unset by nick on #channel', 'topic unset';
call_poe \&App::Devbot::on_topic, 'nick!user@host', '#channel', '';

set_test '-!- nick is now known as newnick', 'nick';
call_poe \&App::Devbot::on_nick, 'nick!user@host', 'newnick', ['#channel'];

set_test '-!- nick [user@host] has quit [Quitting]', 'quit';
call_poe \&App::Devbot::on_quit, 'nick!user@host', 'Quitting', ['#channel'];
