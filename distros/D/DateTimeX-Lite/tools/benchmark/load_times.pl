use strict;
use Benchmark qw(cmpthese timethese);

my $count = shift @ARGV || 100;
cmpthese timethese $count => {
    dt => sub {
        system($^X, '-e', 'use DateTime') == 0 or die;
    },
    dt_lite => sub { 
        system($^X, '-Mblib', '-e', 'use DateTimeX::Lite') == 0 or die;
    },
    dt_lite_full => sub { 
        system($^X, '-Mblib', '-e', 'use DateTimeX::Lite qw(All)') == 0 or die;
    }
};