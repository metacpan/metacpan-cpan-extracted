#!/usr/bin/env perl
use strict;
use warnings;
use 5.010;

use Test::More tests => 14;

$ENV{XDG_CONFIG_HOME} = 't/config';
$ENV{XDG_DATA_HOME}   = 't/data';

use_ok('App::Raps2');

my $r2 = App::Raps2->new(
	master_password => 'sekrit',
	no_cli          => 1,
	pwgen_cmd       => 'echo 123 456',
);
isa_ok( $r2, 'App::Raps2' );

ok( -e 't/config/raps2/password', 'config file created' );

is_deeply(
	$r2->file_to_hash('t/in/hash'),
	{
		key      => 'value',
		otherkey => 'othervalue'
	},
	'file_to_hash works',
);

is( $r2->ui, undef, 'no_cli works (no UI object created)' );

$r2->pw_save(
	password => 'foopass',
	name     => 'test1'
  ),

  ok( -e 't/data/raps2/test1', 'Save password test1' );

is( $r2->pw_load( name => 'test1' )->{password},
	'foopass', 'Password for test1 loaded ok' );

$r2->pw_save(
	password => 'foopass',
	file     => 't/data/raps2/test2',
	url      => 'murl',
	login    => 'mlogin',
	extra    => 'mextra',
  ),

  is( $r2->pw_load_info( file => 't/data/raps2/test2' )->{url},
	'murl', 'Password info loaded ok (url)' );

is( $r2->pw_load_info( file => 't/data/raps2/test2' )->{login},
	'mlogin', 'Password info loaded ok (login)' );

is( $r2->pw_load( file => 't/data/raps2/test2' )->{password},
	'foopass', 'Password for test2 loaded ok' );

is( $r2->pw_load( file => 't/data/raps2/test2' )->{extra},
	'mextra', 'Extra for test2 loaded ok' );

is( $r2->generate_password(), '123', 'generate_password + pwgen_cmd ok' );

is( $r2->conf('pwgen_cmd'), 'echo 123 456', 'conf->pwgen_cmd ok' );
is( $r2->conf('xclip_cmd'), 'xclip -l 1', 'conf->xclip_cmd ok' );

unlink('t/data/raps2/test1');
unlink('t/data/raps2/test2');
unlink('t/config/raps2/password');
unlink('t/config/raps2/defaults');
