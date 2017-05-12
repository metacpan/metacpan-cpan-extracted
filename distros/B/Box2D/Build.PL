use strict;
use warnings;
use Alien::Box2D;
use Module::Build::WithXSpp;

push @INC, "build";

my $builder = Module::Build::WithXSpp->new(
    module_name         => 'Box2D',
    dist_abstract       => '2D Physics Library',
    license             => 'perl',
    dist_author         => q{Kartik Thakore <kthakore@CPAN.org>},
    dist_version_from   => 'lib/Box2D.pm',
    configure_requires => {
        'Module::Build' => 0.38,
        'Alien::Box2D' => 0.103,
    },
    build_requires => {
        'Test::More'     => 0,
        'Alien::Box2D'   => 0.103,
        'ExtUtils::XSpp' => 0.14,
	    'ExtUtils::Typemap::ObjectMap'   => '0',
        'ExtUtils::Typemap::STL::String' => '0',
        'ExtUtils::Typemap::Basic'       => '0',
    },
    add_to_cleanup      => [ 'Box2D-*' ],
    extra_typemap_modules => {
        'ExtUtils::Typemap::ObjectMap'   => '0',
        'ExtUtils::Typemap::STL::String' => '0.04',
        'ExtUtils::Typemap::Basic'       => '0.04',
    },
    extra_compiler_flags => [ Alien::Box2D->config('cflags') ],
    extra_linker_flags   => [ Alien::Box2D->config('libs') ],
    meta_merge => {
        resources => {
            bugtracker => 'https://github.com/PerlGameDev/Box2D-perl/issues',
            repository => 'https://github.com/PerlGameDev/Box2D-perl'
        }
    },
);

# early_includes will be included right before perl.h in main.xs
$builder->early_includes( [ qw( "sys/vnode.h" ) ] ) if $^O eq 'solaris';

$builder->create_build_script();
