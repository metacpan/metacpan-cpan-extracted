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

my $readme = "$ROOT/README";
my $text   = (-f $readme) ? _slurp($readme) : '';

# Example scripts that the README should advertise.
my @eg      = grep { m{\Aeg/} } _manifest_files($ROOT);
my @eg_base = map { my $b = $_; $b =~ s{.*/}{}; $b } @eg;

plan_tests(4 + scalar(@eg_base));

ok(-f $readme, 'R1: README exists');
ok($text =~ /BATsh/,    'R2: README mentions BATsh');
ok($text =~ /\d+\.\d+/, 'R3: README mentions a version number');

# R4: README version matches BATsh.pm $VERSION
my $pm_ver = _pm_version("$ROOT/lib/BATsh.pm");
my ($readme_ver) = ($text =~ /(\d+\.\d+)/);
ok(defined $pm_ver && defined $readme_ver && $readme_ver eq $pm_ver,
   "R4: README version (${\(defined $readme_ver ? $readme_ver : 'undef')}) matches BATsh.pm (${\(defined $pm_ver ? $pm_ver : 'undef')})");

# R5..: README advertises each eg/ example by basename.
for my $b (@eg_base) {
    my $q = quotemeta($b);
    ok($text =~ /$q/, "R5: README mentions $b");
}

# Extract $VERSION from a .pm file (Perl 5.005_03 compatible).
sub _pm_version {
    my($file) = @_;
    (-f $file) or return undef;
    my $src = _slurp($file);
    if ($src =~ /\$VERSION\s*=\s*["']?([0-9._]+)["']?/) {
        return $1;
    }
    return undef;
}

END { end_testing() }
