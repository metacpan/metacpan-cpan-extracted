use strict;
use warnings;
use utf8;
use Algorithm::HyperLogLog;

my $hll = Algorithm::HyperLogLog->new(10);

while(<>){
    next if !defined $_;
    $hll->add($_);
}


my $cardinality = $hll->estimate;

__END__