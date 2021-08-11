use Test::More;

eval "use Probe::Perl";
plan skip_all => "Probe::Perl required for testing script" if $@;

use File::Spec;

use strict;

my $perl = Probe::Perl->find_perl_interpreter;
my $lib  = '-I' . File::Spec->catfile(qw/blib lib/);
my $script = File::Spec->catfile(qw/blib script create_cloginrc/); 

# first check whether script runs with option -help or -man
#
is(system($perl, $lib, $script, '-help'),0, "run with -help");
is(system($perl, $lib, $script, '-man'),0, "run with -man");

my $cmd = join(" ", $perl, $lib, $script, "--templatefile=t/template/fix.tmpl",
        "t/csv/fix.csv");
my $text;
if (open(my $out, '-|', $cmd)) {
        undef $/;
        $text = <$out>;
        close $out;
}
is($text,"Fix Template\n","use fix.tmpl");

my $cmd = join(" ", $perl, $lib, $script, "--templatefile=t/template/escape.tmpl",
        "t/csv/escape.csv");
my $text;
if (open(my $out, '-|', $cmd)) {
        undef $/;
        $text = <$out>;
        close $out;
}
is($text,"escaped {a\\\{\\ \\}\\\&\\\\} (rancid)\n","use fix.tmpl");

done_testing();
