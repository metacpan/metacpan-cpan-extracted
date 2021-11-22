# vim: set ts=4 sw=4 tw=78 et si:
use 5.006;
use strict;
use warnings;
use Module::Build;

my $builder = Module::Build->new(
    add_to_cleanup      => [ 'Algorithm-CheckDigits-*' ],
    build_requires      => {
        'Probe::Perl'   => 0,
        'Test::More'    => 0,
        'Pod::Usage'    => 1.30,
    },
    configure_requires  => { 'Module::Build' => 0.38 },
    create_makefile_pl  => 'small',
    dist_author         => 'Mathias Weidner <mamawe@cpan.org>',
    dist_version_from   => 'lib/Algorithm/CheckDigits.pm',
    license             => 'perl',
    module_name         => 'Algorithm::CheckDigits',
    requires            => { 
        # Perl 5.10.1 includes "configure_requires" support
        #             (see: Module::Build::Compat)
        'perl'          => '5.10.1',
    	'version'       => 0,
    },
    meta_merge => {
        resources => {
            repository => 'https://github.com/matwei-perl/Algorithm-CheckDigits',
            bugtracker => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Algorithm-CheckDigits',
        }
    },
    script_files        => [
        'bin/checkdigits.pl',
    ],
);

$builder->create_build_script();
