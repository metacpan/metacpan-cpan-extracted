[![Build Status](https://travis-ci.org/wang-q/App-Egaz.svg?branch=master)](https://travis-ci.org/wang-q/App-Egaz) [![Coverage Status](http://codecov.io/github/wang-q/App-Egaz/coverage.svg?branch=master)](https://codecov.io/github/wang-q/App-Egaz?branch=master) [![MetaCPAN Release](https://badge.fury.io/pl/App-Egaz.svg)](https://metacpan.org/release/App-Egaz)
# NAME

App::Egaz - **E**asy **G**enome **A**ligner

# SYNOPSIS

    egaz <command> [-?h] [long options...]
            --help (or -h)  show help
                            aka -?

    Available commands:

          commands: list the application's commands
              help: display a command's help screen

         blastlink: link sequences by blastn
        blastmatch: matched positions by blastn in genome sequences
            blastn: blastn wrapper between two fasta files
        exactmatch: exact matched positions in genome sequences
           fas2vcf: list variations in blocked fasta file
           formats: formats of files use in this project
             lastz: lastz wrapper for two genomes or self alignments
           lav2axt: convert .lav files to .axt
           lav2psl: convert .lav files to .psl
            lpcnam: the pipeline of pairwise lav-psl-chain-net-axt-maf
         maskfasta: soft/hard-masking sequences in a fasta file
            multiz: multiz step by step
         normalize: normalize lav files
         partition: partitions fasta files by size
           prepseq: preparing steps for lastz
             raxml: raxml wrapper to construct phylogenetic trees
      repeatmasker: RepeatMasker wrapper
          template: create executing bash files

Run `egaz help command-name` for usage information.

# DESCRIPTION

App::Egaz stands for **E**asy **G**enome **A**ligner.

**Caution**: `egaz lpcnam` implements UCSC's chain-net pipeline, but some parts,
e.g. `axtChain`, don't work correctly under macOS. Use `egaz lastz`'s build in
chaining mechanism (`C=2`) instead.

# INSTALLATION

    cpanm --installdeps https://github.com/wang-q/App-Egaz/archive/0.2.8.tar.gz
    curl -fsSL https://raw.githubusercontent.com/wang-q/App-Egaz/master/share/check_dep.sh | bash
    cpanm -nq https://github.com/wang-q/App-Egaz/archive/0.2.8.tar.gz
    # cpanm -nq https://github.com/wang-q/App-Egaz.git

# CONTAINER

`egaz` has tons of dependencies, so the simplest way to use it is using a container system.
`Singularity` 3.x is the preferred one.

    # Pull and build the image
    singularity pull docker://wangq/egaz:master

    # Run a single command
    singularity run egaz_master.sif egaz help

    # Interactive shell
    # Note:
    #   * .sif is immutable
    #   * $HOME, /tmp, and $PWD are automatically loaded
    #   * All actions affect the host paths
    #   * Singularity Desktop for macOS isn't Fully functional.
    #       * https://github.com/hpcng/singularity/issues/5215
    singularity shell egaz_master.sif

    # With Docker
    docker run -it --rm -v "$(pwd)"/egaz:/egaz wangq/egaz:master

# EXAMPLE

- Multiple genome alignments of _Saccharomyces cerevisiae_ strains and other _Saccharomyces_ species
    - Detailed steps [https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md#detailed-steps](https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md#detailed-steps)
    - `egaz template` steps [https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md#template-steps](https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md#template-steps)
- Self alignments of _S. cerevisiae_ reference strain S288c
    - Detailed steps [https://github.com/wang-q/App-Egaz/blob/master/doc/Scer-self.md#detailed-steps](https://github.com/wang-q/App-Egaz/blob/master/doc/Scer-self.md#detailed-steps)
    - `egaz template` steps [https://github.com/wang-q/App-Egaz/blob/master/doc/Scer-self.md#template-steps](https://github.com/wang-q/App-Egaz/blob/master/doc/Scer-self.md#template-steps)

# AUTHOR

Qiang Wang <wang-q@outlook.com>

# LICENSE

This software is copyright (c) 2018 by Qiang Wang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

# CITATION

Yan Wang\*, Xiaohui Liang\*, Yuqian Jiang, Danjiang Dong, Cong Zhang, Tianqiang Song, Ming Chen, Yong You, Han Liu, Min Ge, Haibin Dai, Fengchan Xi, Wanqing Zhou, Jian-Qun Chen, Qiang Wang#, Qihan Chen#, Wenkui Yu#.

Novel fast pathogen diagnosis method for severe pneumonia patients in the intensive care unit: randomized clinical trial.

eLife. 2022; 11: e79014.

DOI: [https://doi.org/10.7554/eLife.79014](https://doi.org/10.7554/eLife.79014)

'\*': These authors contributed equally to this work
'#': For correspondence
