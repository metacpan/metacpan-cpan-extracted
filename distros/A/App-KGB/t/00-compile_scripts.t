use strict;
use warnings;
use Test::More;
use Test::Compile::Internal;

my $t = Test::Compile::Internal->new( verbose => 1 );

my @scripts = $t->all_pl_files;

$t->plan( tests => scalar(@scripts) );

for my $file (@scripts) {
    $t->ok( $t->pl_file_compiles($file), "$file compiles" );
}

$t->done_testing;
