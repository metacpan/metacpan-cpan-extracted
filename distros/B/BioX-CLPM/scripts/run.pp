#!/usr/bin/perl

use BioX::CLPM::Engine;

# Run parameters
my $file1  = '/home/mihir/clpm_perl/data/test_sequence1.fasta';
my $file2  = '/home/mihir/clpm_perl/data/bsa_sequence.fasta';
my $params = { enzyme_id   => 1,
	       linker_id   => 1,
	       sequences   => { files => [ $file1, $file2 ] },
	       tolerance   => '500',
	       missed_clvg => 3,
	       stat_mod    => 'carbamidomethylated',
	       var_mod     => { C => 160.2, M => -90.56 } };

# Create engine
my $engine = BioX::CLPM::Engine->new( $params );

my @sequences = $engine->sequences();
foreach my $sequence ( @sequences ) {
	warn "RUN    sequence->get_cl_sequence " . $sequence->get_cl_sequence() . "\n";
	my @fragments = $sequence->fragments();
	foreach my $fragment ( @fragments ) {
		warn "RUN    fragment_id " . $fragment->get_fragment_id() . "\n";
		warn "RUN    mass     " . $fragment->get_mass() . "\n";
		my %counts = %{ $fragment->get_counts() };
		warn "RUN    vmass    " . join( ':', keys %counts) . "," . join( ':', values %counts ) . "\n";
	}
}

my $mass = $engine->linker()->get_mass();
warn "RUN    linker mass " . $mass . "\n";

exit;

