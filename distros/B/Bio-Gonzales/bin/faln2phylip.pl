#!/usr/bin/env perl

use Getopt::Long::Descriptive;
use Bio::Gonzales::Align::IO qw/phylip_spew/;
use Bio::Gonzales::Seq::IO qw/faslurp/;

my ($opt, $usage) = describe_options(
    '%c %o <fasta_alignment_file>, <phylip_alignment_destination_file>',
    [ 'help',       "print usage message and exit" ],
 );

print($usage->text), exit if $opt->help;

my ($in, $out) = @ARGV;
my $seqs = faslurp($in);

$seqs = [ grep { $_->seq =~ /\w/ } @$seqs ];
phylip_spew($out, 'relaxed sequential', $seqs );
