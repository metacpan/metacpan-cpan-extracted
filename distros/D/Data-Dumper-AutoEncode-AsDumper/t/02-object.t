use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use Encode;

package MyClass {
    use Data::Dumper::AutoEncode::AsDumper;

    sub new {
        my $class = shift;
        return bless {}, $class;
    }
};

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

subtest 'function is imported via object' => sub {
    my $obj = MyClass->new;
    my $got = Dumper $data;

    is( decode_utf8($got), $expected );
};

done_testing;