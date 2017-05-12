#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}

plan tests => 5;

use_ok('Config::Crontab');

my $ct;

## make some objects
my $com1 = new Config::Crontab::Comment( -data => "## Well! If microwaves don't" );
my $com2 = new Config::Crontab::Comment( -data => "## take the cake!" );
my $env1 = new Config::Crontab::Env( -data => 'MAILTO=joe@schmoe.org' );
my $event1 = new Config::Crontab::Event( -data => '30 4 * * Wed /bin/wednesday' );

## do tests by adding non-block objects to a crontab
$ct = new Config::Crontab;
is( $ct->last($com1, $com2, $env1, $event1), 0, "last entry" );
my $rv = <<'_CRONTAB_';
## Well! If microwaves don't
## take the cake!
MAILTO=joe@schmoe.org
30 4 * * Wed /bin/wednesday
_CRONTAB_
chomp $rv;  ## chomped because not a block
is( $ct->dump, '', "empty dump" );

## try some selects, deletes, etc.
is( $ct->select, 0, "select empty" );
ok( ! $ct->remove($com1), "remove empty" ); ## FIXME: Perl 5.6.1 says '0', Perl 5.00503 says ''; we use !
