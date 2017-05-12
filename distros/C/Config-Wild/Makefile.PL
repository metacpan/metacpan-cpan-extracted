use inc::Module::Install;

name 'Config-Wild';
license 'gpl3';
auto_license( holder => 'Smithsonian Astrophysical Observatory' );
all_from 'lib/Config/Wild.pm';

author_tests( 'xt' );

resources(
    license => 'http://www.gnu.org/licenses/gpl-3.0.html',

    # bitbucket is the fiducial repo.  it's mirrored to github
    # 'cause that seems to be what people prefer

    #   repository => 'https://bitbucket.org/djerius/config-wild',

    # stuck at CPAN::Meta::Spec version 1.4. due to Module::Install
    repository => 'https://github.com/djerius/config-wild',
);

cpanfile;

WriteAll;
