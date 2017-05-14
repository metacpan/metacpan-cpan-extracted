#!perl
# -*- perl -*-
#
# DO NOT EDIT, created automatically by ../mkprereqinst.pl

# on Thu Nov  4 00:28:23 2004
#

use Getopt::Long;
my $require_errors;
my $use = 'cpan';

if (!GetOptions("ppm"  => sub { $use = 'ppm'  },
		"cpan" => sub { $use = 'cpan' },
	       )) {
    die "usage: $0 [-ppm | -cpan]\n";
}

if ($use eq 'ppm') {
    require PPM;
    do { print STDERR 'Install Benchmark-Harness'.qq(\n); PPM::InstallPackage(package => 'Benchmark-Harness') or warn ' (not successful)'.qq(\n); } if !eval 'require Benchmark::Harness; Benchmark::Harness->VERSION(1.08)';
    do { print STDERR 'Install GD-Graph-lines'.qq(\n); PPM::InstallPackage(package => 'GD-Graph-lines') or warn ' (not successful)'.qq(\n); } if !eval 'require GD::Graph::lines; GD::Graph::lines->VERSION(1.15)';
    do { print STDERR 'Install GD'.qq(\n); PPM::InstallPackage(package => 'GD') or warn ' (not successful)'.qq(\n); } if !eval 'require GD; GD->VERSION(2.12)';
} else {
    use CPAN;
    install 'Benchmark::Harness' if !eval 'require Benchmark::Harness; Benchmark::Harness->VERSION(1.08)';
    install 'GD::Graph::lines' if !eval 'require GD::Graph::lines; GD::Graph::lines->VERSION(1.15)';
    install 'GD' if !eval 'require GD; GD->VERSION(2.12)';
}
if (!eval 'require Benchmark::Harness; Benchmark::Harness->VERSION(1.08);') { warn $@; $require_errors++ }
if (!eval 'require GD::Graph::lines; GD::Graph::lines->VERSION(1.15);') { warn $@; $require_errors++ }
if (!eval 'require GD; GD->VERSION(2.12);') { warn $@; $require_errors++ }warn "Autoinstallation of prerequisites completed\n" if !$require_errors;
