#! perl

use strict;
use warnings;

use Test::More tests => 2;

use CPAN::Upload::Tiny;
use File::Temp 'tempfile';

my ($filehandle, $filename) = tempfile(TMPDIR => 1);
print $filehandle "user FOO\npassword BAR\n";
close $filehandle;

my ($user, $password) = CPAN::Upload::Tiny::read_config_file($filename);
is($user, 'FOO', 'Username is FOO');
is($password, 'BAR', 'Password is BAR');

