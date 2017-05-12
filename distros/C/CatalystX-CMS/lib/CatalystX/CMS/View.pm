package CatalystX::CMS::View;
use strict;
use warnings;
use base qw( Catalyst::View::TT );
use CatalystX::CMS;
use MRO::Compat;
use mro 'c3';
use Carp;
use Data::Dump qw( dump );
use Path::Class;
use Class::Inspector;
use Template::Plugin::Handy 'install';
use Scalar::Util qw( blessed );

our $VERSION = '0.011';

my $DEBUG = 0;

__PACKAGE__->config(
    WRAPPER => 'cms/wrapper.tt',

    # turn .tt caching off so that we force read on every req.
    # with caching on (default) occasional errors if the
    # .tt is saved to disk and then immediately requested,
    # because the cached version is being read instead of from disk.
    CACHE_SIZE => 0,
);

__PACKAGE__->mk_accessors(qw( cms_template_base ));

=head1 NAME

CatalystX::CMS::View - base View class

=head1 SYNOPSIS

 package MyApp::View::CMS;
 use strict;
 use base qw( CatalystX::CMS::View );
 1;
 
=head1 DESCRIPTION

CatalystX::CMS::View isa Catalyst::View::TT class that handles
dynamic include path generation and other CMS-related features.

=head1 VIRTUAL METHODS

CatalystX::CMS::View uses the Template::Plugin::Handy module to install
additional vmethods in the global Template namespace.
 
=head1 METHODS

Only new or overridden method are documented here.

=cut

=head2 new

Overrides new() method to set INCLUDE_PATH to include
all the paths in main app cms B<root> config.

=cut

sub new {
    my ( $class, $c, $arg ) = @_;

    my $template_base = Class::Inspector->loaded_filename('CatalystX::CMS');
    $template_base =~ s/\.pm$//;

    my $default_tt = Path::Class::dir( $template_base, 'tt' );

    # put the CMS app installed templates last so they can be
    # locally overridden
    # and then whatever is already set.
    # *AND* no duplicates.
    my @paths = (
        Path::Class::dir( $c->config->{root} ),
        @{ $c->config->{cms}->{root}->{rw} },
        @{ $c->config->{cms}->{root}->{r} }, $default_tt,
    );
    my ( %uniq, @inc_path );
    for ( @paths, @{ $class->config->{INCLUDE_PATH} || [] } ) {
        push( @inc_path, $_ ) unless $uniq{"$_"}++;
    }

    if ( $c->debug ) {
        my $t = Text::SimpleTable->new(74);
        $t->row("$_") for @inc_path;
        $c->log->debug( "CMS View inc path:\n" . $t->draw . "\n" );
    }

    $class->config( { INCLUDE_PATH => \@inc_path } );

    my $self = $class->next::method( $c, $arg );

    $self->cms_template_base($default_tt);

    return $self;
}

=head2 process

Overrides base method to test cmspage in stash and mangle
the C<template> value if it isa CatalystX::CMS::Page object.

=cut

sub process {
    my ( $self, $c ) = @_;
    my $t = $c->stash->{template};
    $c->log->debug("template = $t") if $c->debug;
    if ( blessed($t)
        and $t->isa('CatalystX::CMS::Page') )
    {
        my $file = $t->file . $t->ext;

        if ( -s $t->delegate ) {
            $c->log->debug(
                "resetting template to $file [" . $t->delegate . ']' )
                if $c->debug;
            $c->stash( template => $file );
            unless ( exists $c->stash->{cmspage} ) {
                $c->stash( cmspage => $t );
            }
        }
        else {
            $c->log->debug( "setting new_file = " . $t->file ) if $c->debug;
            $c->stash( new_file => $t->file, template => 'cms/new_file.tt' );
        }
    }

    $DEBUG and warn "View -> process next::method";

    my $ret = $self->next::method($c);

    $DEBUG and warn "View -> process complete";

    return $ret;
}

=head2 template_vars

Override base method to set additional vars for render(), including:

=over

=item

CMS

=item

additional_template_paths

=back

=cut

sub template_vars {
    my ( $self, $c ) = @_;

    my $cvar     = $self->config->{CATALYST_VAR};
    my $cms_mode = $c->stash->{cms_mode} || 0;
    my $conf     = $c->config->{cms};
    my $cmspage  = $c->stash->{cmspage};
    my @inc;

    # There are two parts to setting up the wrapper paths.
    # (1) the cmspage.type, which defaults to 'html' (think MIME)
    # (2) the cmspage.flavour, which defaults to 'default' (think skins)
    my $type    = $conf->{default_type}    || 'html';
    my $flavour = $conf->{default_flavour} || 'default';
    if ($cmspage) {

        #warn dump $cmspage;

        my $attrs = $cmspage->attrs;
        $type    = exists $attrs->{type}    ? $attrs->{type}    : $type;
        $flavour = exists $attrs->{flavour} ? $attrs->{flavour} : $flavour;

        my %uniq;
        for my $dir ( @{ $conf->{root}->{rw} }, @{ $conf->{root}->{r} } ) {
            my $path = Path::Class::dir( $dir, $type, $flavour ) . '';
            $uniq{$path}++;
            push( @inc, $path );
        }
        my $cmspage_dir = $cmspage->dir . '';
        push( @inc, $cmspage_dir ) unless exists $uniq{$cmspage_dir};
    }

    # in cms mode, always use that flavour for wrappers
    my $wrapper_flav = $flavour;
    if ($cms_mode) {
        $wrapper_flav = 'cms';
    }

    my @path = ( 'cms', 'wrappers', $type, $wrapper_flav );
    my $CMS = {
        css      => [],
        js       => [],
        mode     => $cms_mode,
        static   => ( $c->config->{static_url} || $c->uri_for('/static') ),
        wrappers => {
            type    => $type,
            flavour => $flavour,
            header  => Path::Class::file( @path, 'header.tt' ),
            footer  => Path::Class::file( @path, 'footer.tt' ),
            body    => Path::Class::file( @path, 'body.tt' ),
            wrapper => Path::Class::file( @path, 'wrapper.tt' ),
            base    => Path::Class::dir(@path),
        },
    };

    if ( $c->debug ) {
        $c->log->debug( "View extra inc path: " . dump \@inc );
        $c->log->debug("cms_mode = $cms_mode");

        #$c->log->debug( "CMS var = " . dump $CMS );
    }

    $DEBUG and warn "View -> template_vars set";
    $DEBUG and warn "View: " . dump($CMS);

    defined $cvar
        ? ( $cvar => $c )
        : (
        c                         => $c,
        base                      => $c->req->base,
        name                      => $c->config->{name},
        CMS                       => $CMS,
        additional_template_paths => \@inc,
        );
}

1;

__END__

=head1 AUTHOR

Peter Karman, C<< <karman@cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to
C<bug-catalystx-cms@rt.cpan.org>, or through the web interface at
L<http://rt.cpan.org>.  I will be notified, and then you'll automatically be
notified of progress on your bug as I make changes.

=head1 ACKNOWLEDGEMENTS

The Minnesota Supercomputing Institute C<< http://www.msi.umn.edu/ >>
sponsored the development of this software.

=head1 COPYRIGHT & LICENSE

Copyright 2008 by the Regents of the University of Minnesota.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut
