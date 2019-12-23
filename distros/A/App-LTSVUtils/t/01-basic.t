#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use App::LTSVUtils;
use File::Temp qw(tempdir);
use File::Slurper qw(write_text);

my $dir = tempdir(CLEANUP => 1);
write_text("$dir/empty.ltsv", '');
#write_text("$dir/1.ltsv", "f1\tf2\tf3\n1\t2\t3\n4\t5\t6\n7\t8\t9\n");
#write_text("$dir/2.tsv", "f1\n1\n2\n3\n");
#write_text("$dir/3.csv", qq(f1,f2\n1,"row\n1"\n2,"row\n2"\n));
#write_text("$dir/4.tsv", qq(f1\tF3\tf2\n1\t2\t3\n4\t5\t6\n));
#write_text("$dir/5.tsv", qq(f1\n1\n2\n3\n4\n5\n6\n));
write_text("$dir/l1.ltsv", qq(f1:1\tf2:2\nf2:20\tf1:10\n));
#write_text("$dir/no-rows.tsv", qq(f1\tf2\tf3\n));
#write_text("$dir/no-header-1.tsv", "1\t2\t3\n4\t5\t6\n7\t8\t9\n");

subtest ltsv_dump => sub {
    my $res;

    $res = App::LTSVUtils::ltsv_dump(filename=>"$dir/l1.ltsv");
    is_deeply($res, [200,"OK",[{f1=>1, f2=>2}, {f1=>10, f2=>20}]])
        or diag explain $res;
};

done_testing;
