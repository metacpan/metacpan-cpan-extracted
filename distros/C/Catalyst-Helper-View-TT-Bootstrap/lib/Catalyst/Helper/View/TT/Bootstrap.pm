package Catalyst::Helper::View::TT::Bootstrap;

use strict;
use Path::Class;

our $VERSION = '0.01';

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
    $helper->render_file( "nav_default_css", file( $css, 'nav_default.css' ) );

    # /{base}/root/site files
    $helper->render_file( "site_wrapper", file( $site, 'wrapper.tt' ) );
    $helper->render_file( "site_html",    file( $site, 'html.tt' ) );

    # /{base}/root/site/shared files
    $helper->render_file( "shared_base",   file( $shared, 'base.tt' ) );

    # /{base}/root/site/layout files
    $helper->render_file( "layout_default",     file( $layout, 'default.tt' ) );
    $helper->render_file( "layout_2columns",    file( $layout, '2columns.tt' ) );
    $helper->render_file( "layout_2col_top",    file( $layout, '2col_top.tt' ) );
    $helper->render_file( "layout_2col_bottom", file( $layout, '2col_bottom.tt' ) );

    # /{base}/root/site/header, navigation, and footer files
    $helper->render_file( "header_default", file( $header, 'default.tt' ) );
    $helper->render_file( "nav_default",    file( $nav,    'default.tt' ) );
    $helper->render_file( "footer_default", file( $footer, 'default.tt' ) );
}

=head1 NAME

Catalyst::Helper::View::TT::Bootstrap - Helper for TT view. Creates the View/TT.pm and a template directory structure under MyApp/root containing templates, macros, and a base stylesheet to facilitate getting to the meat of building your app's pages sooner than later.

=head1 SYNOPSIS

# use the helper to create the view module and templates

    $ script/myapp_create.pl view TT TT::Bootstrap

# add something like the following to the page templates for your application
 [%
 page.layout = '2columns';  # use a 2 column layout
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
 %]
 ...your content here...

=head1 DESCRIPTION

This helper module creates a TT View module.  It also creates a set of
templates, macros, and a stylesheet to let you focus on the content of
your apps pages sooner.

The View/TT.pm module created is configured to work within the generated
template structure.

See L<Catalyst::Helper::View::TT::Bootstrap::Manual> for more details on
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

=head1 AUTHOR

Lucas Smith <lsmith@lucas.e.smith@gmail.com>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use strict;
use base 'Catalyst::View::TT';

__PACKAGE__->config({
    PRE_PROCESS        => 'site/shared/base.tt',
    WRAPPER            => 'site/wrapper.tt',
    TEMPLATE_EXTENSION => '.tt',
    TIMER              => 0,
    static_root        => '/static',
    static_build       => 0
});

sub template_vars {
    my $self = shift;
    return (
        $self->NEXT::template_vars(@_),
        static_root  => $self->{static_root},
        static_build => $self->{static_build}
    );
}

=head1 NAME

[% class %] - Catalyst TT::Bootstrap View

=head1 SYNOPSIS

See L<[% app %]>

=head1 DESCRIPTION

Catalyst TT::Bootstrap View.

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
    IF res.match('^https?://');
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
DEFAULT page.title  = '[* app *]';
DEFAULT page.layout = 'default';
DEFAULT page.header = 'default';
DEFAULT page.nav    = 'default';
DEFAULT page.footer = 'default';
DEFAULT page.head             = {};
DEFAULT page.head.stylesheets = [];
DEFAULT page.head.scripts     = [];
DEFAULT page.body             = {};
DEFAULT page.body.classes     = [];
DEFAULT page.body.scripts     = [];
DEFAULT page.content_class    = 'content';

# Include global macros/vars/set up per implementation
TRY; PROCESS site/global.tt; CATCH file; END;

