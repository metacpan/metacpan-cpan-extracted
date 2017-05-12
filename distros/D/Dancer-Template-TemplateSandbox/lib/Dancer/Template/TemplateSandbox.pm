package Dancer::Template::TemplateSandbox;

use strict;
use warnings;
use Dancer::Config 'setting';
use Dancer::FileUtils 'path';

use base 'Dancer::Template::Abstract';

our $VERSION = '1.00';

my %_template_config;

sub init
{
    my ( $self ) = @_;

    die "Template::Sandbox is needed by Dancer::Template::TemplateSandbox"
        unless Dancer::ModuleLoader->load( 'Template::Sandbox' );

    %_template_config = (
        open_delimiter          => '<%',
        close_delimiter         => '%>',
        template_toolkit_compat => 1,
        %{$self->config},
        );

    $_template_config{ template_root } = setting( 'views' )
        if setting( 'views' );


    if( $_template_config{ cache } )
    {
        my ( $cache_type, $cache_dir );

        $cache_dir = delete $_template_config{ cache_dir }
            if $_template_config{ cache_dir };
        $cache_type = delete $_template_config{ cache_type }
            if $_template_config{ cache_type };
        $cache_type ||= 'memory';

        if( $_template_config{ cache } eq 'cache_factory' )
        {
            my ( %options );

            die "Unable to load chosen template caching module: " .
                "Cache::CacheFactory"
                unless Dancer::ModuleLoader->load( 'Cache::CacheFactory' );

            if( $cache_type eq 'file' )
            {
                %options = (
                    storage    => { 'file' => { cache_root => $cache_dir, }, },
                    );
            }
            else
            {
                %options = (
                    storage    => { $cache_type => {}, },
                    );
            }

            $_template_config{ cache } = Cache::CacheFactory->new( %options );
        }
        elsif( $_template_config{ cache } eq 'chi' )
        {
            my ( %options );

            die "Unable to load chosen template caching module: CHI"
                unless Dancer::ModuleLoader->load( 'CHI' );

            if( $cache_type eq 'file' )
            {
                %options = (
                    driver   => 'File',
                    root_dir => $cache_dir,
                    );
            }
            else
            {
                %options = (
                    driver => Dancer::ModuleLoader->class_from_setting(
                        $cache_type ),
                    );
            }

            $_template_config{ cache } = CHI->new( %options );
        }
        else
        {
            die "Unknown template caching module: $_template_config{ cache }";
        }
    }
}

sub render($$$)
{
    my ( $self, $template, $tokens ) = @_;
    my ( $ts );

    die "'$template' is not a regular file"
      if !ref($template) && (!-f $template);

    $ts = Template::Sandbox->new( %_template_config );
    $ts->add_vars( $tokens );

    if( ref( $template ) )
    {
        $ts->set_template_string( ${$template} );
    }
    else
    {
        $template =~ s~^\Q$_template_config{template_root}/\E~~
            if $_template_config{ template_root };
        $ts->set_template( $template );
    }

    my $contentref = $ts->run();
    return( $contentref ? ${$contentref} : undef );
}

1;
__END__

=pod

=head1 NAME

Dancer::Template::TemplateSandbox - Template::Sandbox wrapper for Dancer

=head1 DESCRIPTION

This class is an interface between Dancer's template engine abstraction layer
and the L<Template::Sandbox> module.

In order to use this engine, set the following setting:

    template: template_sandbox

This can be done in your config.yml file or directly in your app code with the
B<set> keyword.

Note that Dancer configures the Template::Sandbox engine to use <% %> brackets
instead of its default <: :> brackets, it also sets template_toolkit_compat
to true.

=head1 SETTINGS

You can pass additional options to the L<Template::Sandbox> constructor
from within the C<template_sandbox> subsetting of the C<engines> setting in
your config.yml:

    template: template_sandbox
    engines:
        template_sandbox:
            open_delimiter: <:
            close_delimiter: :>

=head1 CACHING

You can enable and configure caching by setting the C<cache>, C<cache_type>
and C<cache_dir> settings.

C<cache> may be one of C<'cache_factory'> or C<'chi'> to use
L<Cache::CacheFactory> or L<CHI> respectively.

C<cache_type> will set the cache type, C<'file'> and C<'memory'> should
both be fine, but other values may or may not work.

C<cache_dir> will need to be set if you set C<cache_type> to C<'file'>, but
is otherwise ignored.

    template: template_sandbox
    engines:
        template_sandbox:
            cache: cache_factory
            cache_type: file
            cache_dir: /var/tmp/cache/dancer

    template: template_sandbox
    engines:
        template_sandbox:
            cache: chi
            cache_type: memory

=head1 TEMPLATE FUNCTIONS

In keeping with L<Template::Sandbox> philosophy, no template functions
are enabled by default.

You can load them as class-wide template functions from your C<myapp.pm>:

    package myapp;
    use Dancer;

    use Template::Sandbox qw/:function_sugar/;

    Template::Sandbox->register_template_function(
        localtime => ( no_args inconstant sub { scalar localtime() } ),
        );

Or you can use template function libraries with class-level imports:

    package myapp;
    use Dancer;

    use Template::Sandbox;
    use Template::Sandbox::NumberFunctions qw/:all/;

The documentation in L<Template::Sandbox> and L<Template::Sandbox::Library>
goes into more detail on both these scenarios.

=head1 SEE ALSO

L<Dancer>, L<Template::Sandbox>, L<Cache::CacheFactory>, L<CHI>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Template::TemplateSandbox


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Template-TemplateSandbox>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Template-TemplateSandbox>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Template-TemplateSandbox>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Template-TemplateSandbox>

=back

=head1 AUTHORS

Sam Graham <libdancer-template-templatesandbox-perl BLAHBLAH illusori.co.uk>.

Based on work in L<Dancer::Template::TemplateToolkit> by Alexis Sukrieh.

=head1 COPYRIGHT & LICENSE

Copyright 2010 Sam Graham, all rights reserved.
Portions derived from work copright Alexis Sukrieh.

This library is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
