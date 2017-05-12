#!/usr/bin/perl -w

use strict;
use warnings;
use Module::Build;

#  This subclassing adds the following build commands:
#    testrelease - runs the release tests in xt/release
#    testall     - runs the tests both in t and xt (recursively)
#  It also customises the "test" command so that it also runs the
#  release tests if either the RELEASE_TESTING or AUTOMATED_TESTING
#  environment variables are set, in line with what appears to be
#  the current consensus "best-practice" as of Feb 2010.
#
#  All xt tests are assumed to do their own requirements checking
#  and to gracefully skip their tests if the requirements are not
#  available: under no circumstances should they add requirements
#  to the end-user build or install processes.

my $class = Module::Build->subclass(
    class => 'Module::Build::SGRAHAM',
    code  => <<'END_OF_CODE',
sub ACTION_test
{
    my ( $self ) = @_;

    if( $ENV{ RELEASE_TESTING } or $ENV{ AUTOMATED_TESTING } )
    {
        #  Checking $self->{ properties } breaks the black-box but
        #  won't clobber use of --test_files args.
        #  Can't call $self->test_files() to find if any were manually
        #  supplied, because that autoexpands the default setting.
        $self->test_files( 't', 'xt/release' )
            unless $self->{ properties }->{ test_files };
    }
    return $self->SUPER::ACTION_test();
}

sub ACTION_testrelease
{
    my ( $self ) = @_;

    $self->depends_on( 'build' );
    local $ENV{ RELEASE_TESTING } = 1;
    $self->test_files( qw( xt/release ) );
    $self->depends_on( 'test' );
}

sub ACTION_testall
{
    my ( $self ) = @_;

    $self->depends_on( 'build' );
    $self->test_files( qw( t xt ) );
    $self->recursive_test_files( 1 );
    $self->depends_on( 'test' );
}

sub ACTION_distdir
{
    my ( $self ) = @_;

    $self->depends_on( 'testrelease' );

    return( $self->SUPER::ACTION_distdir() );
}
END_OF_CODE
    );

my $builder = $class->new(
    module_name         => 'Dancer::Template::TemplateSandbox',
    license             => 'perl',
    dist_author         => q{Sam Graham <libdancer-template-templatesandbox-perl@illusori.co.uk>},
    dist_version_from   => 'lib/Dancer/Template/TemplateSandbox.pm',
    configure_requires => {
        'Module::Build'    => 0.23,
    },
    build_requires => {
        'Test::More'       => 0,
    },
    requires => {
        #  template_toolkit_compat support first introduced in 1.03.
        'Template::Sandbox' => '1.03',
        'Dancer'            => 0,
    },
    sign => 1,
    dynamic_config => 0,
);

$builder->create_build_script();
