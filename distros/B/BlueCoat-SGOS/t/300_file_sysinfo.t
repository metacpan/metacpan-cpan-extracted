#!perl -T
#
#
#
use strict;
use BlueCoat::SGOS;
use Test::More;

#use Test::NoWarnings;

BEGIN {chdir 't' if -d 't'}

my %testparams;
my $regex = $ARGV[0];

opendir(D, "sysinfos/");
my @files = readdir(D);
closedir D;

my $totaltests = 0;
foreach my $file (@files) {
	if ($file =~ m/\.parameters$/) {
		open(F, "<sysinfos/$file");
		while (<F>) {
			my $line = $_;
			chomp($line);
			my @s = split(/;/, $line);
			if ($#s < 1) {next}
			if ($regex) {
				if ($s[0] !~ /$regex/) {next}
			}
			$testparams{$s[0]}{$s[1]} = $s[2];
		}
		close F;
	}
}

$totaltests = keys %testparams;

# +1 for warnings
plan tests => $totaltests;

foreach (keys %testparams) {
	my $filename = $_;
	my %data     = %{$testparams{$filename}};
	my $subtests = keys %data;
	$subtests = $subtests + 4;
	note("subtests=$subtests");
	subtest "For $filename" => sub {
		plan tests => $subtests;
		note("Begin $filename");
		my $bc = BlueCoat::SGOS->new('debuglevel' => 0);

		# test 1 - do we have an object
		ok($bc, 'have an object');

		# test 2 - can we get a sysinfo from file
		ok($bc->get_sysinfo_from_file("sysinfos/$filename"), "file=$filename, got sysinfo");

		# test 3 - parse sysinfo (returns 1 if ok)
		ok($bc->parse_sysinfo(), "file=$filename, parse_sysinfo");

		# test 4 - is the size of the sysinfo greater than 10
		ok(length($bc->{'sgos_sysinfo'}) > 10, "file=$filename, sysinfo size gt 10");

		foreach (sort keys %data) {
			my $k     = $_;
			my $value = $data{$k};

			if ($k =~ m/int-/) {
				my ($interface, $configitem) = $k =~ m/int-(.+)-(.+)/;
				if (!defined($value) && !defined($bc->{'interface'}{$interface}{$configitem})) {
					pass("file=$filename, expected $interface $configitem undefined, got undefined)");
				}
				elsif ($value) {
					ok(
						$bc->{'interface'}{$interface}{$configitem} eq $value,
"file=$filename, expected $interface $configitem ($value), got ($bc->{'interface'}{$interface}{$configitem})"
					);
				}
				else {
					fail(
"file=$filename, expected $interface $configitem ($value), got ($bc->{'in    terface'}{$interface}{$configitem})"
					);
				}
			}
			elsif ($k =~ m/length-/) {
				my ($var) = $k =~ m/length-(.+)/;
				my $length = length($bc->{$var}) || 0;
				if (!defined($value)) {
					$value = 0;
				}
				ok($length == $value, "file=$filename, length($var), expected ($value), got ($length)");
			}
			else {
				if (!defined($value) && !defined($bc->{$k})) {
					pass("file=$filename, $k: expected blank, got blank");
				}
				else {
					ok($bc->{$k} eq $value, "file=$filename, $k: expected ($value), got ($bc->{$k})");
				}
			}
		}
		note("End $filename");
	  }
}

