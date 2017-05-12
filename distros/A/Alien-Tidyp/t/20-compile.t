#!perl

use strict;
use warnings;
use Test::More;

use Test::More tests => 2;
use Alien::Tidyp;
use File::Temp qw(tempdir tempfile);
use ExtUtils::CBuilder;
use ExtUtils::Liblist;
use Config;

my $cb = ExtUtils::CBuilder->new(quiet => 0);

my $dir = tempdir( CLEANUP => 1 );
my ($fs, $src) = tempfile( DIR => $dir, SUFFIX => '.c' );
syswrite($fs, <<MARKER); # write test source code
#include <tidyp.h>
int main() { tidyVersion(); return 0; }

MARKER
close($fs);

my $i = Alien::Tidyp->config('INC');
my $l = Alien::Tidyp->config('LIBS');
$l = ExtUtils::Liblist->ext($l) if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/); # MSVC compiler hack

my $obj = $cb->compile( source => $src, extra_compiler_flags => $i );
isnt( $obj, undef, 'Testing compilation' );

my $exe = $cb->link_executable( objects => $obj, extra_linker_flags => $l );
isnt( $exe, undef, 'Testing linking' );
