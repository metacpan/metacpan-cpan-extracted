#!/usr/bin/perl -w

use strict;
use warnings;

use Test::Most;

plan qw/no_plan/;

use App::PM::Announce;
use Directory::Scratch;

my $scratch = Directory::Scratch->new;

$ENV{APP_PM_ANNOUNCE_HOME} = $scratch->base;

my $app = App::PM::Announce->new;
my $history = $app->history;
my $uuid = 'not-really-a-uuid';
my $result;

ok($history);

$history->insert( $uuid => xyzzy => 1 );

$result = $history->fetch( $uuid );
ok($result->{insert_datetime});
is($result->{data}->{xyzzy}, 1);
is($result->{data}->{did_meetup}, undef);

$history->update( $uuid => did_meetup => 1 );

$result = $history->fetch( $uuid );
is($result->{data}->{xyzzy}, 1);
is($result->{data}->{did_meetup}, 1);

$result = $history->find_or_insert( $uuid );
is($result->{data}->{xyzzy}, 1);
is($result->{data}->{did_meetup}, 1);

#$history->update( $uuid => did_linkedin => 2 );

#$result = $history->fetch( $uuid );
#is($result->{data}->{xyzzy}, 1);
#is($result->{data}->{did_meetup}, 1);
