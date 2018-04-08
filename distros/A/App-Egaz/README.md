[![Build Status](https://travis-ci.org/wang-q/App-Egaz.svg?branch=master)](https://travis-ci.org/wang-q/App-Egaz) [![Coverage Status](http://codecov.io/github/wang-q/App-Egaz/coverage.svg?branch=master)](https://codecov.io/github/wang-q/App-Egaz?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/App-Egaz.svg)](https://metacpan.org/release/App-Egaz)
# NAME

App::Egaz - Backend of **E**asy **G**enome **A**ligner

# SYNOPSIS

    egaz <command> [-?h] [long options...]
            -? -h --help  show help

    Available commands:

        commands: list the application's commands
            help: display a command's help screen

          blastn: blastn wrapper between two fasta files
      exactmatch: exact matched positions in genome sequences
         formats: formats of files use in this project
           lastz: lastz wrapper for two genomes or self alignments
         lav2axt: convert .lav files to .axt files
         lav2psl: convert .lav files to .psl files
          lpcnam: the pipeline of pairwise lav-psl-chain-net-axt-maf
          masked: masked (or gaps) regions in fasta files
       maskfasta: soft/hard-masking sequences in a fasta file
       normalize: normalize lav files
       partition: partitions fasta files by size
        plottree: use the ape package to draw newick trees
         prepseq: preparing steps for lastz
           raxml: raxml wrapper to construct phylogenetic trees

Run `egaz help command-name` for usage information.

# DESCRIPTION

App::Egaz is the backend of **E**asy **G**enome **A**ligner.

**Caution**: `egaz lpcnam` implement UCSC's chain-net pipeline, but some parts,
e.g. `axtChain` don't work correctly under macOS. Use `egaz lastz`'s build in
chaining mechanism (`C=2`) instead.

# INSTALLATION

    cpanm --installdeps https://github.com/wang-q/App-Egaz/archive/0.0.11.tar.gz
    curl -fsSL https://raw.githubusercontent.com/wang-q/App-Egaz/master/share/check_dep.sh | bash
    cpanm -nq https://github.com/wang-q/App-Egaz/archive/0.0.11.tar.gz
    # cpanm -nq https://github.com/wang-q/App-Egaz.git

# EXAMPLE

- Procedures of multiple genome alignments
    - Detailed/alternative steps for _Saccharomyces cerevisiae_ strains [https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md](https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md)

# AUTHOR

Qiang Wang <wang-q@outlook.com>

# LICENSE

This software is copyright (c) 2018 by Qiang Wang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.
