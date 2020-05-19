use strict;
use warnings;

use Module::Build;

my $class = Module::Build->subclass( code => <<'EOF' );

    sub ACTION_authortest {
        my ($self) = @_;

        $self->depends_on('build');
        $self->depends_on('manifest');
        $self->depends_on('distmeta');

        $self->test_files( qw< t xt/ > );
        $self->recursive_test_files(1);

        $self->depends_on('test');

        return;
    }

    sub ACTION_distdir {
        my ($self) = @_;

        $self->depends_on('authortest');

        return $self->SUPER::ACTION_distdir();
    }
EOF

my $builder = $class->new(
    module_name         => 'CLI::Startup',
    license             => 'perl',
    dist_author         => q{Len Budney <len.budney@gmail.com>},
    dist_version_from   => 'lib/CLI/Startup.pm',

    requires => {
        'perl'            => '5.10.0',
        'Carp'            => 0,
        'Class::Std'      => '0.01',
        'Clone'           => 0,
        'Config::Any'     => 0,
        'Data::Dumper'    => 0,
        'English'         => 0,
        'Exporter'        => 0,
        'File::Basename'  => 0,
        'File::Copy'      => 0,
        'File::HomeDir'   => '0.97',
        'Getopt::Long'    => '2.38',
        'Hash::Merge'     => 0,
        'List::Util'      => 0,
        'Pod::Text'       => '3.01',
        'Readonly'        => 0,
        'Symbol'          => 0,
        'Text::CSV'       => 0,
    },

    recommends => {
        'Config::Tiny'        => 0, # To read INI configs
        'Config::INI::Writer' => 0, # To write INI configs
        'JSON::MaybeXS'       => 0, # To write JSON configs
        'YAML::Any'           => 0, # To write YAML configs
        'XML::Simple'         => 0, # To write XML configs
    },

    build_requires => {
        'Cwd'             => 0,
        'Test::More'      => 0,
        'Test::Trap'      => 0,
        'Test::Exception' => 0,

        # Shut up Test::Prereq
        'base'            => 0,
        'strict'          => 0,
        'warnings'        => 0,
    },

    configure_requires => {
        'Module::Build' => 0.33,
    },

    add_to_cleanup      => [qw{
        *.bak
        CLI-Startup-*
    }],
    create_makefile_pl => 'traditional',
);

$builder->create_build_script();
