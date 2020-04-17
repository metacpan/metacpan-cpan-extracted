use strict;
use warnings;
use Test::More;
use Test::More::UTF8;
use Encode;
use Capture::Tiny 'capture_stderr';
use FindBin '$RealBin';

my $expected = encode_utf8 q!{
  'i中文' => '也許你的生活很有趣',
  'Ελληνικά' => 'ἓν οἶδα ὅτι οὐδὲν οἶδα',
  'русский' => 'доверяй, но проверяй',
}
!;

subtest 'function is imported via loading object\'s parent class' => sub {
    my $dump = capture_stderr(sub {
        qx{perl $RealBin/import-via-class-load-inherited.pl}
    });

    is( $dump, $expected, 'output ok' );
};

done_testing;
__END__