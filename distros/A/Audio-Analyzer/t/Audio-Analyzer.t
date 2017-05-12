#!/opt/local/bin/perl

use strict;
use warnings;

use Audio::Analyzer;
use Test::Simple tests => 1218;

my $a = Audio::Analyzer->new(file => 't/1000hz.pcm', sample_rate => 8000, channels => 1, dft_size => 2**6);
my @freq_list = parse_freq('t/1000hz.freq');

ok(defined($a) && ref $a eq 'Audio::Analyzer', 'new() works');

check_lists(\@freq_list, $a->freqs);
check_output($a);

sub parse_freq {
	my ($file) = @_;
	local($/) = undef;
	my @data;
	
	die "could not open $file: $!" unless open(FREQ, $file);
	@data = split("\n", <FREQ>);
	die "could not close $file: $!" unless close(FREQ);

	return @data;
}

sub check_lists {
	my ($ref1, $ref2) = @_;
	my $last = $#$ref1;

	ok(scalar(@$ref1) == scalar(@$ref2), "lists are same length, last element: $last");

	foreach my $i (0 .. $last)  {
		ok($ref1->[$i] == $ref2->[$i], "element $i match");
	}
}

sub check_output {
	my ($a) = @_;
	my $chunk;
	my $len = 32;

	while(defined($chunk = $a->next)) {
		ok(ref($chunk) eq 'Audio::Analyzer::Chunk', 'got a proper chunk');

		my $data = $chunk->fft;
		ok(scalar(@$data) == 1, 'channels is proper length');

		$data = $data->[0];
		ok(scalar(@$data) == $len, 'data is proper length');
		
		foreach my $i (0 .. $len - 1) {
			my $one = $data->[$i];

			if ($one > .1) {
				ok($i == 28, "large value in proper band: $i");

				ok($one > 0.182, "lower bound ok: $one band: $i");
				ok($one < 0.188, "upper bound ok: $one band: $i");
			} else {
				ok($i != 28, "noise is in proper band: $one band: $i");
			}
		}
	}
}

