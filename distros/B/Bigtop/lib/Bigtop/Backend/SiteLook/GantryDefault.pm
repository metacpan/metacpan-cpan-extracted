package Bigtop::Backend::SiteLook::GantryDefault;
use strict; use warnings;

# I would normally use Inline TT to control the appearance of the
# output, but I've been scared away before even trying to generate
# a valid template toolkit template with a tt template.
# So, I resort the bad old days of here docs.

use File::Spec;
use Bigtop;
use Bigtop::Parser;

BEGIN {
    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'app', 'location',
        )
    );

    Bigtop::Parser->add_valid_keywords(
        Bigtop::Keywords->get_docs_for(
            'controller',
            qw( location rel_location page_link_label )
        )
    );
}

sub what_do_you_make {
    return [
        [ 'html/genwrapper.html' =>
                'A sample template toolkit wrapper [please change it]' ],
    ];
}

sub backend_block_keywords {
    return [
        { keyword => 'no_gen',
          label   => 'No Gen',
          descr   => 'Skip everything for this backend',
          type    => 'boolean' },

        { keyword => 'gantry_wrapper',
          label   => 'Gantry Wrapper Path',
          descr   => 'Path to sample_wrapper.tt in the Gantry '
                        .   'distribution [defaults to ./html]',
          type    => 'text' },
    ];
}

sub gen_SiteLook {
    my $class    = shift;
    my $base_dir = shift;
    my $tree     = shift;

    # make the html directory
    my $html_dir = File::Spec->catdir( $base_dir, 'html' );
    mkdir $html_dir;
    $html_dir    = File::Spec->catdir( $html_dir, 'templates' );
    mkdir $html_dir;

    # find the root location
    my $app_statements = $tree->{application}{lookup}{app_statements};
    my $app_location   = $app_statements->{location}[0]
            if ( defined $app_statements->{location} );

    # make the wrapper...

    # ...get controllers
    my $controllers
            = $tree->walk_postorder( 'output_controller_name' );

    my $control_lookup = $tree->{application}{lookup}{controllers};
    my %location_for;
    my %title_for;

    CONTROLLER:
    foreach my $controller ( @{ $controllers } ) {
        my $statements    = $control_lookup->{ $controller }{statements};
        my $location_list = $statements->{rel_location}
                         || $statements->{location};
        my $title_list    = $statements->{page_link_label};

        next CONTROLLER unless $title_list;
        next CONTROLLER if ( $controller eq 'base_controller' );

        unless ( $location_list ) {
            die 'Error: no location or rel_location defined for '
                .   "controller $controller\n";
        }

        $location_for{ $controller } = $location_list->[0];
        $title_for   { $controller } = $title_list   ->[0];
    }

    # ...make the content
    my $links    = build_links(
            $controllers, $app_location, \%location_for, \%title_for
    );
    my $content;
    eval {
        $content  = build_wrapper( $tree->get_config, $links );
    };
    if ( $@ ) {
        warn $@;
        return;
    }

    # ...write it
    my $wrapper  = File::Spec->catfile( $html_dir, 'genwrapper.tt' );

    eval {
        Bigtop::write_file( $wrapper, $content );
    };
    warn $@ if ( $@ );
}

sub build_wrapper {
    my $config = shift;
    my $links  = shift;

    # load the default wrapper
    my $wrapper_file = $config->{SiteLook}{gantry_wrapper};

    unless ( defined $wrapper_file ) {
        require Gantry::Init;
        $wrapper_file = Gantry::Init::base_root() . '/sample_wrapper.tt';
    }

    my $default_wrapper;
    my $WRAPPER;

    open $WRAPPER, '<', $wrapper_file
            or die "Couldn't read $wrapper_file: $!\n";

    while ( my $wrapper_line = <$WRAPPER> ) {
        $wrapper_line =~ s/\s*<!-- Your links here.*-->\n/$links/ if $links;

        $default_wrapper .= $wrapper_line;
    }

    close $WRAPPER;

    return $default_wrapper;
}

sub build_links {
    my $controllers  = shift;
    my $app_location = shift;
    my $location_for = shift;
    my $title_for    = shift;

    # no leading or trailing slashes please
    $app_location    =~ s{^/+}{} if $app_location;
    $app_location    =~ s{/+$}{} if $app_location;

    # make the links
    my $lead = '            <li><a href=\'[% self.app_rootp %]';
    my $links;

    CONTROLLER:
    foreach my $controller ( @{ $controllers } ) {
        my $location   = $location_for  ->{ $controller };
        my $text       = $title_for->{ $controller };

        next CONTROLLER unless $location and $text;
        if ( defined $app_location ) {
            $links .= "$lead/$app_location/$location'>$text</a></li>\n";
        }
        else {
            $links .= "$lead/$location'>$text</a></li>\n";
        }
    }

    return $links;
}

# controller_block
package #
    controller_block;
use strict; use warnings;

sub output_controller_name {
    my $self = shift;

    return [ $self->{__NAME__} ];
}

1;

=head1 NAME

Bigtop::Backend::SiteLook::GantryDefault - Bigtop to generate site appearance files

=head1 SYNOPSIS

If your bigtop file looks like this:

    config {
        SiteLook  GantryDefault {}
    }
    app App::Name { }

and their are controllers in the app block, this backend will generate
the templates for your app (mostly by copying them from Gantry's collection)
when you type:

    bigtop your.bigtop SiteLook

or

    bigtop your.bigtop all

The templates and other files will live in the html subdirectory of the
build directory.  The files generated (or copied) include genwrapper.tt,
index.html, and all the other templates that various bits of Gantry use
(notably the AutoCRUD).  It also makes a couple of css files in the
html/css subdirectory of the build dir.

=head1 DESCRIPTION

This Bigtop backend generates templates and css files to make your app
look like the Gantry samples.

=head1 KEYWORDS

This modules registers the location keyword at the app and controller level.
It also registers page_link_label and rel_location at the controller level.
Note that all of these except page_link_label are also registered by
Control modules.

=head1 METHODS

To keep podcoverage tests happy.

=over 4

=item backend_block_keywords

Tells tentmaker that I understand these config section backend block keywords:

    no_gen
    gantry_wrapper

=item what_do_you_make

Tells tentmaker what this module makes.  Summary: genwrapper.tt a TT WRAPPER.

=item gen_SiteLook

Called by Bigtop::Parser to get me to do my thing.

=item build_links

What I call on the various AST packages to do my thing.

=item build_wrapper

What I call on the various AST packages to do my thing.

=back

=head1 AUTHOR

Phil Crow <crow.phil@gmail.com>

=head1 COPYRIGHT and LICENSE

Copyright (C) 2005 by Phil Crow

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.6 or,
at your option, any later version of Perl 5 you may have available.

=cut
