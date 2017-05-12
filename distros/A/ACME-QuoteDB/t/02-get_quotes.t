#!perl -T

use strict;
use warnings;

use ACME::QuoteDB;
use ACME::QuoteDB::LoadDB;

#use Test::More 'no_plan';
use Test::More tests => 33;
use File::Basename qw/dirname/;
use Data::Dumper qw/Dumper/;
use Carp qw/croak/;
use File::Spec;


BEGIN {
    eval "use DBD::SQLite";
    $@ and croak 'DBD::SQLite is a required dependancy';
}

#make test db writeable
sub make_test_db_rw {
     use ACME::QuoteDB::DB::DBI;
     # yeah, this is supposed to be covered by the build process
     # but is failing sometimes,...
     chmod 0666, ACME::QuoteDB::DB::DBI->get_current_db_path;
}

{
    make_test_db_rw;

    my $q = File::Spec->catfile((dirname(__FILE__),'data'), 'simpsons_quotes.csv');
    my $load_db = ACME::QuoteDB::LoadDB->new({
                                file        => $q,
                                file_format => 'csv',
                                create_db   => 1, # first run, create the db
                            });

    isa_ok $load_db, 'ACME::QuoteDB::LoadDB';
    $load_db->data_to_db;
    is $load_db->success, 1;
}

my $sq = ACME::QuoteDB->new;

# some 'the simpsons' characters
my @expected_attr_name_list = (
         'Apu Nahasapemapetilon',
         'Chief Wiggum',
         'Comic Book Guy',
         'Grandpa Simpson',
         'Ralph Wiggum',
        );
is( $sq->list_attr_names, join "\n", sort @expected_attr_name_list);

#warn $sq->get_quote, "\n";
ok $sq->get_quote; # default get random quote
ok $sq->get_quote =~ m{\w+};

{
    my $res = $sq->get_quote({AttrName => 'apu'});
    if ($res =~ m/apu/xmsgi) {
        pass 'ok';
    } 
    else {
        fail 'a supposed apu quote, should contain "Apu" within,...';
    }
}

{
    my $res = $sq->get_quote({AttrName => 'chief wiggum'});
    if ($res =~ m/(chief|clancy|wiggum|police|gun|donut)/xmsgi) {
        pass 'ok';
    } 
    else {
        fail 'a supposed chief wiggum quote, 
               should contain "chief wiggum" within,...';
    }
}

{
    my $res = $sq->get_quote({AttrName => 'wiggum'});
    if ($res =~ m/(ralph|chief|wiggum)/xmsgi) {
        pass 'ok';
    } 
    else {
        fail 'a supposed wiggum quote, should 
              contain "ralph or chief" within,...';
    }
}

{
    my $q= 'I hope this has taught you kids a lesson: ' .
                     qq{kids never learn.\n-- Chief Wiggum};
    my $res = $sq->get_quote({AttrName => 'Chief Wiggum', Rating => '9.0'});
    if ($res && $res eq $q) {
        pass 'ok';
    } 
    else {
        fail 'quote should be found';
    }
}

eval { # param mispelled
    $sq->get_quote({Charcter => 'bart'});
};
if ($@) {
    pass if $@ =~ m/unsupported argument option passed/;
} else {fail 'should alert user on non existant params' };


eval {
    $sq->get_quote({Limit => '4'}); # only avail for 'get_quotes'
};
if ($@) {
    pass if $@ =~ m/unsupported argument option passed/;
} else {fail 'should alert user on non existant params' };


eval {
    $sq->get_quote({Contain => '4'}); # only avail for 'get_quotes_contain'
};
if ($@) {
    pass if $@ =~ m/unsupported argument option passed/;
} else {fail 'should alert user on non existant params' };


# any unique part of name should work
# i.e these should all return the same results
is scalar @{$sq->get_quotes({AttrName => 'comic book guy'})}, 8;
is scalar @{$sq->get_quotes({AttrName => 'comic book'})}, 8;
is scalar @{$sq->get_quotes({AttrName => 'comic'})}, 8;
is scalar @{$sq->get_quotes({AttrName => 'book'})}, 8;
is scalar @{$sq->get_quotes({AttrName => 'book guy'})}, 8;
is scalar @{$sq->get_quotes({AttrName => 'guy'})}, 8;

eval {
    $sq->get_quotes({AttrName => 'your momma'});
};
if ($@) {
    pass 'ok' if $@ =~ m/attribution not found/;
    pass 'ok'; #'dont talk about my momma on the simpsons';
} else {fail 'attribution should not be found' };

eval {
    $sq->get_quotes({AttrName => 'chewbaccas momma'});
};
if ($@) {
    pass 'ok' if $@ =~ m/attribution not found/;
    pass 'ok'; #'now your really asking for trouble'; 
} else {fail 'attribution should not be found' };


eval { # param mispelled
    $sq->get_quotes({Charcter => 'bart'});
};
if ($@) {
    pass if $@ =~ m/unsupported argument option passed/;
} else {fail 'should alert user on non existant params' };


#sqlite> select COUNT(*) from quote where attribution_id IN (29,5);
#61 # get all family name wiggum quotes (ralph and clancy)
is scalar @{$sq->get_quotes({AttrName => 'wiggum', Rating => '2-10'})}, 15;

# get 6 random quotes
is scalar @{$sq->get_quotes({Limit => 6})}, 6;

is scalar @{$sq->get_quotes({
                           Limit  => 2,
                           Rating => '9-10'
                           })}, 2; # get 2 very funny random quotes

is scalar @{$sq->get_quotes({
                           AttrName => '  wiggum   ',
                           Rating    => ' 4 - 7 ', # opps, 'spacing' out,...
                           Limit     => 2
                           })}, 2; # get 2 not so funny wiggum quotes

ok $sq->get_quotes({
                     AttrName => 'comic',
                     Rating => '7'
                   })->[0] =~ m/Highlander/;

ok $sq->get_quotes({
                     AttrName => 'comic',
                     Rating => '7.0'
                   })->[0] =~ m/Highlander/;


my $gs = "Big deal! When I was a pup, we got spanked by presidents " .
         "'til the cows came home! Grover Cleveland spanked me on " .
         "two non-consecutive occasions!\n-- Grandpa Simpson";
is $sq->get_quotes_contain({
                  Contain =>  'til the cow'
})->[0], $gs;


is $sq->get_quotes_contain({
                  Contain =>  'til the cow',
                  Rating  => '1-5',
                  Limit   => 2
})->[0], undef;


eval {
    $sq->get_quotes_contain({
                      Contain =>  'til the cow',
                      Rating  => '-7',
                      Limit   => 2
    })};
if ($@) {
    pass if $@ =~ m/negative range not permitted/;
} else {fail 'should alert user on incorrect rating input' };


is $sq->get_quotes_contain({
                  Contain   => 'wookie',
                  AttrName => 'ralph',
                  Limit     => 1
})->[0], qq{I bent my wookie.\n-- Ralph Wiggum};



