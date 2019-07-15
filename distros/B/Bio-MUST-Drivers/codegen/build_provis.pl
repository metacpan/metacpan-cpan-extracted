#!/usr/bin/env perl

use Modern::Perl '2011';
use autodie;

use Template;
use Path::Class qw(file dir);


# TODO: better handle taps (some are in homebrew/core and tap is useless)

my @provisions = (
    { 'class' => 'Blast',
      'app'   => 'NCBI-BLAST+',
      'pgm'   => 'blastp',
      'form'  => 'blast',               # homebrew/core
    },
    { 'class' => 'Cap3',
      'app'   => 'CAP3',
      'pgm'   => 'cap3',
      'form'  => 'cap3',                # brewsci/bio
    },
    { 'class' => 'CdHit',
      'app'   => 'CD-HIT',
      'pgm'   => 'cd-hit',
      'form'  => 'cd-hit',              # brewsci/bio
    },
    { 'class' => 'ClustalO',
      'app'   => 'Clustal Omega',
      'pgm'   => 'clustalo',
      'form'  => 'clustal-omega',       # brewsci/bio
    },
    { 'class' => 'Exonerate',
      'app'   => 'Exonerate',
      'pgm'   => 'exonerate',
      'form'  => 'exonerate',           # brewsci/bio
    },
    { 'class' => 'Hmmer',
      'app'   => 'HMMER',
      'pgm'   => 'hmmsearch',
      'form'  => 'hmmer',               # homebrew/core
    },
    { 'class' => 'Mafft',
      'app'   => 'MAFFT',
      'pgm'   => 'mafft',
      'form'  => 'mafft',               # homebrew/core
    },
);


my $template = file('codegen/templates', 'generic.tt')->stringify;
my $outdir = dir('lib/Bio/MUST/Provision');

for my $vars (@provisions) {
    my $outfile = file($outdir, $vars->{class} . '.pm')->stringify;
    my $tt = Template->new( { RELATIVE => 1 } );
    $tt->process($template, $vars, $outfile)
        or die 'Cannot build: ' . $outfile . ": $!";
}
