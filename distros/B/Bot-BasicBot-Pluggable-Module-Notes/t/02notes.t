#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use Test::DatabaseRow;

use Test::Bot::BasicBot::Pluggable;

my $TESTDB = 't/brane.db';
use_ok( "Bot::BasicBot::Pluggable::Module::Notes" );

# What the what?  Putting this *inside* the for loop makes say_output be empty,
# which implies that say() hasn't been overridden.
my @say_output = ();
sub Test::Bot::BasicBot::Pluggable::say {
    my ($self, %args) = @_;
    push @say_output, \%args;
}

for my $store_name (qw<SQLite DBIC>) {
    unlink $TESTDB;

    use_ok( "Bot::BasicBot::Pluggable::Module::Notes::Store::$store_name" );

    my $bot = Test::Bot::BasicBot::Pluggable->new( channels => [ "#test" ],
                                                   server   => "irc.example.com",
                                                   port     => "6667",
                                                   nick     => "bot",
                                                   username => "bot",
                                                   name     => "bot",
        );

###
###

    my $notes_handler = $bot->load( "Notes" );

# my $notes_handler = $bot->handler( "Notes" );

## Test command parsing:

    my $simple_command = $notes_handler->parse_command('!nb');
    is_deeply($simple_command, { command => 'nb',  method => 'store_note', args => ''}, 'Parsed simple command !nb');

    my $two_word_command = $notes_handler->parse_command('!{my notes}');
    is_deeply($two_word_command, { command => 'mn',method => 'replay_notes',  args => ''}, 'Parsed two word command !{my notes}');

    my $command_with_args = $notes_handler->parse_command('!search #todo');
    is_deeply($command_with_args, { command => 'search', method => 'search', args => '#todo' }, 'Parsed command with args !search #todo');
    
## store
    eval {
        local $SIG{__WARN__} = { }; # we expect DBI to warn
        $notes_handler->set_store(
            "Bot::BasicBot::Pluggable::Module::Notes::Store::$store_name"
            ->new( "thisdoesnotexist/brane.db" )
            );
    };
    ok( $@, "set_store croaks when database file can't be created" );

    eval {
        $notes_handler->set_store(
            "Bot::BasicBot::Pluggable::Module::Notes::Store::$store_name"
            ->new( $TESTDB )
            );
    };
    is( $@, "", "...but is fine when it can" );

    my $store = "Bot::BasicBot::Pluggable::Module::Notes::Store::$store_name"
        ->new( "t/brane.db" );
    my $dbh = $store->dbh;
    $Test::DatabaseRow::dbh = $dbh;

## test handler storage
    $notes_handler->store_note(who => 'me', channel => '#metest', content => 'something');

    row_ok( table => "notes",
            where => [ channel => '#metest', notes => 'something', name => 'me' ],
            label => "Finds directly stored data'" );
    # fetch the direct stored one so we know the timestamp.. 

    $store->store(
        timestamp => '2010-01-01 23:23:23',
        name => 'directstore',
        channel => '#stored',
        notes => 'stored directly',
        );


    # FIXME: replay_notes should say so when nothing is found.
    # FIXME: allow searching by channel.

    @say_output = ();
    $notes_handler->replay_notes(who => 'directstore');
    is_deeply(\@say_output, [{
        who => 'directstore', channel => 'msg',
        body => "[#stored] (2010-01-01 23:23:23) stored directly\n"
              }], "Said stored note, store=$store_name");

    if ($store_name ne 'SQLite') {
## test handler storage, with tags
        $notes_handler->store_note(who => 'me2', channel => '#metest2', content => 'something #test #BOOBIES');
        
        row_ok( table => "notes",
                where => [ channel => '#metest2', notes => 'something #test #BOOBIES', name => 'me2' ],
                label => "Finds directly stored data, with tags" );
        
        row_ok( table => 'tags',
                where => [ tag => 'test' ],
                label => 'directly stored data, tag test'
        );
        row_ok( table => 'tags',
                where => [tag => 'boobies'],
                label => 'directly stored data, tag boobies'
            );

        # test search with tags
        @say_output = ();
        $notes_handler->search(content => '#test');
        is(scalar @say_output, 1, 'Returned one result in search for tag #test');
        like($say_output[0]{body}, qr/\[#metest2\] \((?:[^)]+)\) something #test #BOOBIES/, 'Matched search ourput for tag #test');

        ## now look for both tags, should return only one note:
        @say_output = ();
        $notes_handler->search(content => '#test #boobies');
        is(scalar @say_output, 1, 'Returned one result in search for tag #test and #boobies');
        like($say_output[0]{body}, qr/\[#metest2\] \((?:[^)]+)\) something #test #BOOBIES/, 'Matched search ourput for tag #test');


    }
    
## test via bot
    $bot->tell_direct('TODO: Better document bot');

    row_ok( table => "notes",
            where => [ channel => '#test', notes => 'TODO: Better document bot', name => 'test_user' ],
            results => 0,
            label => "Doesn't store note if doesnt begin with 'note to self'" );

    $bot->tell_direct('!{note to self} TODO: Better document bot');

    row_ok( table => "notes",
            where => [ channel => '#test', notes => 'TODO: Better document bot', name => 'test_user' ],
            label => "stores note to self" );

    @say_output = ();
    $bot->tell_direct('!nb #BooBies appear on the side of a church in SF at two o\'clock');
    is_deeply(\@say_output, [
                  {
                      body => 'Stored your note.',
                      who => 'test_user',
                      channel => 'msg'
                  }
              ]);
    

    if ($store_name eq 'DBIC') {
        @say_output = ();
        $bot->tell_direct('!search #bOObies');
        
        is(@say_output, 2, 'Found 2 #boobies tagged notes');
        
        like($say_output[0]{body}, 
             qr/^\[#metest2\] \(\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\) something #test #BOOBIES\n$/, 'Search result matches');
        like($say_output[1]{body}, 
             qr/^\[#test\] \(\d{4}-\d{2}-\d{2} \d\d:\d\d:\d\d\) #BooBies appear on the side of a church in SF at two o'clock\n$/, 'Search result matches');

        @say_output = ();
        $bot->tell_direct('!search #dicks');
        is_deeply(\@say_output, [
                      {
                          body => 'Return to sender.  Address unknown.  No such number.  No such zone.',
                          who => 'test_user',
                          channel => 'msg'
                      }
                  ]);
    } else {
        diag('skipping search tests under SQLite');
    }
}

done_testing;

