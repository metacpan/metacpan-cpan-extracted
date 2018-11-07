#!perl -w
use strict;

use Test::More;
plan tests => 4;

use Devel::CheckOS;
use Capture::Tiny qw(capture);
use Config;

SKIP: {
    skip "Script works but tests don't on Windows.  Dunno why.", 4
        if(Devel::CheckOS::os_is('MicrosoftWindows'));

my($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        Tie::Scalar::Decay
        02packages t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
    )
)};

# filter out nonsense like
#   Subroutine File::Slurp::O_RDWR redefined at .../File/Slurp.pm line 11.
#   Subroutine File::Slurp::O_CREAT redefined at .../File/Slurp.pm line 11.
#   Subroutine File::Slurp::O_EXCL redefined at .../File/Slurp.pm line 11.
# from something in the dependency tree that only seems to affect 5.8, and
#   v-string in use/require non-portable at .../File/Slurp.pm line 3
# in 5.10.0

$stderr = join("\n", grep {
    $_ !~ /
        ^
        (
            (
                Subroutine.File::Slurp::O_(RDWR|CREAT|EXCL).redefined |
                v-string.in.use\/require.non-portable
            )
            .*File\/Slurp.pm
        ) |
        Devel::Hide.*Test.Pod
    /x
} split(/[\r\n]+/, $stderr));

# in case we're deliberately turning this off ...
$stderr =~ s{Devel::Hide hides LWP/Protocol/https.pm}{};

is_deeply($stderr, '', "no errors reported");
is_deeply($stdout, "*Tie::Scalar::Decay (dist: D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)\n",
    "got Tie::Scalar::Decay right not using Makefile.PL");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        --showmoduleversions
        Tie::Scalar::Decay
        02packages t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
        usemakefilepl 1
    )
)};
is_deeply($stdout, 'Tie::Scalar::Decay (dist: D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)
  Time::HiRes (dist: J/JH/JHI/Time-HiRes-1.9719.tar.gz, mod ver: 1.2)
', "got Tie::Scalar::Decay right using Makefile.PL and --showmoduleversions");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        CPAN::FindDependencies
        02packages t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz
        cachedir t/cache/CPAN-FindDependencies-1.1/
    )
)};
is_deeply($stdout, 'CPAN::FindDependencies (dist: D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz)
  CPAN (dist: A/AN/ANDK/CPAN-1.9205.tar.gz)
    File::Temp (dist: T/TJ/TJENNESS/File-Temp-0.19.tar.gz)
      File::Spec (dist: K/KW/KWILLIAMS/PathTools-3.25.tar.gz)
        ExtUtils::CBuilder (dist: K/KW/KWILLIAMS/ExtUtils-CBuilder-0.21.tar.gz)
        Module::Build (dist: K/KW/KWILLIAMS/Module-Build-0.2808.tar.gz)
        Scalar::Util (dist: G/GB/GBARR/Scalar-List-Utils-1.19.tar.gz)
      Test::More (dist: M/MS/MSCHWERN/Test-Simple-0.72.tar.gz)
        Test::Harness (dist: A/AN/ANDYA/Test-Harness-3.03.tar.gz)
  *LWP::UserAgent (dist: G/GA/GAAS/libwww-perl-5.808.tar.gz)
  YAML (dist: I/IN/INGY/YAML-0.66.tar.gz)
', "got CPAN::FindDependencies right");

};
