#!/usr/bin/env perl

use warnings;
use strict;

use Carp;

use Bio::Grid::Run::SGE;

run_job(
    {
        config => {
            idx_format => 'General',
            record_sep => '^\s+\d+\s+\d+$',
        },
        task => sub {
            my ( $c, $result_file, $seq_file ) = @_;

            my $cmd = join " ", ("$ENV{HOME}/usr/bin/phyml", '--quiet', @{$c->{extra}{cmd_opts}}, "-i $seq_file", "--datatype $c->{extra}{type}");

            INFO "Running phyml $cmd";

            my $success = my_sys_non_fatal($cmd);

            my $phyml_result_file_prefix = "${seq_file}_phyml_";
            for my $f ( glob("${phyml_result_file_prefix}*") ) {
                next unless ( -f $f );
                ( my $result_file = $f ) =~ s/^\Q$phyml_result_file_prefix\E//;
                $result_file = $result_prefix . "." . $result_file;
                INFO "Renaming $f -> $result_file";
                rename $f, $result_file;
            }
            return $success;
        }

    }
);

