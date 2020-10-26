package App::Dazz;
use 5.010001;
use strict;
use warnings;
use App::Cmd::Setup -app;

our $VERSION = "0.1.0";

=pod

=encoding utf-8

=head1 NAME

App::Dazz - Daligner-based UniTig utils

=head1 SYNOPSIS

    dazz <command> [-?h] [long options...]
            -? -h --help  show help

    Available commands:

       commands: list the application's commands
           help: display a command's help screen

      contained: discard contained unitigs
          cover: trusted regions in the first file covered by the second
       dazzname: rename FASTA reads for dazz_db
          group: group anchors by long reads
         layout: layout anchors within a group
          merge: merge overlapped unitigs
         orient: orient overlapped sequences to the same strand
        overlap: detect overlaps by daligner
       overlap2: detect overlaps between two (large) files by daligner
      show2ovlp: LAshow outputs to overlaps


Run C<dazz help command-name> for usage information.

=head1 DESCRIPTION

App::Dazz comprises some Daligner-based UniTig utils

=head1 INSTALLATION

    brew install brewsci/science/poa
    brew install wang-q/tap/faops
    brew install wang-q/tap/dazz_db@20201008
    brew install wang-q/tap/daligner@20201008
    brew install wang-q/tap/intspan

    cpanm --installdeps https://github.com/wang-q/App-Dazz/archive/0.1.0.tar.gz
    # cpanm --installdeps --verbose --mirror-only --mirror http://mirrors.ustc.edu.cn/CPAN/ https://github.com/wang-q/App-Dazz.git
    cpanm -nq https://github.com/wang-q/App-Dazz/archive/0.1.0.tar.gz
    # cpanm -nq https://github.com/wang-q/App-Dazz.git

=head1 AUTHOR

Qiang Wang E<lt>wang-q@outlook.comE<gt>

=head1 LICENSE

This software is copyright (c) 2017 by Qiang Wang.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;

__END__
