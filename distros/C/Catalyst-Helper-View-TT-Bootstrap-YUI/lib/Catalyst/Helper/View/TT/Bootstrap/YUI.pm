package Catalyst::Helper::View::TT::Bootstrap::YUI;

use strict;

our $VERSION = '0.02';

use Path::Class;

sub mk_compclass {
    my ( $self, $helper, @args ) = @_;
    my $file = $helper->{file};
    $helper->render_file( 'compclass', $file );
    $self->mk_templates( $helper, @args );
}

sub mk_templates {
    my ( $self, $helper ) = @_;

    # Build directory structure
    # /{base}/root
    my $root = dir( $helper->{base}, 'root' );
    $helper->mk_dir($root);

    # /{base}/root/static ./css ./css/images ./scripts ./images
    my $static = dir( $root, 'static' );
    $helper->mk_dir($static);
    my $css = dir( $static, 'css' );
    $helper->mk_dir($css);
    $helper->mk_dir( dir( $css, 'images' ) );
    $helper->mk_dir( dir( $static, 'images') );
    $helper->mk_dir( dir( $static, 'scripts') );

    # /{base}/root/site
    my $site = dir( $root, 'site' );
    $helper->mk_dir($site);

    # /{base}/root/site/shared
    my $shared = dir( $site, 'shared' );
    $helper->mk_dir($shared);

    # /{base}/root/site/layout
    my $layout = dir( $site, 'layout' );
    $helper->mk_dir($layout);

    # /{base}/root/site/header, navigation, and footer
    my $header = dir( $site, 'header' );
    $helper->mk_dir($header);
    my $nav = dir( $site, 'nav' );
    $helper->mk_dir($nav);
    my $footer = dir( $site, 'footer' );
    $helper->mk_dir($footer);

    # Render files
    # /{base}/root/static/css files
    $helper->render_file( "screen_css",      file( $css, 'screen.css' ) );

    # /{base}/root/site files
    $helper->render_file( "site_wrapper", file( $site, 'wrapper.tt' ) );
    $helper->render_file( "site_html",    file( $site, 'html.tt' ) );

    # /{base}/root/site/shared files
    $helper->render_file( "shared_base",   file( $shared, 'base.tt' ) );

    # /{base}/root/site/layout files
    $helper->render_file( "layout_default", file( $layout, 'default.tt' ));
    #$helper->render_file( "layout_2columns",   file( $layout, '2columns.tt' ));
    #$helper->render_file( "layout_2col_left",  file( $layout, '2col_left.tt' ));
    #$helper->render_file( "layout_2col_right", file( $layout, '2col_right.tt'));
    #$helper->render_file( "layout_3col",       file( $layout, '3columns.tt' ) );

    # /{base}/root/site/header, navigation, and footer files
    $helper->render_file( "header_default", file( $header, 'default.tt' ));
    $helper->render_file( "nav_default",    file( $nav,    'default.tt' ));
    $helper->render_file( "footer_default", file( $footer, 'default.tt' ));
}

=head1 NAME

Catalyst::Helper::View::TT::Bootstrap::YUI - Generate TT templates using YUI

=head1 SYNOPSIS

Helper for TT view. Creates the C<MyAppView/TT.pm> file and a template 
directory structure under MyApp/root containing templates, macros, and 
links to the hosted version of the YUI C<reset-fonts-grids.css> file.

Use the helper to create the view module and templates:

    $ script/myapp_create.pl view TT TT::Bootstrap::YUI

The stash key for configuring everything is C<< $c->stash->{page} >> with
defaults in C<MyApp/root/site/shared/base.tt>.

Add something like the following to the page templates for your application

 [%~
    page.layout = '2columns';  # use a 2 column layout (default is 'default')
    page.header = 'my_custom'; # will load root/site/header/my_custom.tt
    page.footer = 'none';      # don't display a footer

    # adds these <link rel="stylsheet"...> tags to the <head>
    page.head.stylesheets.push('foo.css','bar.css');

    # adds these <script> tags to the <head>
    page.head.scripts.push('foo.js','bar.js');

    # adds these <script> tags to the bottom of the <body> -- usually preferable
    page.body.scripts.push('baz.js','poop.js');

    # adds these classes to the <body> tag
    page.body.classes.push('foo','bar');
 ~%]
 ...your content here...

=head1 DESCRIPTION

This helper module creates a L<Catalyst::View::TT> class in your application.
It also creates a set of templates, macros, and a stylesheet to let you focus 
on the content of your apps pages sooner with less copy and pasting.

