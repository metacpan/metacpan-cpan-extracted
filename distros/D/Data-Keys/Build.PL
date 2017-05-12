use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Data::Keys',
    license           => 'perl',
    dist_author       => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from => 'lib/Data/Keys.pm',
    
    configure_requires => {'Module::Build' => 0.36},
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'Test::NoMalware'   => 0,
        'File::Temp'        => 0,
        'JSON::Util'        => 0,
    },
    requires => {
        'Moose'        => 0,
        'Moose::Util'  => 0,
        'Digest::SHA1' => 0,
        'Carp::Clan'   => 0,
        'IO::Any'      => 0,
        'List::MoreUtils' => 0,
    },
    script_files => [
    ],
    add_to_cleanup => [ 'Data-Keys-*' ],
    create_readme  => 1,
    meta_merge => {
        resources => {
            repository => 'git://github.com/jozef/Data-Keys.git',
            bugtracker => 'http://github.com/jozef/Data-Keys/issues',
        },
        keywords => [ qw/ key value file store / ],
    },
);

$builder->create_build_script();
