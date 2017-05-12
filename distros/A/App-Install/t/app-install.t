#!perl -T

use Test::More  tests => 8;
use lib 'lib';

BEGIN {
    use_ok( 'App::Install' );
}

can_ok('App::Install', 'files');
App::Install->files(foo => "bar");
is_deeply(\%App::Install::files, {foo => "bar"}, "... and can set files");

can_ok('App::Install', 'permissions');
App::Install->permissions(foo => 0755);
is_deeply(\%App::Install::permissions, {foo => 0755}, "... and can set permissions");

can_ok('App::Install', 'delimiters');
App::Install->delimiters(1, 2);
is_deeply(\@App::Install::delimiters, [1,2], "... and can set delimiters");

can_ok('App::Install', 'install');
