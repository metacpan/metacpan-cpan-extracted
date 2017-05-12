#!/usr/bin/perl
###########################################
# keylock.pl - Sample for set covering
# Mike Schilli, 2003 (m@perlmeister.com)
###########################################
use warnings;
use strict;

use Algorithm::SetCovering;
use Log::Log4perl qw(:easy);

Log::Log4perl->easy_init({level => $INFO, 
                          layout => "%m%n"});

my $alg = Algorithm::SetCovering->new(
    columns => 4,
    mode    => "greedy");

$alg->add_row(1, 0, 1, 0);
$alg->add_row(1, 1, 0, 0);
$alg->add_row(1, 1, 1, 0);
$alg->add_row(0, 1, 0, 1);
$alg->add_row(0, 0, 1, 1);

my @to_be_opened = (@ARGV || (1, 1, 1, 1));

my @set = $alg->min_row_set(@to_be_opened);

print "To open (@to_be_opened), we need ",
      scalar @set, " keys:\n";

for(@set) {
    print "$_: ", join('-', $alg->row($_)), "\n";
}
