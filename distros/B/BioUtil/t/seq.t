#!/usr/bin/env perl

use Test::Simple tests => 5;

use strict;
use lib '../lib';

use BioUtil::Seq;

# =========================================================
my $file = "t/seq.fa";
my $seqs = read_sequence_from_fasta_file($file);
ok( keys %$seqs == 2 );

my $file2 = "t/seq2.fa";
write_sequence_to_fasta_file( $seqs, $file2 );
my $seqs2 = read_sequence_from_fasta_file($file);

ok( keys %$seqs == keys %$seqs2 );

# =========================================================

ok( validate_sequence('agagagcatttag-agagt')
        and not validate_sequence('jz') );

ok( revcom('accccgt') eq 'acggggt' );

ok( base_content( 'gc', 'gcagatatac' ) == 0.4 );
