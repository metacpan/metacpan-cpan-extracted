use strict;
use File::Spec;
use Probe::Perl;
use Test::More;

my $perl = Probe::Perl->find_perl_interpreter;
my $lib  = '-I' . File::Spec->catfile(qw/blib lib/);
my $script = File::Spec->catfile(qw/blib script make-epub/); 

# first check whether script runs with option -help or -man
#
is(system($perl, $lib, $script, '-help'),0, "run with -help");
is(system($perl, $lib, $script, '-man'),0, "run with -man");

done_testing()
