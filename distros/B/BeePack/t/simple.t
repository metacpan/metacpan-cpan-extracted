#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use File::Temp qw/ tmpnam /;

use BeePack;

my $dbfile = defined $ENV{BEEPACK_GENERATE_SIMPLE_TESTDB}
  ? $ENV{BEEPACK_GENERATE_SIMPLE_TESTDB} : tmpnam();
my $tempfile = tmpnam();

{
  my $init_beepack = BeePack->open($dbfile,$tempfile);

  isa_ok($init_beepack,'BeePack','$init_beepack');

  $init_beepack->set_integer( integer => 23 );
  $init_beepack->set_bool( bool => 1 );
  $init_beepack->set_string( string => "This is a text" );
  $init_beepack->set_nil( 'nil' );
  $init_beepack->set( array => [qw( 1 2 3 )] );
  $init_beepack->set( hash => {qw( 1 a 2 b 3 c )} );

  $init_beepack->save;
}

{
  my $beepack_ro = BeePack->open($dbfile);

  isa_ok($beepack_ro,'BeePack','$beepack_ro');

  is($beepack_ro->get('integer'),23,'Reading integer');
  is($beepack_ro->get('bool') ? 1 : 0,1,'Reading bool');
  is($beepack_ro->get('string'),"This is a text",'Reading string');
  is($beepack_ro->get('nil'),undef,'Reading nil');
  is_deeply($beepack_ro->get('array'),[qw( 1 2 3 )],'Reading array');
  is_deeply($beepack_ro->get('hash'),{qw( 1 a 2 b 3 c )},'Reading hash');
  is($beepack_ro->exists('nil') ? 1 : 0,0,"nil value doesn't exists");

  eval {
    $beepack_ro->set( string => 'Readonly!' );
  };
  like($@, qr/Trying to set on readonly BeePack/, 'Setting on readonly produces error');
}

{
  my $beepack_rw = BeePack->open($dbfile,$tempfile);

  isa_ok($beepack_rw,'BeePack','$beepack_rw');

  $beepack_rw->set_integer( integer => 24 );
  $beepack_rw->set_bool( bool => 0 );
  $beepack_rw->set_string( string => "This is another text" );
  $beepack_rw->set( array => [qw( 4 5 6 )] );
  $beepack_rw->set( hash => {qw( 4 d 5 e 6 f )} );

  $beepack_rw->save;
}

{
  my $beepack_ro2 = BeePack->open($dbfile,undef, nil_exists => 1 );

  isa_ok($beepack_ro2,'BeePack','$beepack_ro2');

  is($beepack_ro2->exists('nil') ? 1 : 0,1,"nil value does exists with nil_exists = 1");
  is($beepack_ro2->get('integer'),24,'Reading changed integer');
  is($beepack_ro2->get('bool') ? 1 : 0,0,'Reading changed bool');
  is($beepack_ro2->get('string'),"This is another text",'Reading changed string');
  is_deeply($beepack_ro2->get('array'),[qw( 4 5 6 )],'Reading changed array');
  is_deeply($beepack_ro2->get('hash'),{qw( 4 d 5 e 6 f )},'Reading changed hash');
}

done_testing;
