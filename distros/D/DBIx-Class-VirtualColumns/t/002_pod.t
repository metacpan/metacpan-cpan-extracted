# -*- perl -*-

# t/002_pod.t - check pod

use Test::Pod tests => 1;

pod_file_ok( "lib/DBIx/Class/VirtualColumns.pm", "Valid POD file" );