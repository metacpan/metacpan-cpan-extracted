#!/usr/bin/perl -w

use GDBM_File;
use Benchmark;

use vars qw(%hash $n);
$n = 0;

tie %hash, 'GDBM_File', '/tmp/foo.gdbm', &GDBM_WRCREAT, 0640;

sub insert {
	$hash{$n} = "A"x2**10;
	$n++;
}

sub access {
	my $this = $hash{int(rand($n-1))};
}
	
timethis(10000, \&insert, 'First 10000');
timethis(10000, \&access, 'Random Access n=10000');
timethis(90000, \&insert, 'Pad to 100000');
timethis(10000, \&insert, 'Insert 100000-110000');
timethis(10000, \&access, 'Random Access n=110000');
timethis(990000, \&insert, 'Pad to 1000000');
timethis(10000, \&insert, 'Insert 1000000-1001000');
timethis(10000, \&access, 'Random Access n=1001000');
