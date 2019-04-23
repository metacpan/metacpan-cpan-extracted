#!perl

use 5.010001;
use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use App::TSVUtils;
use File::Temp qw(tempdir);
use File::Slurper qw(write_text);

my $dir = tempdir(CLEANUP => 1);
write_text("$dir/empty.tsv", '');
write_text("$dir/1.tsv", "f1\tf2\tf3\n1\t2\t3\n4\t5\t6\n7\t8\t9\n");
write_text("$dir/2.tsv", "f1\n1\n2\n3\n");
#write_text("$dir/3.csv", qq(f1,f2\n1,"row\n1"\n2,"row\n2"\n));
write_text("$dir/4.tsv", qq(f1\tF3\tf2\n1\t2\t3\n4\t5\t6\n));
write_text("$dir/5.tsv", qq(f1\n1\n2\n3\n4\n5\n6\n));
write_text("$dir/no-rows.tsv", qq(f1\tf2\tf3\n));
write_text("$dir/no-header-1.tsv", "1\t2\t3\n4\t5\t6\n7\t8\t9\n");

# XXX test with opt: --no-header

subtest tsv_dump => sub {
    my $res;

    $res = App::TSVUtils::tsv_dump(filename=>"$dir/1.tsv");
    is_deeply($res, [200,"OK",[["f1","f2","f3"],[1,2,3],[4,5,6],[7,8,9]]])
        or diag explain $res;
};

done_testing;
