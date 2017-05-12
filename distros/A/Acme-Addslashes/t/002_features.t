use Test::More tests => 4;

use v5.12;
use strict;
use warnings;
use utf8;
use feature qw(unicode_strings);

use Acme::Addslashes qw(addslashes);
use Encode qw(decode);

ok(decode("utf8", addslashes q{Moose}) eq q{M̸o̸o̸s̸e̸}, 'Latin text slashed up');

ok(decode("utf8", addslashes qq{☃}) eq qq{☃̸}, 'Slashed up snowman');

ok(decode("utf8", addslashes qq{\x{1F4A9}}) eq qq{\x{1F4A9}\x{338}}, 'Slashed up Pile of Poo');

ok(decode("utf8", addslashes q{Robert'); DROP TABLE Students;--}) eq q{R̸o̸b̸e̸r̸t̸'̸)̸;̸ ̸D̸R̸O̸P̸ ̸T̸A̸B̸L̸E̸ ̸S̸t̸u̸d̸e̸n̸t̸s̸;̸-̸-̸}, 'Slashed up little Bobby Tables');
