use strict;
use warnings;

use Test::Pod;

my @poddirs = qw( blib );

my @files = all_pod_files( map {  $_ } @poddirs );

all_pod_files_ok(@files);
