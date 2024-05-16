#!perl

use strict;
use warnings;
use Test::Exception;
use Test::More 0.98;

use ArrayData::Test::Source::LinesInFile;
use File::Temp qw(tempfile);

my ($tempfh, $tempfile) = tempfile();
print $tempfh "one\n";
print $tempfh "two\n";
print $tempfh "three\n";
seek $tempfh, 0, 0;

for my $which (1..2) {
    my ($t, $subtestname);
    if ($which == 1) {
        $t = ArrayData::Test::Source::LinesInFile->new(fh => $tempfh);
        $subtestname = "fh";
    } else {
        close $tempfh;
        $t = ArrayData::Test::Source::LinesInFile->new(filename => $tempfile);
        $subtestname = "filename";
    }

    subtest $subtestname => sub {
        $t->reset_iterator;
        is_deeply($t->get_next_item, "one");
        is_deeply($t->get_next_item , "two");
        is_deeply($t->get_next_item , "three");
        dies_ok { $t->get_next_item };

        $t->reset_iterator;
        is_deeply($t->get_next_item, "one");

        ok($t->has_item_at_pos(0));
        is_deeply($t->get_item_at_pos(0), "one");
        ok($t->has_item_at_pos(2));
        is_deeply($t->get_item_at_pos(2), "three");
        ok(!$t->has_item_at_pos(3));
        dies_ok { $t->get_item_at_pos(3) };
    };

    # test reopen

    if ($which == 2) {
        close $tempfh;
        $t = ArrayData::Test::Source::LinesInFile->new(filename => $tempfile);

        subtest "$subtestname reopen" => sub {
            is_deeply($t->get_next_item, "one");
        };
    }
}

done_testing;
