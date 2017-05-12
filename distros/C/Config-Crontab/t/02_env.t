#-*- mode: cperl -*-#
use Test::More;
use blib;

chdir 't' if -d 't';
require './setup.pl';

unless( have_crontab() ) {
    plan skip_all => "no crontab available";
    exit;
}
plan tests => 53;

use_ok('Config::Crontab');

## FIXME: add some space tests (as per crontab(5))

my $env;

$env = new Config::Crontab::Env;
is( $env->dump, '', "empty env" );
undef $env;

$env = new Config::Crontab::Env( -name  => 'MAILTO',
                                 -value => 'scott@perlcode.org' );
is( $env->dump, 'MAILTO=scott@perlcode.org' );
undef $env;

$env = new Config::Crontab::Env( -value => 'scott@perlcode.org' );
is( $env->dump, '' );
is( $env->name('MAILTO'), 'MAILTO' );
is( $env->dump, 'MAILTO=scott@perlcode.org' );
undef $env;

$env = new Config::Crontab::Env( -name => 'MAILTO' );
is( $env->dump, 'MAILTO=' );
is( $env->value('joe@schmoe.org'), 'joe@schmoe.org' );
is( $env->dump, 'MAILTO=joe@schmoe.org' );
undef $env;

$env = new Config::Crontab::Env;
is( $env->dump, '' );
is( $env->name('MAILTO'), 'MAILTO' );
is( $env->dump, 'MAILTO=' );
is( $env->value('foo@bar.baz'), 'foo@bar.baz' );
is( $env->dump, 'MAILTO=foo@bar.baz');
is( $env->value(undef), '' );
is( $env->dump, 'MAILTO=' );
is( $env->value('bar@baz.blech'), 'bar@baz.blech');
is( $env->dump, 'MAILTO=bar@baz.blech');
is( $env->name(undef), '' );
is( $env->dump, '' );
undef $env;

## test some quoting issues
$env = new Config::Crontab::Env( -name   => 'MAILTO',
                                 -value  => 'joe@schmoe.org', );
is( $env->dump, 'MAILTO=joe@schmoe.org' );
is( $env->value(q!"Scott Wiersdorf" <scott@perlcode.org>!), '"Scott Wiersdorf" <scott@perlcode.org>' );
is( $env->dump, 'MAILTO="Scott Wiersdorf" <scott@perlcode.org>' );
undef $env;

## test the 'active' method/attribute
$env = new Config::Crontab::Env( -name   => 'MAILTO',
                                 -value  => 'joe@schmoe.org',
                                 -active => 0 );
is( $env->dump, '#MAILTO=joe@schmoe.org' );
ok( $env->active(1) );
is( $env->dump, 'MAILTO=joe@schmoe.org' );
undef $env;

$env = new Config::Crontab::Env;
is( $env->dump, '' );
is( $env->name('MAILTO'), 'MAILTO' );
is( $env->value('foo@bar.org'), 'foo@bar.org' );
is( $env->dump, 'MAILTO=foo@bar.org' );
is( $env->active(0), 0 );
is( $env->dump, '#MAILTO=foo@bar.org' );
is( $env->value(undef), '' );
is( $env->dump, '#MAILTO=' );
ok( $env->active(1) );
is( $env->dump, 'MAILTO=' );
undef $env;

## test the parse constructor
$env = new Config::Crontab::Env(-data => 'MAILTO=joe@schmoe.org');
is( $env->dump, 'MAILTO=joe@schmoe.org' );
ok( $env->active );
is( $env->name, 'MAILTO' );
is( $env->value, 'joe@schmoe.org' );
undef $env;

## -active is ignored because of -data
$env = new Config::Crontab::Env( -active => 0,
                                 -data   => 'MAILTO=foo@bar.com');
is( $env->dump, 'MAILTO=foo@bar.com' );
undef $env;

$env = new Config::Crontab::Env( -data => 'MAILTO=' );
is( $env->dump, 'MAILTO=' );
undef $env;

## garbage in constructor should return undef
ok( ! defined($env = new Config::Crontab::Env( -data => 'garbage' )) );
undef $env;

## newline in constructor
$env = new Config::Crontab::Env( -data => "MAILTO=foo\@bar.com\n" );
is( $env->data, 'MAILTO=foo@bar.com' );
is( $env->value, 'foo@bar.com' );
undef $env;

## newline in data
$env = new Config::Crontab::Env;
is( $env->data("MAILTO=foo\@bar.com\n"), 'MAILTO=foo@bar.com' );
is( $env->value, 'foo@bar.com' );
is( $env->dump, 'MAILTO=foo@bar.com' );
undef $env;

## use the data method
$env = new Config::Crontab::Env;
is( $env->dump, '' );
is( $env->data( 'MAILTO = joe@schmoe.org' ), 'MAILTO=joe@schmoe.org' );
is( $env->name, 'MAILTO' );
is( $env->value, 'joe@schmoe.org' );
is( $env->dump, 'MAILTO=joe@schmoe.org' );
undef $env;
