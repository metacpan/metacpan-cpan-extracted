#!perl

use 5.010;
use strict;
use warnings;

use IO::Scalar;
use Test::Exception;
use Test::More 0.98;

use Data::Section::Seekable::Reader;
use Data::Section::Seekable::Writer;

my $part1 = pack("H*","8ef3945ee62ce743140a50cf0b78f00bca9f6d25");
my $part2 = pack("H*","db198d9489ec4b325d895f3e35ae20086872682d");

my $writer = Data::Section::Seekable::Writer->new;
$writer->add_part(part1 => $part1);
$writer->add_part(part2 => $part2);
my $data = $writer->as_string;
is($data,
   join(
       "",
       "Data::Section::Seekable v1\n",
       "part1,14,20\n",
       "part2,48,20\n\n",
       "### part1 ###\n",
       "\x8E\xF3\x94^\xE6,\xE7C\24\nP\xCF\13x\xF0\13\xCA\x9Fm%",
       "### part2 ###\n",
       "\xDB\31\x8D\x94\x89\xECK2]\x89_>5\xAE \bhrh-",
   )
);

my $fh = IO::Scalar->new(\$data);
my $reader = Data::Section::Seekable::Reader->new(handle=>$fh);
is_deeply([$reader->parts], ["part1", "part2"]);
is($reader->read_part('part1'), $part1);
is($reader->read_part('part2'), $part2);

done_testing;
