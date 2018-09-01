#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use Test::Exception;
use IO::String;
use Path::Tiny;
use Catmandu::Store::File::BagIt;
use utf8;

my $pkg;

BEGIN {
    $pkg = 'Catmandu::Store::File::BagIt::Bag';
    use_ok $pkg;
}

require_ok $pkg;

my $bag_dir = "t/my-bag-$$";

my $store
    = Catmandu::Store::File::BagIt->new(root => $bag_dir, keysize => 9);
my $index = $store->bag;

ok $store , 'got a store';
ok $index , 'got an index';

ok $index->add({_id => 1234}), 'adding bag `1234`';

my $bag = $store->bag('1234');

ok $bag , 'got bag(1234)';

note("add");
{
    ok $bag->upload(IO::File->new('t/data2/000/000/001/data/test.txt'),
        'test1.txt');

    ok -f "$bag_dir/000/001/234/data/test1.txt", 'test1.txt exists';

    ok $bag->upload(IO::File->new('t/data2/000/000/002/data/test.txt'),
        'test2.txt');

    ok -f "$bag_dir/000/001/234/data/test2.txt", 'test2.txt exists';

    ok $bag->upload(IO::File->new('t/data2/000/000/003/data/test.txt'),
        'test3.txt');

    ok -f "$bag_dir/000/001/234/data/test3.txt", 'test3.txt exists';
}

note("list");
{
    my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [qw(test1.txt test2.txt test3.txt)],
        'got correct response';
}

note("exists");
{
    for (1 .. 3) {
        ok $bag->exists("test" . $_ . ".txt"), "exists(test" . $_ . ".txt)";
    }
}

note("get");
{
    for (1 .. 3) {
        ok $bag->get("test" . $_ . ".txt"), "get(test" . $_ . ".txt)";
    }

    {
        my $file = $bag->get("test1.txt");

        my $str = $bag->as_string_utf8($file);

        ok $str , 'can stream the data';

        is $str , "钱唐湖春行\n", 'got the correct data';
    }

    {
        my $file = $bag->get("test1.txt");

        my $tempfile = Path::Tiny->tempfile;

        my $io    = IO::File->new("> $tempfile");

        $io->binmode(":raw");

        my $bytes = $bag->stream($io, $file);

        $io->close();

        ok $bytes , 'can stream the data';

        is $bytes , 16 , 'got correct byte count';

        my $str = path($tempfile)->slurp_utf8;

        is $str , "钱唐湖春行\n", 'got the correct data';
    }
}

note("delete");
{
    ok $bag->delete('test1.txt'), 'delete(test1.txt)';

    my $array = [sort @{$bag->map(sub {shift->{_id}})->to_array}];

    ok $array , 'list got a response';

    is_deeply $array , [qw(test2.txt test3.txt)], 'got correct response';
}

note("delete_all");
{
    lives_ok {$bag->delete_all()} 'delete_all';

    my $array = $bag->to_array;

    is_deeply $array , [], 'got correct response';
}

done_testing();

END {
	my $error = [];
	path("$bag_dir")->remove_tree;
};
