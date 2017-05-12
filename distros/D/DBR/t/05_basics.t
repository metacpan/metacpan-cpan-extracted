#!/usr/bin/perl

use strict;
use warnings;
no warnings 'uninitialized';

$| = 1;

use lib './lib';
use t::lib::Test;
use Test::More tests => 43;

# As always, it's important that the sample database is not tampered with, otherwise our tests will fail
my $dbr = setup_schema_ok('music');

my $dbh = $dbr->connect('music');
ok($dbh, 'dbr connect');

my $count;
my $rv;

############### COUNT #################

# v1 count
$count = $dbh->select( -count => 1, -table => 'artist' );
ok(defined($count), 'v1 -count defined');
ok($count == 2,     "v1 -count matches ($count)");

$count = $dbh->select( -count => 1, -table => 'track', -where => { album_id => ['d',1] } );
ok(defined($count), 'v1 -count defined');
ok($count == 3,     "v1 -count matches ($count)");

$count = $dbh->select( -count => 1, -table => 'track', -where => { album_id => ['d',999] } ); # Intentional - There is no album 999
ok(defined($count), 'v1 -count defined');
ok($count == 0,     "v1 -count matches ($count)");


# v2 count
my $allartists = $dbh->artist->all;
ok($allartists, 'v2 all artists resultset');

$count = $allartists->count; # Count without any retrieval, so we force it to issue a sidecar query
ok(defined($count), 'v2 all artists resultset count defined');
ok($count == 2,     "v2 count matches ($count)");
$count = $allartists->count;
ok($count == 2,     "v2 count re-run matches ($count)");

my $allartistsB = $dbh->artist->all;
ok($allartistsB, 'v2 all artists resultset(B)');

my @artist_ids = $allartistsB->values('artist_id'); # Perform a retrieval, so we force it to do the full select
ok(@artist_ids == 2, 'v2 all artists values count matches');

$count = $allartists->count;
ok(defined($count), 'v2 all artists resultset count defined');
ok($count == 2,     "v2 count matches ($count)");


####### SELECT / DELETE / SELECT ######

# v1 select / delete / select
my $tracks = $dbh->select( -table => 'track', -fields => 'track_id album_id name', -where => { album_id => ['d',2] } );
ok(ref($tracks) eq 'ARRAY', 'v1 select');
ok(@$tracks == 3,     "v1 correct number of rows");

$rv = $dbh->delete( -table => 'track', -where => { album_id => ['d',2], name => 'Track BA3' } );
ok(defined($rv), 'v1 delete defined');
ok($rv, 'v1 delete');

$tracks = $dbh->select( -table => 'track', -fields => 'track_id album_id name', -where => { album_id => ['d',2] } );
ok(ref($tracks) eq 'ARRAY', 'v1 select');
ok(@$tracks == 2,     "v1 correct number of rows");


# v2 select/delete/select
my $tracksB = $dbh->track->where( album_id => 2 );
ok($tracksB, 'v2 select');
ok($tracksB->count == 2, "v2 correct number of rows");

# v2 select/delete/select
$rv = $dbh->track->where( album_id => 2, name => 'Track BA2' )->next->delete;
ok(defined($rv), 'v2 delete defined');
ok($rv, 'v2 delete');

$tracksB = $dbh->track->where( album_id => 2 );
ok($tracksB, 'v2 select');
ok($tracksB->count == 1, "v2 correct number of rows");


######## INSERT ########

# v1 insert
$rv = $dbh->insert( -table => 'track', -fields => { album_id => ['d',2] , name => 'Track BA5' } );
ok($rv, 'v1 insert');

# v2 insert
$rv = $dbh->track->insert( album_id => 2, name => 'Track BA6' );
ok($rv, 'v2 insert');

# No point in testing v1 bogus insert... it doesn't know anything about the table

# v2 - bogus inserts
eval{ $dbh->track->insert( name => 'Track XXX' ) };                     # album_id defined as NOT NULL
ok($@ =~ /Missing field/i, 'v2 insert w/o required field throws exeption');

eval { $dbh->track->insert( album_id => 2, name => undef ) };           # name is defined as NOT NULL
ok($@ =~ /invalid value/i, 'v2 insert w/ disallowed undef throws exeption');

eval { $dbh->track->insert( album_id => 2, name => 'Monkeywrench!' ) }; # name has a regex of ^[A-Za-z0-9 ]+$
ok($@ =~ /invalid value/i, 'v2 insert w/ disallowed character throws exeption');


########## ->parse ###########
ok(  $dbh->album->parse('rating' => 'sucks'    ), 'parse an enum field'                  );
ok( !$dbh->album->parse('rating' => 'quixotic' ), 'parse an enum field w/ illegal value' );

ok(  $dbh->artist->parse('royalty_rate' => '1%'  ), 'parse a percent field'                  );
ok( !$dbh->artist->parse('royalty_rate' => 'meh' ), 'parse a percent field w/ illegal value' );

ok(  $dbh->track->parse('name' => 'Totally ok' ), 'parse a regular field'                     );
ok( !$dbh->track->parse('name' => 'Not! ok'    ), 'parse a regular field w/ illegal value'    );

ok(  $dbh->track->parse('album_id' => 123         ), 'parse a regular numeric field'                     );
ok( !$dbh->track->parse('album_id' => undef       ), 'parse a regular numeric field w/ illegal value'    );
ok( !$dbh->track->parse('album_id' => ''          ), 'parse a regular numeric field w/ illegal value B'    );
ok( !$dbh->track->parse('album_id' => 'whybother' ), 'parse a regular numeric field w/ illegal value C'    );
