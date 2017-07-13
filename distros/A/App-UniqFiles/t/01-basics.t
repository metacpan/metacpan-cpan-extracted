#!perl -T

use 5.010;
use strict;
use warnings;

use Test::More 0.98;

use File::chdir;
use File::Slurper qw(write_text);
use File::Temp qw(tempdir);
use App::UniqFiles qw(uniq_files);

my $dir = tempdir( CLEANUP => 1 );
$CWD = $dir;

write_text("f1", "a");
write_text("f2", "a");
write_text("f3", "c");
write_text("f4", "aa");
write_text("f5", "a");
# glob only returns f1??
#my @f = glob <f*>;
#diag explain \@f;
my @f = qw(f1 f2 f3 f4 f5);

my $res;

$res = uniq_files(files => \@f);
is_deeply($res->[2], ["f1", "f3", "f4"],
          "default: report_unique=1, report_duplicate=2")
    or diag explain $res;

$res = uniq_files(files => \@f, report_duplicate=>1);
is_deeply($res->[2], ["f1", "f2", "f3", "f4", "f5"], "report_duplicate=1")
    or diag explain $res;

$res = uniq_files(files => \@f, report_unique=>0, report_duplicate=>1);
is_deeply($res->[2], ["f1", "f2", "f5"], "report_unique=0, report_duplicate=1")
    or diag explain $res;

$res = uniq_files(files => \@f, count=>1);
is_deeply($res->[2], {f1=>3, f2=>3, f3=>1, f4=>1, f5=>3}, "count")
    or diag explain $res;

# check_content=0
$res = uniq_files(files => \@f, count=>1, check_content=>0);
is_deeply($res->[2], {f1=>4, f2=>4, f3=>4, f4=>1, f5=>4}, "check_content=0")
    or diag explain $res;

chdir "/" if Test::More->builder->is_passing;
done_testing();
