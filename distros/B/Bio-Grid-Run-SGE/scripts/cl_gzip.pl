#!/usr/bin/env perl

use warnings;
use strict;
use 5.010;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Master;
use Bio::Grid::Run::SGE::Util qw/result_files my_sys_non_fatal INFO MSG expand_path/;
use File::Spec::Functions qw(catfile);

run_job(
  {
    task => sub {
      my ( $c, $result_prefix, $in_files ) = @_;
      my $success = 1;
      for my $in_file (@$in_files) {
        my @cmd = ( 'gzip', $in_file );
        $success &&= my_sys_non_fatal(@cmd);
      }

      return $success;
    },
    usage => \&usage,
  }

);

sub usage {
  return <<EOF;
The script takes an filelist index and gzips all files

EXAMPLE CONFIG:
   ---
   input:
   - format: FileList
     files: [ 'filea', 'fileb', 'filec' ]
   job_name: gzip
   mode: Consecutive

   test: 1

   result_dir: .
   working_dir: .

   prefix_output_dirs: 1
EOF

}
1;
