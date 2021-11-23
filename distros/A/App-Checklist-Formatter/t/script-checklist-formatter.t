use strict;
use File::Spec;
use Probe::Perl;
use Test::More;

plan tests => 2;

my @scriptcall = qw(perl -Iblib/lib blib/script/checklist-formatter);

my $perl = Probe::Perl->find_perl_interpreter;
my $script = File::Spec->catfile(qw/blib script checklist-formatter/); 

# first check whether script with option -help or -man runs
#
is(system($perl, $script, '-help'),0, "run with -help");
is(system($perl, $script, '-man'),0, "run with -man");

