#!/usr/bin/perl

use BioX::CLPM::Engine;

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
   $engine->db_trunc();
warn "TEST   db_trunc()\n";

#my $file = '/home/mihir/clpm_perl/data/test_sequence1.fasta';
#my $seq  = $engine->get_seq({ file => $file });
#warn "TEST   get_seq() $seq\n";

warn "TEST   get_enzyme->get_name() " . $engine->get_enzyme->get_name() . "\n";
my $enzyme = $engine->enzyme({ id => 1 });
warn "TEST   enzyme->get_name " . $enzyme->get_name() . "\n";

warn "TEST   get_linker->get_name() " . $engine->get_linker->get_name() . "\n";
my $linker = $engine->linker({ id => 4 });
warn "TEST   linker->get_name " . $linker->get_name() . "\n";

my @sequences = $engine->sequences();
foreach my $sequence ( @sequences ) {
	warn "TEST   sequence->get_sequence " . $sequence->get_sequence() . "\n";
}

$engine->mark_links();
warn "TEST   engine->mark_links \n";
my @sequences = $engine->sequences();
foreach my $sequence ( @sequences ) {
	warn "TEST   sequence->get_cl_sequence " . $sequence->get_cl_sequence() . "\n";
}

warn "TEST   engine->cleave \n";
$engine->cleave();

exit;

