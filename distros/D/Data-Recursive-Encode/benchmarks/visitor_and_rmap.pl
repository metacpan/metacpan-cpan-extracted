#!perl
use warnings;
use utf8;
use Encode;
use Benchmark qw(:all);
use Data::Visitor::Encode;
use Data::Recursive::Encode;
use Data::Rmap ();
use Deep::Encode qw/deep_utf8_decode/;
 
my $sample = sub { { key => [("これはサンプルです") x 300] } };
 
my $cmp = timethese(
    -1,
    {
        data_recursive => sub {
            my $sample = $sample->();
            my ($s) = Data::Recursive::Encode->encode_utf8($sample);
        },
        data_visitor => sub {
            my $sample = $sample->();
            Data::Visitor::Encode->encode('utf8', $sample);
        },
        data_rmap => sub {
            my $sample = $sample->();
            Data::Rmap::rmap { $_ = Encode::encode_utf8($_) } $sample;
        },
        deep_encode => sub {
            my $sample = $sample->();
            Deep::Encode::deep_utf8_decode($sample);
        },
    }
);
 
cmpthese $cmp;
