use strict;
use warnings;

use Test::More tests => 3+4+1;
use Code::DRY;
#########################
can_ok('Code::DRY', 'set_default_reporter');
can_ok('Code::DRY', 'set_reporter');
can_ok('Code::DRY', 'scan_directories');

is(ref Code::DRY::set_default_reporter(), 'CODE', "set_default_reporter sets default");
is(ref [Code::DRY::set_reporter(Code::DRY::set_default_reporter())]->[0], 'CODE', "set_reporter sets given value (default)");

is(Code::DRY::find_duplicates_in(2, undef, undef), '', "duplicates for undef succeeds");
is(Code::DRY::find_duplicates_in(2, qr{}xms, ''), '', "duplicates for '' succeeds");

eval { require Test::Output && Test::Output->import(); };
my $noTestOutput = $@;

my $retval;
my @testcases = (
sub {$retval = Code::DRY::scan_directories(2,undef,undef,undef,'x'); },
sub {$retval = Code::DRY::scan_directories(2,undef,undef,qr{^00_lowlevel.t$|~$|\.swp$|\.bak}xms,'t'); },
sub {$retval = Code::DRY::scan_directories(2,undef,qr{\.t$}xmso,qr{\d.*?\.t$}xmso,'t'); },
sub {$retval = Code::DRY::scan_directories(2,undef,'\.t$|\.pl$','~$|\.swp$|\.bak','t'); },
sub {$retval = Code::DRY::scan_directories(2,qr{\bcopyright\b}xms,qr{\.t$}xms,qr{~$|\.swp$|\.bak}xms,'t', '.'); },
sub {$retval = Code::DRY::scan_directories(2,'\bcopyright\b','\.pl$','~$|\.swp$|\.bak','t/*'); },
sub {$retval = Code::DRY::scan_directories(2,undef,undef,undef,'t'); },
);
if ($noTestOutput) {
  subtest 'check scan_directories without Test::Output' => sub {
    plan tests => scalar @testcases;
    is(!defined $testcases[0]->(),1, 'undef, no valid directories given');
    is(         $testcases[1]->(),'','with ignore filter');
    is(!defined $testcases[2]->(),1,'with accept & ignore regex filter');
    is(         $testcases[3]->(),'','with accept & ignore string filter');
    is(         $testcases[4]->(),'','with content & accept & ignore filter');
    is(!defined $testcases[5]->(),1,'with all filters and globbing');
    is(         $testcases[6]->(),'','with all files');
  };
} else {
  subtest 'check scan_directories with Test::Output' => sub {
    plan tests => 2* scalar @testcases;
    stdout_is(  sub {$testcases[0]->()},"no valid directories given!\n", 'no dirs output');
    is(!defined $retval,1, 'undef, no valid directories given');

    stdout_like(sub {$testcases[1]->()},qr{duplicate\(s\)\sfound}xms,'output with ignore filter');
    is(         $retval,'','return value with ignore filter');

    stdout_is  (sub {$testcases[2]->()},"no files found for start dir(s) t with accept filter (?^msx:\\.t\$) and ignore filter (?^msx:\\d.*?\\.t\$)!\n",'output with accept & ignore regex filter');
    is(!defined $retval,1,'return value with accept & ignore regex filter');

    stdout_like(sub {$testcases[3]->()},qr{duplicate\(s\)\sfound}xms,'output with accept & ignore string filter');
    is(         $retval,'','return value with accept & ignore string filter');

    stdout_like(sub {$testcases[4]->()},qr{duplicate\(s\)\sfound}xms,'output with content & accept & ignore filter');
    is(         $retval,'','return value with content & accept & ignore filter');

    stdout_is(  sub {$testcases[5]->()},"no valid directories given!\n",'output with all filters and globbing');
    is(!defined $retval,1,'return value with all filters and globbing');

    stdout_like(sub {$testcases[6]->()},qr{duplicate\(s\)\sfound}xms,'output with all files');
    is(         $retval,'','return value with all files');
  };
}
#TODO
