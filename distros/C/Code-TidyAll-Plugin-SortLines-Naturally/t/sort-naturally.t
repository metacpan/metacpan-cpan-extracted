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
eel
Ed
easy
rôle
role
roles
rage
Rose
EOF

my $ct = Code::TidyAll->new(
    root_dir => $dir,
    plugins  => { 'SortLines::Naturally' => { select => $file_name }, }
);

my $output;
$output = capture_merged { $ct->process_all() };
is( $output, "[tidied]  $file_name\n", 'expected output' );
is( scalar( read_text( $full_path ) ), <<'EOF', 'sorted' );
easy
Ed
eel
rage
rôle
role
roles
Rose
EOF

done_testing();
