use strict;
use warnings;
no warnings qw(qw); # suppress warnings about commas in text

use CPAN::FindDependencies qw(finddeps);

use Test::More;
use Test::Differences;

use Devel::CheckOS;
use Capture::Tiny qw(capture);
use Config;

# First, make sure that what we're about to test using the script works
# when using the module directly
{
    local $SIG{__WARN__} = sub { my @w = grep { $_ !~ /no metadata/ } @_; warn(@w) if(@w) };
    eq_or_diff(
        {
         map {
             $_->name() => [$_->depth(), $_->distribution(), $_->warning() ? 1 : 0]
           }
           finddeps(
               'Tie::Scalar::Decay',
               mirror   => 'DEFAULT,t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz',
               cachedir => 't/cache/Tie-Scalar-Decay-1.1.1',
           )
        },
        {
                'Tie::Scalar::Decay' => [0, 'D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz', 1]
        },
        "Fetching directly from the library works"
    );
}

SKIP: {
    skip "Script works but tests don't on Windows.  Dunno why.", 1
        if(Devel::CheckOS::os_is('MicrosoftWindows'));

my($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        help
    )
)};
$stderr =~ s/stty: stdin isn't a terminal\s//;
is($stderr, '', "... no unexpected whining on STDERR");
like($stdout, qr/cpandeps.*perl.*5.8.8.*CPAN::FindDependencies/, "Can spew out some help");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        Tie::Scalar::Decay
        mirror DEFAULT,t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
    )
)};
$stderr = join("\n", grep { $_ !~ / ^ Devel::Hide.*Test.Pod /x } split(/[\r\n]+/, $stderr));
eq_or_diff($stderr, '', "no errors reported");
eq_or_diff($stdout, "*Tie::Scalar::Decay (dist: D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)\n",
    "got Tie::Scalar::Decay right not using Makefile.PL");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        Tie::Scalar::Decay
        --mirror DEFAULT,t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
        --showmoduleversions
        usemakefilepl 1
    )
)};
is($stderr, '', "... no whining on STDERR");
eq_or_diff($stdout, 'Tie::Scalar::Decay (dist: D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)
  Time::HiRes (dist: J/JH/JHI/Time-HiRes-1.9719.tar.gz, mod ver: 1.2)
', "got Tie::Scalar::Decay right using Makefile.PL and --showmoduleversions (and cope with other --args too)");

# same as previous test, but with args in different order
# see https://github.com/DrHyde/perl-modules-CPAN-FindDependencies/issues/13
($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        --mirror DEFAULT,t/cache/Tie-Scalar-Decay-1.1.1/02packages.details.txt.gz
        cachedir t/cache/Tie-Scalar-Decay-1.1.1
        --showmoduleversions
        usemakefilepl 1
        Tie::Scalar::Decay
    )
)};
is($stderr, '', "... no whining on STDERR");
eq_or_diff($stdout, 'Tie::Scalar::Decay (dist: D/DC/DCANTRELL/Tie-Scalar-Decay-1.1.1.tar.gz)
  Time::HiRes (dist: J/JH/JHI/Time-HiRes-1.9719.tar.gz, mod ver: 1.2)
', "same again, but with args in different order");

($stdout, $stderr) = capture { system(
    $Config{perlpath}, (map { "-I$_" } (@INC)),
    qw(
        blib/script/cpandeps
        CPAN::FindDependencies
        cachedir t/cache/CPAN-FindDependencies-1.1/
        mirror DEFAULT,t/cache/CPAN-FindDependencies-1.1/02packages.details.txt.gz
    )
)};
is($stderr, '', "... no whining on STDERR");
eq_or_diff($stdout, 'CPAN::FindDependencies (dist: D/DC/DCANTRELL/CPAN-FindDependencies-1.1.tar.gz)
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


if($ENV{AUTHOR_TESTING}) {
    # Eeuuww, string-system. We need to invoke a shell with a lower ulimit.
    # And it's author-testing because ulimit isn't sufficiently portable.
    my($stdout, $stderr) = capture { system(qq{
        ulimit -n 20;
        bash -c "$Config{perlpath} }.join(' ', (map { "-I$_" } (@INC))).
        q{ blib/script/cpandeps CPAN::FindDependencies --perl 5.30.2" }
    ) };
    unlike($stdout, qr/\*/, "even with a low ulimit we don't get warnings about not being able to retrieve deps");
}

};

done_testing;
