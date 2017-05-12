#!perl

use strict;
use warnings;

use Test::More 0.88 tests => 1;
use FindBin 0.05;
use File::Spec::Functions;
use Devel::FindPerl qw(find_perl_interpreter);
use File::Compare;

my $filename = 'example3.dot';
my $PERL     = find_perl_interpreter() || die "can't find perl!\n";
my $GRAPHER  = catfile( $FindBin::Bin, updir(), qw(bin prereq-grapher) );

system("'$PERL' '$GRAPHER' -o $filename -dot Module::Path");
ok(compare($filename, 'module-path.dot'), 'Check graph for Module::Path');
chmod(0666, $filename);
if (!unlink($filename)) {
    warn "Failed to unlink $filename: $!\n";
}
