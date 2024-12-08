package App::Egaz;

our $VERSION = "0.2.9";

use strict;
use warnings;
use App::Cmd::Setup -app;

=pod

=encoding utf-8

=head1 NAME

App::Egaz - B<E>asy B<G>enome B<A>ligner

=head1 SYNOPSIS

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

Run C<egaz help command-name> for usage information.

=head1 DESCRIPTION

App::Egaz stands for B<E>asy B<G>enome B<A>ligner.

B<Caution>: C<egaz lpcnam> implements UCSC's chain-net pipeline, but some parts,
e.g. C<axtChain>, don't work correctly under macOS. Use C<egaz lastz>'s build in
chaining mechanism (C<C=2>) instead.

=head1 INSTALLATION

    cpanm --installdeps https://github.com/wang-q/App-Egaz/archive/0.2.8.tar.gz
    curl -fsSL https://raw.githubusercontent.com/wang-q/App-Egaz/master/share/check_dep.sh | bash
    cpanm -nq https://github.com/wang-q/App-Egaz/archive/0.2.8.tar.gz
    # cpanm -nq https://github.com/wang-q/App-Egaz.git

=head1 CONTAINER

C<egaz> has tons of dependencies, so the simplest way to use it is using a container system.
C<Singularity> 3.x is the preferred one.

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

=head1 EXAMPLE

=over 4

=item Multiple genome alignments of I<Saccharomyces cerevisiae> strains and other I<Saccharomyces> species

=over 8

=item Detailed steps L<https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md#detailed-steps>

=item C<egaz template> steps L<https://github.com/wang-q/App-Egaz/blob/master/doc/Scer.md#template-steps>

=back

=item Self alignments of I<S. cerevisiae> reference strain S288c

=over 8

=item Detailed steps L<https://github.com/wang-q/App-Egaz/blob/master/doc/Scer-self.md#detailed-steps>

=item C<egaz template> steps L<https://github.com/wang-q/App-Egaz/blob/master/doc/Scer-self.md#template-steps>

=back

=back

=head1 AUTHOR

Qiang Wang E<lt>wang-q@outlook.comE<gt>

=head1 LICENSE

This software is copyright (c) 2018 by Qiang Wang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 CITATION

Yan Wang*, Xiaohui Liang*, Yuqian Jiang, Danjiang Dong, Cong Zhang, Tianqiang Song, Ming Chen, Yong You, Han Liu, Min Ge, Haibin Dai, Fengchan Xi, Wanqing Zhou, Jian-Qun Chen, Qiang Wang#, Qihan Chen#, Wenkui Yu#.

Novel fast pathogen diagnosis method for severe pneumonia patients in the intensive care unit: randomized clinical trial.

eLife. 2022; 11: e79014.

DOI: L<https://doi.org/10.7554/eLife.79014>

'*': These authors contributed equally to this work
'#': For correspondence

=cut

1;

__END__
