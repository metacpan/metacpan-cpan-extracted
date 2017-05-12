#!perl
use 5.014;
use warnings;
use Benchmark qw(cmpthese timethese);
use Data::BinaryBuffer;

my $small_sample = 'abcdefg';
my $big_sample = '0123456789' x (100*1024); # 1Mb

my ($tmp1,$tmp2);
my $ret = timethese(-1, {
    'BB big' => sub {
        my $buf = Data::BinaryBuffer->new;
        my $cnt = 100;
        while (--$cnt) {
            $buf->add($big_sample);
            $tmp1 = $buf->read(512*1024);
            $tmp2 = $buf->read(512*1024);
        }
    },
    'P big' => sub {
        my $buf = '';
        my $cnt = 100;
        while (--$cnt) {
            $buf .= $big_sample;
            $tmp1 = substr $buf, 0, 512*1024, '';
            $tmp2 = substr $buf, 0, 512*1024, '';
        }
    },
    'BB small' => sub {
        my $buf = Data::BinaryBuffer->new;
        my $cnt = 1000;
        while (--$cnt) {
            $buf->add($small_sample);
            $tmp1 = $buf->read(2);
            $tmp2 = $buf->read(5);
        }
    },
    'P small' => sub {
        my $buf = '';
        my $cnt = 1000;
        while (--$cnt) {
            $buf .= $small_sample;
            $tmp1 = substr $buf, 0, 2, '';
            $tmp2 = substr $buf, 0, 5, '';
        }
    },
});
