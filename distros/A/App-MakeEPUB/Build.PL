use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'App-MakeEPUB-*' ],
    build_requires      => {
        'Probe::Perl'   => 0,
        'Test::More'    => 0,
    },
    configure_requires  => { 'Module::Build' => 0.38 },
    create_makefile_pl  => 'small',
    dist_abstract       => 'Create an EPUB ebook',
    dist_author         => 'Mathias Weidner <mamawe@cpan.org>',
    dist_version_from   => 'lib/App/MakeEPUB.pm',
    license             => 'perl',
    module_name         => 'App::MakeEPUB',
    requires => {
	# Perl 5.10.1 includes "configure_requires" support
	#             (see: Module::Build::Compat)
	'perl'		    => '5.10.1',
        'version'	    => 0,
	'Archive::Zip'	    => 0,
	'File::Basename'    => 0,
	'File::Find'	    => 0,
	'File::Path'	    => 0,
	'File::Spec'	    => 0,
	'HTML::TreeBuilder' => 0,
    },
    script_files        => [ 'bin/make-epub' ],
);

$builder->create_build_script();
