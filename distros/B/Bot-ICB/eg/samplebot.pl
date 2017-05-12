#!/usr/bin/perl -w
# -*- Mode: Perl; indent-tabs-mode: nil -*-

use strict;
use Bot::ICB ();

$|++;

my $on_connect = sub
  {
    my $bot = shift;
    $bot->sendpriv("hoople", "hi!");
    $bot->sendcmd("g", "unga");
  };

my $on_public = sub
  {
    my $bot = shift;
    my $nick = shift;
    my @msg = shift;
    print STDERR "<$nick> @msg\n";
  };

my $on_msg = sub
  {
    my $bot = shift;
    my $nick = shift;
    my @msg = shift;

    ($bot->sendopen("later") && $bot->disconnect) if $nick eq 'hoople';

    print STDERR "<*$nick*> @msg\n";
  };

my $on_status = sub
  {
    my $bot = shift;
    my $info = shift;
    my @msg = @_;
    print STDERR "[info] $info: @msg\n";
  };

my $bot = Bot::ICB->newconn;
$bot->debug(1);

$bot->add_handler('connect', $on_connect);
$bot->add_handler('name', $on_status);
$bot->add_handler('sign-off', $on_status);
$bot->add_handler('arrive', $on_status);
$bot->add_handler('depart', $on_status);
$bot->add_handler('topic', $on_status);
$bot->add_handler('boot', $on_status);
$bot->add_handler('public', $on_public);
$bot->add_handler('msg', $on_msg);
$bot->add_handler('status', $on_status);

$bot->login(user => 'dum', group => '$!');
$bot->start;

exit;
