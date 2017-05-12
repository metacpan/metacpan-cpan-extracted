#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 6;
use FindBin qw( $Bin );

use Bot::BasicBot::Pluggable;

my $store = Bot::BasicBot::Pluggable::Store->new();

my $bot = Bot::BasicBot::Pluggable->new(
  channels => [ '#botzone' ],
  nick     => 'TestBot',
  store    => $store
);

print "$Bin\n";


ok(my $module = $bot->load('Eliza'),'loading module via load()');

$module->set('user_scriptfile',"$Bin/testscript1.txt");
is(say("test"),'test1');

$module->set('user_scriptfile',"$Bin/testscript2.txt");
is(say("test"),'test2');

$module->set('user_scriptfile',"$Bin/testscript1.txt");
is(say("test"),'test1');

$module->unset('user_scriptfile');
unlike(say("test"),qr/^test[0-9]/);

is($module->help(),'Implements the classic Eliza algorithm.');

sub say {
	my $message = shift;
	$module->fallback({ body => $message, address => 1});
}
	

1;
