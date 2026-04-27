######################################################################
#
# 9060-readme.t  README checks
#
# COMPATIBILITY: Perl 5.005_03 and later
#
######################################################################
use strict;
BEGIN { if ($] < 5.006 && !defined(&warnings::import)) {
        $INC{'warnings.pm'} = 'stub'; eval 'package warnings; sub import {}' } }
use warnings; local $^W = 1;
BEGIN { pop @INC if $INC[-1] eq '.' }
use FindBin ();
use lib "$FindBin::Bin/lib";
use File::Spec ();
use INA_CPAN_Check;

my $ROOT = File::Spec->rel2abs(
    File::Spec->catdir($FindBin::RealBin, File::Spec->updir));

plan_tests(4);

my $readme = "$ROOT/README";
ok(-f $readme, 'R1: README exists');
my $text = _slurp($readme);
ok($text =~ /BATsh/,    'R2: README mentions BATsh');
ok($text =~ /\d+\.\d+/, 'R3: README mentions a version number');

# R4: README version matches BATsh.pm $VERSION
my $pm_ver = _pm_version("$ROOT/lib/BATsh.pm");
my ($readme_ver) = ($text =~ /(\d+\.\d+)/);
ok(defined $pm_ver && defined $readme_ver && $readme_ver eq $pm_ver,
   "R4: README version (${\(defined $readme_ver ? $readme_ver : 'undef')}) matches BATsh.pm (${\(defined $pm_ver ? $pm_ver : 'undef')})");

END { end_testing() }
