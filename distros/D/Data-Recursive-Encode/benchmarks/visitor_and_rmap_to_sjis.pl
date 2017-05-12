#!perl
use warnings;
use utf8;
use Encode;
use Benchmark qw(:all);
use Data::Visitor::Encode;
use Data::Recursive::Encode;
use Data::Rmap ();
use Deep::Encode ();
 
my $sample = sub {
    return { key => [("これはサンプルです") x 300] }
};

 
my $cmp = timethese(
    -1,
    {
        data_recursive => sub {
            my $sample = $sample->();
            my ($s) = Data::Recursive::Encode->encode('Shift_JIS', $sample);
        },
        data_visitor => sub {
            my $sample = $sample->();
            Data::Visitor::Encode->encode('Shift_JIS', $sample);
        },
        data_rmap => sub {
            my $sample = $sample->();
            Data::Rmap::rmap { $_ = Encode::encode('Shift_JIS', $_) } $sample;
        },
        deep_encode => sub {
            my $sample = $sample->();
            Deep::Encode::deep_encode($sample, 'Shift_JIS');
        },
    }
);
 
cmpthese $cmp;
