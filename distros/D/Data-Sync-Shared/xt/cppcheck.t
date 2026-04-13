use strict;
use warnings;
use Test::More;

plan skip_all => 'set CPPCHECK=1 to run' unless $ENV{CPPCHECK};

my $cppcheck = `which cppcheck 2>/dev/null`;
chomp $cppcheck;
plan skip_all => 'cppcheck not found' unless $cppcheck && -x $cppcheck;

my $out = `cppcheck --enable=warning,style,performance --error-exitcode=1 --suppress=missingIncludeSystem --inline-suppr -I. sync.h 2>&1`;
my $exit = $? >> 8;

if ($exit == 0) {
    pass 'cppcheck: no issues in sync.h';
} else {
    fail 'cppcheck: issues found in sync.h';
    diag $out;
}

done_testing;
