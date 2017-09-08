#!/usr/bin/env perl
#30-08-2017

use strict;
use warnings;
use v5.11;
use Data::Dumper;
use Bio::Grid::Run::SGE;
use File::Spec::Functions;

use Path::Tiny;

job->run(
  {
    pre_task => sub {
      # if seed not set by config, generate one for this job
      if ( !job->config("seqtk_seed") ) {
        job->config( "seqtk_seed" => int( rand(1000) ) );
      }
    },

    task => sub {
      my ( $res_prefix, $data ) = @_;

      my $sample_size = job->config("seqtk_size_frac");
      my $seed        = job->config('seqtk_seed');
      my $result_dir  = job->conf("result_dir");

      my $elems = $data->{elements};

      for my $elem (@$elems) {
        my $files = $elem->{files};

        my @result_files;
        for my $file ( @{$files} ) {
          my $fname = $result_dir . '/' . path($file)->basename(qr/\.f\w+?(\.gz)?$/) . '.fastq';

          job->sys_pipe_fatal( [ 'seqtk', 'sample', '-s', $seed, $file, $sample_size ], '>', $fname );
        }
      }

      return 1;
    }
  }
);

1;
