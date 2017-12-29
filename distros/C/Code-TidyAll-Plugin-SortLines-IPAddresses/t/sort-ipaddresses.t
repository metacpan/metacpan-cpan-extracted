#!/usr/bin/perl

use strict;
use warnings;

use utf8;
use open ':std', ':encoding(utf8)';

use Capture::Tiny qw(capture_merged);
use Code::TidyAll;
use File::Slurper qw( read_text write_text );
use File::Spec ();
use File::Temp qw( tempdir );
use Test::More;

my $file_name = 'to-sort';
my $dir       = tempdir( CLEANUP => 1 );
my $full_path = File::Spec->catfile( $dir, $file_name );

write_text( $full_path, <<'EOF');
8.8.8.8
1.1.1.1
2001:4860:4860::8888
24.24.24.24
64.147.100.106
10.10.10.10
EOF

my $ct = Code::TidyAll->new(
    root_dir => $dir,
    plugins  => { 'SortLines::IPAddresses' => { select => $file_name }, }
);

my $output;
$output = capture_merged { $ct->process_all() };
is( $output, "[tidied]  $file_name\n", 'expected output' );
is( scalar( read_text( $full_path ) ), <<'EOF', 'sorted' );
1.1.1.1
8.8.8.8
10.10.10.10
24.24.24.24
64.147.100.106
2001:4860:4860::8888
EOF

done_testing();
