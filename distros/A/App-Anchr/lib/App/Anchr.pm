package App::Anchr;
use 5.010001;
use strict;
use warnings;
use App::Cmd::Setup -app;

our $VERSION = "0.4.3";

=pod

=encoding utf-8

=head1 NAME

App::Anchr - B<A>ssembler of B<N>-free B<CHR>omosomes

=head1 SYNOPSIS

    anchr <command> [-?h] [long options...]
            -? -h --help  show help

    Available commands:

       commands: list the application's commands
           help: display a command's help screen

        anchors: selete anchors from k-unitigs or superreads
          break: break long reads by anthors
      contained: discard contained super-reads, k-unitigs, or anchors
          cover: trusted regions in the first file covered by the second
       dazzname: rename FASTA reads for dazz_db
            dep: check or install dependances
          group: group anthors by long reads
       kunitigs: create k-unitigs from corrected reads
         layout: layout anthor group
          merge: merge overlapped super-reads, k-unitigs, or anchors
         orient: orient overlapped sequences to the same strand
        overlap: detect overlaps by daligner
       overlap2: detect overlaps between two (large) files by daligner
         quorum: Run quorum to discard bad reads
        replace: replace IDs in .ovlp.tsv
       restrict: restrict overlaps to known pairs
       scaffold: scaffold anchors (k-unitigs/contigs) using paired-end reads
      show2ovlp: LAshow outputs to ovelaps
           trim: trim PE Illumina fastq files

Run C<anchr help command-name> for usage information.

=head1 DESCRIPTION

App::Anchr is tend to be an Assembler of N-free CHRomosomes.

=head1 INSTALLATION

    cpanm --installdeps https://github.com/wang-q/App-Anchr/archive/0.3.2.tar.gz
    curl -fsSL https://raw.githubusercontent.com/wang-q/App-Anchr/master/share/install_dep.sh | bash
    curl -fsSL https://raw.githubusercontent.com/wang-q/App-Anchr/master/share/check_dep.sh | bash
    cpanm -nq https://github.com/wang-q/App-Anchr/archive/0.3.2.tar.gz
    # cpanm -nq https://github.com/wang-q/App-Anchr.git

=head1 AUTHOR

Qiang Wang E<lt>wang-q@outlook.comE<gt>

=head1 LICENSE

This software is copyright (c) 2017 by Qiang Wang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__
