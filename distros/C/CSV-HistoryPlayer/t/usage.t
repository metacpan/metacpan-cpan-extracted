use strict;
use warnings;

use Test::More;
use Test::Warnings;

use Path::Tiny;
use CSV::HistoryPlayer;

sub test_hp {
    my ($name, $code) = @_;
    my $tmp_dir = Path::Tiny->tempdir(CLEANUP => 1);
    subtest $name => sub { $code->($tmp_dir) };
}

subtest "find CSV files" => sub {

    test_hp(
        "simple case" => sub {
            my $tmp_dir = shift;
            path($tmp_dir, 'a.csv')->spew("does-not-matter");
            path($tmp_dir, 'b.csv')->spew("does-not-matter");

            my $player = CSV::HistoryPlayer->new(root_dir => $tmp_dir);
            my $files = [map { $_->basename } @{$player->files}];
            is_deeply $files, [qw/a.csv b.csv/];
        });

    test_hp(
        "nested dirs, unneeded files, dirs filtering" => sub {
            my $tmp_dir = shift;
            my $file_a  = path($tmp_dir, "5", "6", "7", "8", 'a.csv');
            my $file_b  = path($tmp_dir, "1", "2", "3", "4", 'b.CSV');
            my $file_c  = path($tmp_dir, "2", 'c.txt');
            my $file_d  = path($tmp_dir, "6", "NON_NEEDED", "4", 'd.CSV');
            for ($file_a, $file_b, $file_c, $file_d) {
                $_->touchpath;
                $_->spew("does-not-matter");
            }

            my $player = CSV::HistoryPlayer->new(
                root_dir   => $tmp_dir,
                dir_filter => sub { $_[0]->basename !~ /NON_NEEDED/ },
            );
            my $files = [map { $_->basename } @{$player->files}];
            is_deeply $files, [qw/b.CSV a.csv/];

            # another way to accomplish the same
            my $player_2 = CSV::HistoryPlayer->new(
                root_dir     => $tmp_dir,
                files_mapper => sub {
                    my $files = shift;
                    return [reverse sort grep { $_ !~ /NON_NEEDED/ } @$files];
                });
            my $files_2 = [map { $_->basename } @{$player_2->files}];
            is_deeply $files_2, [qw/a.csv b.CSV/];
        });

};

subtest "csv iterator" => sub {

    my $cmp_output = sub {
        my ($out, $filename, $data, $msg) = @_;
        local $Test::Builder::Level = $Test::Builder::Level + 1;
        is $out->[0]->basename, $filename, "file is ok ($msg)";
        is_deeply $out->[1], $data, "data is ok ($msg)";
    };

    my $cmp_scenario = sub {
        my ($player, $expected_rows) = @_;
        for my $idx (0 .. @$expected_rows - 1) {
            my $row    = $expected_rows->[$idx];
            my $actual = $player->poll;
            is $actual->[0]->basename, $row->[0], " row $idx filename match";
            is_deeply $actual->[1], $row->[1], " row $idx content match";
        }
        is $player->poll, undef, "eof";
    };

    test_hp(
        "simple sequentical case" => sub {
            my $tmp_dir = shift;
            path($tmp_dir, 'a.csv')->spew(<<AA);
1399013000,a1
1399013001,a2
1399013002,a3
AA
            path($tmp_dir, 'b.csv')->spew(<<BB);
1399013020,b1
1399013021,b2
BB
            my $player = CSV::HistoryPlayer->new(root_dir => $tmp_dir);
            $cmp_output->($player->peek, 'a.csv', [qw/1399013000 a1/], "peek");
            $cmp_output->($player->peek, 'a.csv', [qw/1399013000 a1/], "peek again");
            $cmp_output->($player->poll, 'a.csv', [qw/1399013000 a1/], "poll");
            $cmp_output->($player->poll, 'a.csv', [qw/1399013001 a2/], "poll again");
            $cmp_output->($player->peek, 'a.csv', [qw/1399013002 a3/], "peek");
            $cmp_output->($player->poll, 'a.csv', [qw/1399013002 a3/], "poll (eof for a)");
            $cmp_output->($player->poll, 'b.csv', [qw/1399013020 b1/], "poll");
            $cmp_output->($player->poll, 'b.csv', [qw/1399013021 b2/], "poll");
            is $player->poll, undef, "eof";
        });

    test_hp(
        "simple parallel case" => sub {
            my $tmp_dir = shift;
            my $f1      = path($tmp_dir, "1", 'a.csv');
            my $f2      = path($tmp_dir, "2", 'a.csv');

            $_->touchpath for ($f1, $f2);

            $f1->spew(<<AA);
1399013001,a2
1399013003,a4
1399013004,a5
AA
            $f2->spew(<<BB);
1399013000,a1
1399013002,a3
1399013005,a6
BB
            my $player = CSV::HistoryPlayer->new(root_dir => $tmp_dir);
            $cmp_scenario->(
                $player,
                [
                    ['a.csv', [qw/1399013000 a1/],],
                    ['a.csv', [qw/1399013001 a2/],],
                    ['a.csv', [qw/1399013002 a3/],],
                    ['a.csv', [qw/1399013003 a4/],],
                    ['a.csv', [qw/1399013004 a5/],],
                    ['a.csv', [qw/1399013005 a6/],],
                ]);
        });

    test_hp(
        "mixed parallel case" => sub {
            my $tmp_dir = shift;
            my $f1      = path($tmp_dir, "1", 'a.csv');
            my $f2      = path($tmp_dir, "2", 'a.csv');
            my $f3      = path($tmp_dir, "3", 'b.csv');
            my $f4      = path($tmp_dir, "4", 'c.csv');
            my $f5      = path($tmp_dir, "5", "5", "5", 'c.csv');

            $_->touchpath for ($f1, $f2, $f3, $f4, $f5);

            $f1->spew(<<A1);
1399013000,a1
1399013002,a3
A1
            $f2->spew(<<A2);
1399013001,a2
1399013003,a4
A2
            $f3->spew(<<B);
1399013010,b1
1399013011,b2
B
            $f4->spew(<<C1);
1399013020,c1
1399013030,c3
C1
            $f5->spew(<<C2);
1399013025,c2
1399013035,c4
C2

            my $player = CSV::HistoryPlayer->new(root_dir => $tmp_dir);
            $cmp_scenario->(
                $player,
                [
                    ['a.csv', [qw/1399013000 a1/],],
                    ['a.csv', [qw/1399013001 a2/],],
                    ['a.csv', [qw/1399013002 a3/],],
                    ['a.csv', [qw/1399013003 a4/],],
                    ['b.csv', [qw/1399013010 b1/],],
                    ['b.csv', [qw/1399013011 b2/],],
                    ['c.csv', [qw/1399013020 c1/],],
                    ['c.csv', [qw/1399013025 c2/],],
                    ['c.csv', [qw/1399013030 c3/],],
                    ['c.csv', [qw/1399013035 c4/],],
                ]);
        });
};

done_testing;
