#!/usr/bin/env perl

use warnings;
use strict;
use Storable qw/nstore retrieve/;
use File::Temp qw/tempdir/;
use File::Spec;
use Config::Auto;
use Data::Dumper;
use Bio::Grid::Run::SGE::Index;
use Bio::Grid::Run::SGE::Iterator;
use Bio::Grid::Run::SGE::Util qw/my_glob expand_path my_mkdir expand_path_rel/;
use Cwd;
use Clone qw/clone/;
use Data::Printer colored => 1, use_prototypes => 0, rc_file => '';
use Bio::Gonzales::Util::Cerial;

use Config;
use Mtest;

my $c = {
  'node_degree_file' => '/home/bargs001/bmrf/ath-osa_combi1_ipr_argotseed5nocv/conf/../node_degrees.txt',
  'cmd'              => [ '/home/bargs001/bmrf/bin/cl_cv.pl' ],
  'no_prompt'        => undef,
  'input'            => [
    {
      'elements' => [
        -1,   1,    2,    3,    4,    5,    6,    7,    8,    9,    10,   11,   12,   13,
        14,   16,   17,   18,   19,   21,   23,   24,   26,   29,   31,   33,   36,   39,
        42,   45,   49,   52,   57,   61,   66,   71,   77,   83,   89,   96,   104,  112,
        121,  131,  141,  152,  164,  177,  191,  206,  223,  240,  259,  280,  302,  326,
        351,  379,  409,  441,  476,  514,  555,  599,  646,  697,  752,  812,  876,  945,
        1020, 1100, 1187, 1281, 1383, 1492, 1610, 1737, 1874, 2023, 2183, 2355, 2541, 2742,
        2959, 3193, 3446, 3718, 4012, 4330, 4672, 5041, 5440, 5870, 6334, 6835, 7376, 7959,
        8588, 9267, 10000
      ],
      'format' => 'List'
    }
  ],
  'go_file'     => '/home/bargs001/bmrf/ath-osa_combi1_ipr_argotseed5nocv/conf/../go.in',
  'net_file'    => '/home/bargs001/bmrf/ath-osa_combi1_ipr_argotseed5nocv/conf/../net.netint.combi.combi',
  'working_dir' => '..',
  'clust_file'  => '/home/bargs001/bmrf/ath-osa_combi1_ipr_argotseed5nocv/conf/../ipr.combi',
  'job_name'    => 'bmrf_cv',
  'method'      => 'Consecutive'
};

my $m = Mtest->new($c);
