#!/usr/bin/env perl

use warnings;
use strict;

use Carp;
use Data::Dumper;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Util qw/expand_path/;
use File::Spec::Functions qw(catfile);

run_job(
    {
        task => sub {
            my ( $c, $result_prefix, $seq_file ) = @_;

            my @cmd = qw(/state/partition1/iprscan/bin/iprscan -cli);
            push @cmd, @{ $c->{args} };
            #-appl hmmpfam -appl hmmsmart -format xml);
            push @cmd, '-seqtype', $c->{extra}{seqtype};
            push @cmd, '-i',       $seq_file;
            push @cmd, '-o',       $result_prefix . '.ipr';
            job->log->info("Running iprscan: @cmd");
            return job->sys(@cmd);
        },
        post_task => \&Bio::Grid::Run::SGE::Util::concat_files,
    }
);

1;

=head1 NAME

cl_iprscan.pl - clusterscript to run interpro scans

=head1 SYNOPSIS

cl_iprscan.pl my.config.pl

=head1 OPTIONS

=over 4

=item seqtype

C<p> for proteins.

=back

=cut
