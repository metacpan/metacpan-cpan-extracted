#!/usr/bin/perl

use strict;
use warnings;

use Bot::BasicBot::Pluggable;
use Bot::BasicBot::Pluggable::Module::Notes;
use Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC;

my $network = shift || 'irc.perl.org';
my $channel = shift || '#northwestengland.pm';


my $bot = Bot::BasicBot::Pluggable->new(  
    channels => [ $channel ],
    server   => $network, # "irc.perl.org",
    port     => "6667",
    
    nick     => "notesbot",
    altnicks => ["notesbot"],
    username => "notesbot",
    name     => "Bot::BasicBot::Pluggable::Module::Notes",
    
#    ignore_list => [qw(hitherto blech muttley)],

    );
my $notes_module = $bot->load( "Notes" );

$notes_module->set_store(
    Bot::BasicBot::Pluggable::Module::Notes::Store::DBIC
    ->new( "/home/castaway/public_html/notesbot/brane.db" )
    );

$notes_module->set_notesurl( "http://desert-island.me.uk/cgi-bin/notesapp.cgi/" );

$bot->run();