It also provides a mechanism for adding dynamic filters, for doing things
like date formatting.

If you already have a TT view in your application, make sure to include the
other directives that are created by the helper.  Typically, this file is
simply C<MyApp/lib/MyApp/View/TT.pm.new> if a file exists with the same name.

See L<Catalyst::Helper::View::TT::Bootstrap::YUI::Manual> for more details on
available variables and macros, and how to work with the layouts.

=head2 METHODS

=head3 mk_compclass

Generates the component class.

=head3 mk_templates

Generates the templates.

=cut

=head1 SEE ALSO

L<Catalyst>, L<Catalyst::View::TT>, L<Catalyst::Helper>,
L<Catalyst::Helper::View::TT>

=head1 AUTHORS

Jay Shirley <jshirley@cpan.org>

Lucas Smith <lsmith@lucassmith.name>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;

use parent 'Catalyst::View::TT';

use Scalar::Util qw(blessed);
use DateTime::Format::DateParse;

__PACKAGE__->config({
    PRE_PROCESS         => 'site/shared/base.tt',
    WRAPPER             => 'site/wrapper.tt',
    TEMPLATE_EXTENSION  => '.tt',
    TIMER               => 0,
    static_root         => '/static',
    static_build        => 0,
    default_tz          => 'America/Los_Angeles',
    default_locale      => 'en_US',
    formats             => {
        date => {
            date    => '%x',
            short   => '%b %e, %G',
            long    => '%X %x',
        }
    }
});

sub template_vars {
    my $self = shift;
    return (
        $self->next::method(@_),
        static_root  => $self->{static_root},
        static_build => $self->{static_build}
    );
}

sub new {
    my ( $class, $c, $arguments ) = @_;
    my $formats = $class->config->{formats};

    return $class->next::method( $c, $arguments ) unless ref $formats eq 'HASH';

    $class->config->{FILTERS} ||= {};

    my $filters = $class->config->{FILTERS};

    foreach my $key ( keys %$formats ) {
        if ( $key eq 'date' ) {
            foreach my $date_key ( keys %{$formats->{$key}} ) {
                $filters->{"${key}_$date_key"} = sub {
                    my $date = shift;
                    return unless defined $date;
                    unless ( blessed $date and $date->can("stringify") ) {
                        $date = DateTime::Format::DateParse->parse_datetime($date);
                    }
                    unless ( $date ) { return $date; }
                    $date->set_locale($class->config->{default_locale})
                        if defined $class->config->{default_locale};
                    # Only apply a timezone if we have a complete date.
                    unless ( "$date" =~ /T00:00:00$/ ) {
                        $date->set_time_zone( $class->config->{default_tz} || 'America/Los_Angeles' );
                    }
                    $date->strftime($formats->{$key}->{$date_key});
                };
            }
        }
    }

    return $class->next::method( $c, $arguments );
}

=head1 NAME

[% class %] - Catalyst TT::Bootstrap::YUI View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst TT::Bootstrap::YUI View.

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
__shared_base__
[%~ TAGS star %]
[%~

MACRO ref(var) BLOCK;
    var_ref = "$var";
    var_ref.match('^([A-Z]+)\\(0x[0-9a-f]+\\)$').0;
END;

# Wraps c.uri_for to point to static resources either inside the
# /root/static structure or explicit URIs.  Assumes 
MACRO static(res, versioned, query) BLOCK;
    uri_params = query || {};
    IF res.match('^https?://') || res.match('^/');
        res;
    ELSIF versioned && static_build;
        uri_params.ver = uri_params.ver || static_build;
        c.uri_for( static_root, res, uri_params );
    ELSE;
        c.uri_for( static_root, res );
    END;
END;

# Set up the default stash structure for the page
IF !page || !ref(page) == 'HASH';
    page = {};
END;
DEFAULT page.title  = c.config.name || '[* app *]';
DEFAULT page.layout = 'default';
DEFAULT page.header = 'default';
DEFAULT page.nav    = 'default';
DEFAULT page.footer = 'default';
DEFAULT page.language = c.config.language || 'en';
DEFAULT page.head             = {};
DEFAULT page.head.stylesheets = [
    'http://yui.yahooapis.com/combo?3.0.0/build/cssfonts/fonts-min.css&3.0.0/build/cssreset/reset-min.css&3.0.0/build/cssbase/base-min.css'
];
DEFAULT page.head.scripts     = [];
DEFAULT page.body             = {};
DEFAULT page.body.classes     = ['yui-skin-sam'];
DEFAULT page.body.scripts     = [
    'http://yui.yahooapis.com/combo?3.0.0/build/yui/yui-min.js'
];
DEFAULT page.content_class    = 'content';

# Include global macros/vars/set up per implementation
TRY; PROCESS site/global.tt; CATCH file; END;

~%]
__screen_css__
/* screen.css */
__site_wrapper__
[%~ TAGS star ~%]
[%~
# Process the appropriate layout
IF page.layout == 'partial';
    content;
ELSE;
    IF page.layout == 'none';
        content WRAPPER site/html.tt;
    ELSE;
        content WRAPPER site/html.tt + "site/layout/${page.layout}.tt";
    END;
END;
~%]
__site_html__
[%~ TAGS star ~%]
[%~ 

IF c.debug && debug_init.defined; $debug_init; END;

IF page.header && page.header != 'none';
    header = PROCESS "site/header/${page.header}.tt";
END;

IF page.footer && page.header != 'none';
    footer = PROCESS "site/footer/${page.footer}.tt";
END;

~%]
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN" "http://www.w3.org/TR/html4/strict.dtd">
<html lang="[% page.language %]">
 <head>
  <title>[% page.title %]</title>
   <meta http-equiv="Content-Language" content="[% page.language %]">
    <meta http-equiv="Content-Type" content="text/html; charset=utf-8">
