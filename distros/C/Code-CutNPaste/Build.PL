use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name       => 'Code::CutNPaste',
    license           => 'perl',
    dist_author       => q{Curtis "Ovid" Poe <ovid@cpan.org>},
    dist_version_from => 'lib/Code/CutNPaste.pm',
    build_requires    => {
        'Test::Most' => '0.25',
    },
    requires => {
        'Capture::Tiny'         => '0.17',
        'File::Find::Rule'      => '0.33',
        'File::HomeDir'         => 0,
        'File::Slurp'           => '9999.19',
        'Moo'                   => 0,
        'Parallel::ForkManager' => '0.007009',
        'Term::ProgressBar'     => 0,
        'aliased'               => 0,
        'autodie'               => '2.10',
        'perl'                  => 5.006,
        'utf8::all'             => '0.004',
    },
    configure_requires => { 'Module::Build' => 0.4 },
    meta_merge => {
        resources =>
          { repository => 'https://github.com/Ovid/code-cutnpaste', },
    },
    add_to_cleanup     => ['Code-CutNPaste-*'],
    create_makefile_pl => 'traditional',
);

if ($builder->prompt(
        "Do you wish to install the 'find_duplicate_perl' utility?", "y"
    ) =~ /^[Yy]/
  )
{
    $builder->script_files( ["bin/find_duplicate_perl"] );
}

$builder->create_build_script();
