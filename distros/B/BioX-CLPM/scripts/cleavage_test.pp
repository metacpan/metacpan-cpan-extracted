#!/usr/bin/perl

use BioX::CLPM::Engine;

my $file1 = '/home/mihir/clpm_perl/data/test_sequence1.fasta';
my $file2 = '/home/mihir/clpm_perl/data/bsa_sequence.fasta';
my $params = { enzyme_id   => 1,
	       linker_id   => 2,
	       sequences   => { files => [ $file1, $file2 ] },
	       tolerance   => '500',
	       missed_clvg => 3,
	       stat_mod    => 'carbamidomethylated',
	       var_mod     => 'oxidized methionine' };

my $engine = BioX::CLPM::Engine->new( $params );

my $enzyme          = $engine->get_enzyme();
my $enzyme_id       = $enzyme->get_enzyme_id();
my $enzyme_name     = $enzyme->get_name();
my $clvg_sites      = $enzyme->get_clvg_sites();
my $clvg_position   = $enzyme->get_clvg_position();
my $missed_clvg     = $engine->get_missed_clvg();
my ( $end1, $end2 ) = $engine->get_linker->ends();

print "enzyme       $enzyme          \n";
print "enzyme_id    $enzyme_id       \n";
print "enzyme_name  $enzyme_name     \n";
print "clvg_sites   $clvg_sites      \n";
print "clvg_positio $clvg_position   \n";
print "missed_clvg  $missed_clvg     \n";
print "ends         ( $end1, $end2 ) \n";

$engine->cleave();

exit;

