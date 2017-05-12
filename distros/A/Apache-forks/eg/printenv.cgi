#!/usr/bin/perl
##
##  printenv -- demo CGI program which just prints its environment
##

use threads;
use threads::shared;

use Data::Dumper;
use Benchmark qw(:all);

print "Content-type: text/plain\n\n";

### print environment details ###
foreach $var (sort(keys(%ENV))) {
    $val = $ENV{$var};
    $val =~ s|\n|\\n|g;
    $val =~ s|"|\\"|g;
    print "${var}=\"${val}\"\n";
}

print Dumper(\%INC);

print "\nmy tid=";
print threads->tid,"\n";

### create some threads ###
my @threads;
push @threads, threads->new(sub {
	sleep 1;
}) for 1..5;
$_->join foreach @threads;
print "ok, we joined all locally-created threads (".scalar(@threads).")\n";

### test global hash cache ###
$mycache::cache{counter}++;
print Dumper(\%mycache::cache);

### test performance of global vars ###
timethis (-5, sub { $mycache::cache{somevar}++ } );
