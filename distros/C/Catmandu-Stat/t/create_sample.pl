#!/usr/bin/env perl

use Catmandu;

my $exporter = Catmandu->exporter('JSON', line_delimited => 1);

my $N = shift // 1000;

for (my $i = 0 ; $i < $N ; $i++) {

    my $rec = {};

    $rec->{'uniq'}    = $i;
    $rec->{'half'}    = $i if ($i % 2 == 0);
    $rec->{'quarter'} = $i if ($i % 4 == 0);
    $rec->{'double'}  = $i % 2 ? [1,0] : [0,1];

    $exporter->add($rec);
}

$exporter->commit;

print  STDERR "entropy:\n";
printf STDERR "uniq:    %.1f\n" , log($N) / log(2);
printf STDERR "half:    %.1f\n" , -1 * ( (1/2)*log(1/2) + (1/2) * log(1/$N) )/log(2);
printf STDERR "quarter: %.1f\n" , -1 * ( (3/4)*log(3/4) + (1/4) * log(1/$N) )/log(2);
printf STDERR "double:  %.1f\n" , -1 * log(1/2) / log(2);