[%
# Add all javascript refs in page.head.scripts (see page.body.scripts)
page.head.scripts = page.head.scripts.unique;
FOREACH script IN page.head.scripts;
    NEXT UNLESS script;
    script = script.match('^(https?://|/)') ?
                    script :
                    static("scripts/$script", 1); -%]
    <script type="text/javascript" src="[% script %]"></script>
[%
END;

# Add all stylesheet refs in page.head.stylesheets
page.head.stylesheets = page.head.stylesheets.unique;
FOREACH stylesheet IN page.head.stylesheets;
    NEXT UNLESS stylesheet;
    stylesheet = stylesheet.match('^(https?://|/)') ?
                    stylesheet :
                    static("css/$stylesheet", 1); -%]
   <link rel="stylesheet" href="[% stylesheet %]" media="screen">
[%
END;
%]
   <link rel="stylesheet" href="[% static( 'css/screen.css', 1 ) %]" media="screen">
 </head>
 <!--[if !IE]> <-->
 <body
    [%~ IF page.body.id %] id="[% page.body.id %]"[% END %]
    [%~ page.body.classes.size ?
            ' class="' _ page.body.classes.unique.join(' ') _ '"' : '' %]>
 <!--><![endif]-->
 <!--[if IE 5]>
 <body
    [%~ IF page.body.id %] id="[% page.body.id %]"[% END =%]
    class="[% page.body.classes.join(' ') %] IE IE5">
 <![endif]-->
 <!--[if IE 6]>
 <body
    [%~ IF page.body.id %] id="[% page.body.id %]"[% END =%]
    class="[% page.body.classes.join(' ') %] IE IE6">
 <![endif]-->
 <!--[if IE 7]>
 <body
    [%~ IF page.body.id %] id="[% page.body.id %]"[% END =%]
    class="[% page.body.classes.join(' ') %] IE IE7">
 <![endif]-->
    [% # Drop in the header if appropriate
    header %]
    <div class="[% page.content_class %]">[% content %]</div>
    [% footer;

    # Add footer scripts
    page.body.scripts = page.body.scripts.unique;
    FOREACH script IN page.body.scripts;
        NEXT UNLESS script;
        script = script.match('^(https?://|/)') ?
                        script :
                        static('scripts/' _ script, undef, 1); -%]
        <script type="text/javascript" src="[% script %]"></script>
    [%
    END;
    %]
 </body>
</html>
__layout_default__
[%~ TAGS star ~%]
[%~ 
# Nothing fancy here.  Just dump the content.
content
~%]
__header_default__
[%~ TAGS star ~%]
<div id="header">
   <h1>This is your header</h1>
   <p>Edit root/site/header/default.tt</p>
</div>
[% # Include the navigation
IF page.nav && page.nav != 'none';
    PROCESS "site/nav/${page.nav}.tt";
END;
~%]
__nav_default__
[%~ TAGS star ~%]
[%~
# Place all global navigation in this template
~%]
__footer_default__
[%~ TAGS star ~%]
<div id="footer">
    <p>Edit root/site/footer/default.tt</p>
</div>
