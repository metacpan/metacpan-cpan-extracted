#!/usr/bin/env perl

use warnings;
use strict;

use Carp;
use Data::Dumper;

use Bio::Grid::Run::SGE;
use Bio::Grid::Run::SGE::Util;

run_job(
  {
    task => sub {
      my ( $c, $result_prefix, $seq_file ) = @_;

      my @cmd = qw(blastall);
      push @cmd, @{ $c->{args} };
      push @cmd, '-i', $seq_file;
      push @cmd, '-o', $result_prefix . '.blast';
      INFO "Running blastall @cmd";
      my $success = my_sys_non_fatal(@cmd);
      $success &&= my_sys_non_fatal( 'gzip', $result_prefix . '.blast' );
      return $success;
    },
    #post_task => \&Bio::Grid::Run::SGE::Util::concat_files,
  }
);

1;
