use Test::More;

eval "use Probe::Perl";
plan skip_all => "Probe::Perl required for testing script" if $@;

use File::Spec;

use strict;

my ($cmd,$text);

my $perl = Probe::Perl->find_perl_interpreter;
my $lib  = '-I' . File::Spec->catfile(qw/blib lib/);
my $script = File::Spec->catfile(qw/blib script create_cloginrc/); 

# first check whether script runs with option -help or -man
#
is(system($perl, $lib, $script, '-help'),0, "run with -help");
is(system($perl, $lib, $script, '-man'),0, "run with -man");

$cmd = join(" ", $perl, $lib, $script, "--templatefile=t/template/fix.tmpl",
        "t/csv/fix.csv");
if (open(my $out, '-|', $cmd)) {
        undef $/;
        $text = <$out>;
        close $out;
}
is($text,"Fix Template\n","use fix.tmpl");

$cmd = join(" ", $perl, $lib, $script, "--templatefile=t/template/escape.tmpl",
        "t/csv/escape.csv");
if (open(my $out, '-|', $cmd)) {
        undef $/;
        $text = <$out>;
        close $out;
}
is($text,"escaped {a\\\{\\ \\}\\\&\\\\} (rancid)\n","use fix.tmpl");

$cmd = join(" ", $perl, $lib, $script, "--templatefile=t/template/catch-all.tmpl",
        "t/csv/catch-all.csv");
if (open(my $out, '-|', $cmd)) {
        undef $/;
        $text = <$out>;
        close $out;
}
is($text,"n1's type (known) is known.\nn2's type (unknown) has no template.\n",
	"unknown type");

$cmd = join(" ", $perl, $lib, $script, "--templatefile=t/template/name-text.tmpl",
        "--columns=name,type,text", "t/csv/without-columns.csv");
if (open(my $out, '-|', $cmd)) {
        undef $/;
        $text = <$out>;
        close $out;
}
is($text,"l1 is a letter containing 'Dear prudence...'\n","use --columns");

done_testing();
