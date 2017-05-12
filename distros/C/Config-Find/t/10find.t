#!/usr/bin/perl -w
use strict;

use Config::Find;
use File::Path;
use Test::More tests => 9;

$ENV{HOME} = 't/data';
if ($^O eq 'MSWin32') {
  no warnings qw(redefine once);
  *Config::Find::WinAny::app_user_dir = sub {
     return 't/data';
  }
}
my $test1_name = $^O eq 'MSWin32' ? 't\\data\\test1.cfg' : 't/data/.test1';
my $test2_name = $^O eq 'MSWin32' ? 't\\data\\test2.cfg' : 't/data/.test2';
my $test3_name = $^O eq 'MSWin32' ? 't\\data\\test3.cfg' : 't/data/.test3';

my $fn = Config::Find->find( name => 'test1' );
is($fn,$test1_name) or do {
  $fn = Config::Find->find( names => ['test1'], mode => 'write', scope => 'global' );
  diag ("was searching for $fn");
};
$fn = Config::Find->find( names => ['test2','test1'] );
is($fn,$test2_name);

eval { $fn = Config::Find->find( names => ['does','not','exist'] ) };
is($fn,undef);

eval { $fn = Config::Find->find( names => 'string' ) };
like($@,qr/expecting an array ref/);
eval { $fn = Config::Find->find( names => ['string'], mode => 'append' ) };
like($@,qr/invalid option mode/);
eval { $fn = Config::Find->find( names => ['string'], scope => 'peri' ) };
like($@,qr/invalid option scope/);

eval { $fn = Config::Find->find( names => ['test1','test2'], mode => 'read' ) };
is($fn,$test1_name);
eval { $fn = Config::Find->find( names => ['test3'], mode => 'write' ) };
is($fn,$test3_name);

mkdir('conf');
eval { $fn = Config::Find->find( names => ['test3'], mode => 'write', scope => 'global' ) };
like($fn,($^O eq 'MSWin32' ? qr!t\\test3\.cfg$! : qr!/conf/test3\.conf$!));
rmdir('conf');
