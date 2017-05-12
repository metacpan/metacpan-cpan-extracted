use 5.006;  # read the CAVEATS if you really want a version that works on 5.5
use strict;
use warnings;
use Module::Build;


my @more_prereqs = ();
push @more_prereqs, "IO::String" => 0 if $] < 5.008;

my $builder = Module::Build->new(
    module_name         => 'Config::Extend::MySQL',
    license             => 'perl',
    dist_author         => 'Sebastien Aperghis-Tramoni <sebastien@aperghis.net>',
    dist_version_from   => 'lib/Config/Extend/MySQL.pm',
    requires => {
        'perl'                  => '5.006',
        'Carp'                  => '0',
        'Config::Tiny'          => '0',
        'File::Basename'        => '0',
        'File::Read'            => '0',
        'File::Spec::Functions' => '0',
        'UNIVERSAL::require'    => '0',
        @more_prereqs,
    },
    build_requires => {
        'Test::More'        => 0,
    },
    add_to_cleanup      => [ 'Config-Extend-MySQL-*' ],
);

$builder->create_build_script();
