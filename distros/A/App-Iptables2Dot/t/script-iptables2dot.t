use Test::More;

eval "use Probe::Perl";
plan skip_all => "Probe::Perl required for testing script" if $@;

use File::Spec;

use strict;

my $perl = Probe::Perl->find_perl_interpreter;
my $lib  = '-I' . File::Spec->catfile(qw/blib lib/);
my $script = File::Spec->catfile(qw/blib script iptables2dot/); 

# first check whether script runs with option -help or -man
#
is(system($perl, $lib, $script, '-help'),0, "run with -help");
is(system($perl, $lib, $script, '-man'),0, "run with -man");

# die with an unknown option
#
isnt(system($perl, $lib, $script, 't/iptables-save/unknown.txt'),0,
	"unknown option");

# add optdef for an unknown option
#
my $cmd = join(" ", $perl, $lib, $script, "--add-optdef=unknown-opt=s",
	"t/iptables-save/unknown.txt");
my $text;
if (open(my $out, '-|', $cmd)) {
	undef $/;
	$text = <$out>;
	close $out;
}
like($text, qr/FORWARD:R0:e -> LOG:name:w;$/ms, 'understand unknown option');

done_testing();
