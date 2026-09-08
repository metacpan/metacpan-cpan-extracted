use v5.40;
use ExtUtils::MakeMaker;
use Alien::Build::MB 0.09;

# Alien::Build::MB loads the alienfile, folds its prereqs into Module::Build, and adds Build
# actions that probe/download/build the alien during install.
my $abmb = Alien::Build::MB->new(
    module_name    => 'Alien::Zlib',
    license        => 'artistic_2',
    dynamic_config => 1,
    name           => 'Alien-Zlib',

    # ... all the other Module::Build stuff ...
    allow_pureperl       => 0,
    test_files           => ( ( -d '.git' || $ENV{RELEASE_TESTING} ) && -d 'xt' ) ? 't/ xt/' : 't/',
    recursive_test_files => 1
);
$abmb->create_build_script;
