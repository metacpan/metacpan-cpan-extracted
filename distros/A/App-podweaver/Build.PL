use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    module_name         => 'App::podweaver',
    license             => 'perl',
    dist_author         => q{Sam Graham <libapp-podweaver-perl@illusori.co.uk>},
    dist_version_from   => 'lib/App/podweaver.pm',
    script_files        => 'script',
    configure_requires => {
	'Module::Build'     => 0.38,
    },
    build_requires => {
        'Test::Command'     => 0.08,
        'Test::More'        => 0,
        'Test::MockObject'  => 0,
        'Test::Differences' => 0,
        #  File::Temp->newdir() requires 0.18.
        'File::Temp'        => 0.18,
        'File::Spec'        => 0,
        'File::Copy'        => 0,
        'Pod::Elemental::Selectors' => 0,
        'Pod::Elemental::Transformer::Nester' => 0,
        'Software::License::Perl_5' => 0,
    },
    requires => {
        'Config::Tiny'   => 0,
        'CPAN::Meta'     => 0,
        # 3.101632 for ability to run on documents without package declaration
        'Pod::Weaver'    => 3.101632,
        'File::HomeDir'  => 0,
        'File::Find::Rule'       => 0,
        'File::Find::Rule::Perl' => 0,
        'File::Find::Rule::VCS'  => 0,
        'File::Slurp'    => 0,
        'IO::File'       => 0,
        'Log::Any'       => 0,
        'Log::Any::Adapter' => 0,
        'Log::Any::Adapter::Dispatch' => 0,
        'Module::Metadata'   => 1.000000,
        'Pod::Elemental' => 0,
        'Pod::Elemental::Transformer::Pod5' => 0,
        'PPI::Document'  => 0,
        'Try::Tiny'      => 0,
    },
    recommends => {
        'Pod::Weaver::PluginBundle::ReplaceBoilerplate' => 0,
    },
    meta_merge => {
        'resources' => {
            'repository' => 'http://github.com/illusori/Perl-App-podweaver',
            },
        },
    add_to_cleanup      => [ 'App-podweaver-*' ],
    create_readme => 1,
    sign => 1,
    dynamic_config => 0,
);

$builder->create_build_script();
