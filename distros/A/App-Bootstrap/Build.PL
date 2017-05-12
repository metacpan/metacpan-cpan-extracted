use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::Bootstrap',
    license             => 'perl',
    dist_author         => 'Kirrily "Skud" Robert <skud@cpan.org>',
    dist_version_from   => 'lib/App/Bootstrap.pm',
    build_requires => {
        'Test::More' => 0,
    },
    requires => {
    },
    add_to_cleanup      => [ 'App-Bootstrap-*' ],
);

print <<"END";
########################################################################
# This module has been renamed App::Install.  Go install that instead. #
########################################################################

Sleeping for 30 seconds now so you notice.  Hit Ctrl-C to quit.
END

sleep(30);

$builder->create_build_script();
