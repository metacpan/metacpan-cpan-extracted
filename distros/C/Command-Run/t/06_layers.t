use strict;
use warnings;
use utf8;
use Test::More;

use Command::Run;

# Encoding layers pushed on STDIN/STDOUT during nofork execution must
# not accumulate across executions.
# cf. https://github.com/kaz-utashiro/perl-perlio-leak-bench

sub layers { scalar(() = PerlIO::get_layers(shift)) }

my %handle = (STDOUT => \*STDOUT, STDIN => \*STDIN);

for my $raw (0, 1) {
    my %before = map { $_ => layers($handle{$_}) } keys %handle;
    my $data;
    for (1 .. 10) {
	my $result = Command::Run->new(
	    command => [sub { print "j: ", scalar <STDIN> }],
	    stdin   => "\x{3042}\n",
	    nofork  => 1,
	    raw     => $raw,
	)->run;
	$data = $result->{data};
    }
    is $data, "j: \x{3042}\n", "nofork raw=$raw: data correct after repeated runs";
    for my $h (sort keys %handle) {
	is layers($handle{$h}), $before{$h},
	    "nofork raw=$raw: $h layer count unchanged";
    }
}

done_testing;
