use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use Data::Dumper::AutoEncode::AsDumper;
use Encode;

my $data = {
    русский  => "доверяй, но проверяй",
    i中文    => "也許你的生活很有趣",
    Ελληνικά => "ἓν οἶδα ὅτι οὐδὲν οἶδα",
};

my $expected = q!{
  'i中文' => '也許你的生活很有趣',
  'Ελληνικά' => 'ἓν οἶδα ὅτι οὐδὲν οἶδα',
  'русский' => 'доверяй, но проверяй',
}
!;

subtest 'function is exported' => sub {
    my $got = Dumper $data;

    is( decode_utf8($got), $expected );
};

done_testing;