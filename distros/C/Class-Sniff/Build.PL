use strict;
use warnings;
use Module::Build;
use 5.006;

my $builder = Module::Build->new(
    module_name       => 'Class::Sniff',
    license           => 'perl',
    dist_author       => 'Curtis "Ovid" Poe <ovid@cpan.org>',
    dist_version_from => 'lib/Class/Sniff.pm',
    requires          => {
        'B::Concise'        => 0.66,
        'Devel::Symdump'    => 2.08,
        'Digest::MD5'       => 2.36,
        'File::Find::Rule'  => 0.30,
        'Graph::Easy'       => 0.64,
        'List::MoreUtils'   => 0.22,
        'Sub::Identify'     => 0.03,
        'Text::SimpleTable' => 0.05,
        'perl'              => 5.006,
    },
    build_requires     => { 'Test::Most' => 0.20, },
    add_to_cleanup     => ['Class-Sniff-*'],
    create_makefile_pl => 'traditional',
);

if ( $builder->prompt( "Do you wish to install the 'csniff' utility?", "y" ) =~
    /^[Yy]/ )
{
    $builder->script_files( ["bin/csniff"] );
}

$builder->create_build_script();
