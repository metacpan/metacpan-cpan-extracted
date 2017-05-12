#!/usr/bin/perl

use BioX::CLPM::Engine;

# Start with files as normal
my $file1 = '/home/mihir/clpm_perl/data/test_sequence1.fasta';
my $file2 = '/home/mihir/clpm_perl/data/bsa_sequence.fasta';
my $params = { enzyme_id   => 1,
	       linker_id   => 3,
	       sequences   => { files => [ $file1, $file2 ] },
	       tolerance   => '500',
	       missed_clvg => 3,
	       stat_mod    => 'carbamidomethylated',
	       var_mod     => 'oxidized methionine' };

my $engine = BioX::CLPM::Engine->new( $params );
   $engine->mark_links();
my @sequences = $engine->sequences();
foreach my $sequence ( @sequences ) {
	warn "TEST   sequence->get_cl_sequence " . $sequence->get_cl_sequence() . "\n";
}

# Use new sequences and new linker
#my $linker    = BioX::CLPM::Engine->new( $params );
#my $sequence1 = BioX::CLPM::Engine->new( $params );
#my $sequence2 = BioX::CLPM::Engine->new( $params );



exit;