~%]
__screen_css__
/* Reset styles */
body {
    color: #000;
    background:#FFF;
}
body,
h1, h2, h3, h4, h5, h6,
div, p, blockquote, code, pre, th, td,
ol, ul, li, dl, dt, dd,
form, fieldset, legend, input, textarea {
    margin: 0;
    padding: 0;
}
table {
    border-collapse: collapse;
    border-spacing: 0;
}
fieldset, img {
    border:0;
}
strong, em, code, th, td {
    font-style: normal;
    font-weight: normal;
}
li {
    list-style: none;
}
h1, h2, h3, h4, h5, h6 {
    font-size: 100%;
    font-weight: normal;
}

/* Layout style */
.content {
    width: 750px;
    overflow: hidden;
    margin-left: auto;
    margin-right: auto;
}
.float_container {
    overflow: hidden;
}
.main_column {
    width: 425px;
}
.support_column {
    width: 300px;
}
.column {
    width: 365px;
}

/* Miscellaneous useful styles */
.hide  { display: none !important }
.left  { display: inline; float: left }
.right { display: inline; float: right }
.clear { clear: both }

/* cursor styles */
.clickable   { cursor: pointer; cursor: hand; }
.unclickable { cursor: default !important; }
.movable     { cursor: move; }
__nav_default_css__
/* Define the style for the default site navigation here */
#nav {
    width: 750px;
    margin: 0 auto 1.2em;
    border-bottom: 1px solid #4d3c4b;
    overflow: hidden;
}   
#nav li {
    float: left;
    margin-right: -10px;
}   
#nav li a {
    display: block;
    background: url(../images/catalyst_logo.png) no-repeat right top;
    padding-right: 25px;
    color: #900;
    font: bold small-caps 120% Trebuchet MS, Arial Black, Arial, sans-serif;
}
#nav li a span {
    display: block;
    background: url(../images/catalyst_logo.png) no-repeat -10px 0;
    padding: 25px 0 .2em 15px;
}
#nav li.active a {
    background-position: -10px 0;
    padding: 0 0 0 15px;
    color: #555;
    text-decoration: none;
}
#nav li.active a span {
    background-position: right top;
    padding: 25px 25px .2em 0;
}
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
  <meta http-equiv="Content-Type" content="text/html; charset=utf-8" />
  <link rel="stylesheet" href="[% static( 'css/screen.css', 1 ) %]" media="screen"/>
  <link rel="stylesheet" href="[% static( 'css/nav_' _ page.nav _ '.css' ) %]" media="screen"/>
[%
# Add all javascript refs in page.head.scripts (see page.body.scripts)
page.head.scripts = page.head.scripts.unique;
FOREACH script IN page.head.scripts;
    NEXT UNLESS script;
    script = script.match('^https?://') ?
                    script :
                    static('scripts/' _ script, 1); -%]
    <script type="text/javascript" src="[% script %]"></script>
[%
END;

# Add all stylesheet refs in page.head.stylesheets
page.head.stylesheets = page.head.stylesheets.unique;
FOREACH stylesheet IN page.head.stylesheets;
    NEXT UNLESS stylesheet;
    stylesheet = stylesheet.match('^https?://') ?
                    stylesheet :
                    static('css/' _ stylesheet, 1); -%]
   <link rel="stylesheet" href="[% stylesheet %]" media="screen">
[%
END;
%]
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
        script = script.match('^https?://') ?
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
# Nothing fancy here.  Just dump the content
content
~%]
__layout_2columns__
[%~ TAGS star ~%]
[%
DEFAULT left_column_template  = 'left_column';
DEFAULT left_column_class     = 'main_column';

DEFAULT right_column_template = 'right_column';
DEFAULT right_column_class    = 'support_column';

DEFAULT content_column = 'left';

DEFAULT column_wrapper_class  = page.content_class;
column_wrapper_class = '' IF column_wrapper_class == 'none';
~%]
<div class="[% page.content_class %]">
IF content_column == 'left' %]
    <div class="left [% left_column_class %]">[% content %]</div>
    <div class="right [% right_column_class %]">
    [%~
    TRY;
        PROCESS $right_column_template;
    CATCH file;
        '<p>Error rendering right column</p>';
        IF c.debug;
            '<p>' _ file.info _ '</p>';
        END;
    END;
    ~%]
    </div>
