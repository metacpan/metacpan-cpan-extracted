use strict;
use warnings;
use utf8;
use Test::More;
#use Test::More::UTF8;
use Encode;
use Capture::Tiny 'capture_stderr';
use FindBin '$RealBin';

my $expected = q!{
  'i中文' => '也許你的生活很有趣',
  'Ελληνικά' => 'ἓν οἶδα ὅτι οὐδὲν οἶδα',
  'русский' => 'доверяй, но проверяй',
}
!;

subtest 'function is imported via class function' => sub {
    my $dump = capture_stderr(sub {
        qx{perl $RealBin/import-via-class-function.pl}
    });

    is( decode_utf8($dump), $expected, 'output ok' );
};

done_testing;
__END__