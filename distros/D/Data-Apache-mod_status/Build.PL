use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'Data::Apache::mod_status',
    license             => 'perl',
    dist_author         => 'Jozef Kutej <jkutej@cpan.org>',
    dist_version_from   => 'lib/Data/Apache/mod_status.pm',
    configure_requires  => { 'Module::Build' => 0.36 },
    requires => {
        'Getopt::Long'   => 0,
        'Pod::Usage'     => 0,
        'Data::Dumper'   => 0,
        'Moose'          => 0,
        'Moose::Util::TypeConstraints'
                         => 0,
        'LWP::UserAgent' => 0,
        'Carp::Clan'     => 0,
        'IPC::Run3'      => 0,
        'XML::LibXSLT'   => 0,
        'XML::LibXML'    => 0,
        'DateTime::Format::Strptime'
                         => 0,
    },
    build_requires => {
        'Test::More'        => 0,
        'Test::Differences' => 0,
        'Test::Exception'   => 0,
        'File::Slurp'       => 0,
        'File::Which'       => 0,
    },
    script_files => [
        'script/mod_status-info',
    ],
    add_to_cleanup      => [ 'Data-Apache-mod_status-*' ],
    create_readme       => 1,
);

$builder->create_build_script();