[%
ELSE;
~%]
    <div class="left [% left_column_class %]">
    [%~
    TRY;
        PROCESS $left_column_template;
    CATCH file;
        '<p>Error rendering left column</p>';
        IF c.debug;
            '<p>' _ file.info _ '</p>';
        END;
    END ~%]
    </div>
    <div class="right [% right_column_class %]">[% content %]</div>
[%
END
%]
__layout_2col_top__
[%~ TAGS star ~%]
[%
DEFAULT left_column_template  = 'left_column';
DEFAULT left_column_class     = 'column';
DEFAULT right_column_template = 'right_column';
DEFAULT right_column_class    = 'column';

DEFAULT bottom_content_class  = page.content_class;
bottom_content_class = '' IF bottom_content_class == 'none';

DEFAULT column_wrapper_class  = bottom_content_class;
column_wrapper_class = '' IF column_wrapper_class == 'none';
~%]
<div class="float_container [% column_wrapper_class %]">
    <div class="left [% left_column_class %]">
    [%~
    TRY;
        PROCESS $left_column_template;
    CATCH file;
        '<p>Error rendering left column</p>';
        IF c.debug;
            '<p>' _ file.info _ '</p>';
        END;
    END;
    %]</div>
    <div class="right [% right_column_class %]">
    [%~
    TRY;
        PROCESS $right_column_template;
    CATCH file;
        '<p>Error rendering right column</p>';
        IF c.debug;
            '<p>' _ file.info _ '</p>';
        END;
    END;
    %]</div>
</div>
<div class="[% bottom_content_class %]">[% content %]</div>
__layout_2col_bottom__
[%~ TAGS star ~%]
[%
DEFAULT left_column_template  = 'left_column';
DEFAULT left_column_class     = 'column';

DEFAULT right_column_template = 'right_column';
DEFAULT right_column_class    = 'column';

DEFAULT top_content_class     = page.content_class;
top_content_class = '' IF top_content_class == 'none';

DEFAULT column_wrapper_class  = top_content_class;
column_wrapper_class = '' IF column_wrapper_class == 'none';
~%]
<div class="[% top_content_class %]">[% content %]</div>
<div class="float_container [% column_wrapper_class %]">
    <div class="left [% left_column_class %]">
    [%~
    TRY;
        PROCESS $left_column_template;
    CATCH file;
        '<p>Error rendering left column</p>';
        IF c.debug;
            '<p>' _ file.info _ '</p>';
        END;
    END;
    %]</div>
    <div class="right [% right_column_class %]">
    [%~
    TRY;
        PROCESS $right_column_template;
    CATCH file;
        '<p>Error rendering right column</p>';
        IF c.debug;
            '<p>' _ file.info _ '</p>';
        END;
    END;
    %]</div>
</div>
__header_default__
[%~ TAGS star ~%]
<p>Your masthead here</p>

[% # Include the navigation
IF page.nav && page.nav != 'none';
    PROCESS "site/nav/${page.nav}.tt";
END;
~%]
__nav_default__
[%~ TAGS star ~%]
<ul id="nav">
    <li class="active"><a href="#"><span>Nav 1</span></a></li>
    <li><a href="#"><span>Nav 2</span></a></li>
    <li><a href="#"><span>Nav 3</span></a></li>
    <li><a href="#"><span>Nav 4</span></a></li>
    <li><a href="#"><span>Nav 5</span></a></li>
</ul>
__footer_default__
[%~ TAGS star ~%]
<p>Your footer here</p>
