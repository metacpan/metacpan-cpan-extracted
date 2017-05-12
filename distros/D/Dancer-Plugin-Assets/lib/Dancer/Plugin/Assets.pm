=head1 NAME

Dancer::Plugin::Assets - Manage and minify .css and .js assets in a Dancer application

=head1 SYNOPSIS

=head3 In your Dancer application

 use Dancer::Plugin::Assets qw( assets add_asset );

=head3 Sometime during the request ...

 get "/index" => sub {
    ## Include assets by plugin method
    add_asset "/css/beautiful.css";
    add_asset "/css/handlebars.js";

    ## Include assets by assets object
    assets->include( "/css/main.css" );
    assets->include( "/js/something.js" );
 };

=head3 Then, in your .tt, print css tags at <head>, print js tags after body

  <html>
    <head><title>[% title %]</title>
    [% css_tags %]
    </head>
    <body>
    </body>
    [% js_tags %]
  </html>

=head3 Or you want to add css and js and print them all in template file inside <head>

  <html>
    <head><title>[% title %]</title>
    [% add_asset("/js/jquery.js")         %]
    [% add_asset("/js/handlebars.js")     %]
    [% add_asset("/css/beautiful.css")    %]
    [% CALL assets.include("/js/foo.js")  %]
    [% css_and_js_tags || js_and_css_tags %]
    </head>
    <body>
    </body>
  </html>

=head1 DESCRIPTION

Dancer::Plugin::Assets integrates File::Assets into your Dancer application. Essentially, it provides a unified way to include .css and .js assets from different parts of your program. When you're done processing a request, you can use assets->export() or [% css_and_js_tags %] to generate HTML or assets->exports() to get a list of assets.

D::P::Assets will also handle .css files of different media types properly.

In addition, D::P::Assets includes support for minification via YUI compressor, L<JavaScript::Minifier>, L<CSS::Minifier>, L<JavaScript::Minifier::XS>, and L<CSS::Minifier::XS>

Note that Dancer::Plugin::Assets does not serve files directly, it will work with L<Static::Simple> or whatever static-file-serving mechanism you're using.

=head1 USEAGE

For usage hints and tips, see L<File::Assets>

=head1 CONFIGURATION

You can configure D::P::Assets by manipulating the environment configration files, e.g.

    config.yml
    environments/development.yml
    environments/production.yml

The following settings are available:

    url            # The url to access the asset files default "/"

    base_dir       # A path to automatically look for assets under (e.g. "/public")
                   
                   # This path will be automatically prepended to includes, so that instead of
                   # doing ->include("/public/css/stylesheet.css") you can just do ->include("/css/stylesheet.css")
                   
                   
    output_dir     # The path to output the results of minification under (if any).
                   # For example, if output is "built/" (the trailing slash is important), then minified assets will be
                   # written to "root/<assets-path>/static/..."
                   #
                   # Designates the output path for minified .css and .js assets
                   # The default output path pattern is "%n%-l%-d.%e" (rooted at the dir of <base>)
                   
                   
    minify         # "1" or "best" - Will either use JavaScript::Minifier::XS> & CSS::Minifier::XS or
                   #                 JavaScript::Minifier> & CSS::Minifier (depending on availability)
                   #                 for minification
                   # "0" or "" or undef - Don't do any minfication (this is the default)
                   # "./path/to/yuicompressor.jar" - Will use YUI Compressor via the given .jar for minification
                   # "minifier" - Will use JavaScript::Minifier & CSS::Minifier for minification


    minified_name  # The name of the key in the stash that provides the assets object (accessible via config->{plugins}{assets}{minified_name}.
                   # By default, the <minified_name> is "minified".

=head1 Example configuration

Here is an example configuration: ( All the value are set by default )

    plugins:
        Assets:
            base_dir: "/public"
            output_dir: "static/%n%-l.%e"
            minified_name: "minified"
            minify: 1

=head1 METHODS IN ROUTE CODE

=head2 assets

Return L<File::Assets> object that exists throughout the lifetime of the request

=head2 add_asset

same as sub { assets->include( shift ); return undef }

=head1 METHODS IN TT

=head2 [% assets %]

Return L<File::Assets> object that exists throughout the lifetime of the request

=head2 [% add_asset %]

same as [% CALL assets.include( "file..." ) %]

=head2 [% css_tags %]

return tags of css in html

=head2 [% js_tags %]

return tags of javascript in html

=head2 [% css_and_js_tags %]

return tags in this order of css and javascript in html

=head2 [% js_and_css_tags %]

return tags in this order of javascript and css in html

=head1 AUTHOR

Michael Vu, C<< <micvu at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-dancer-plugin-assets at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Dancer::Plugin::Assets>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::Assets

You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-Assets>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-Assets>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-Assets>

=item * Search CPAN

L<http://search.cpan.org/dist/Dancer-Plugin-Assets>

=item * GIT Respority

L<https://bitbucket.org/mvu8912/p5-dancer-plugin-assets>

=back

=head1 SEE ALSO

L<File::Assets>

L<Dancer::Plugin>

L<http://developer.yahoo.com/yui/compressor/>

L<JavaScript::Minifier::XS>

L<CSS::Minifier::XS>

L<JavaScript::Minifier>

L<CSS::Minifier>

=head1 ACKNOWLEDGEMENTS

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

package Dancer::Plugin::Assets;
{
  $Dancer::Plugin::Assets::VERSION = '1.52';
}
use URI;
use Dancer::Plugin;
use Dancer ":syntax";
use File::Assets;

register assets              => \&_assets;
register add_asset           => \&_include;
register_plugin for_versions => [ 1, 2 ];

hook before_template_render => sub {
    my $stash = shift;
    $stash->{assets}          = _assets();
    $stash->{add_asset}       = \&_include;
    $stash->{css_tags}        = \&_css_tags;
    $stash->{js_tags}         = \&_js_tags;
    $stash->{css_and_js_tags} = \&_css_and_js_tags;
    $stash->{js_and_css_tags} = \&_js_and_css_tags;
};

sub _assets {
    return var("assets")
      || _build_assets();
}

sub _include {
    my $assets = _assets();
    $assets->include(@_);
    return;
}

sub _js_and_css_tags {
    return _js_tags() . _css_tags();
}

sub _css_and_js_tags {
    return _css_tags() . _js_tags();
}

sub _css_tags {
    my $assets = _assets();
    return $assets->export("css");
}

sub _js_tags {
    my $assets = _assets();
    return $assets->export("js");
}

sub _build_assets {
    my $setting = plugin_setting();

    my $url           = _url( $setting->{url} );
    my $base_dir      = $setting->{base_dir} || setting "public";
    my $output_dir    = $setting->{output_dir} || "static/%n%-l.%e";
    my $minify        = defined $setting->{minify} ? $setting->{minify} : 1;
    my $minified_name = $setting->{minified_name} || "minified";

    ## https://metacpan.org/pod/File::Assets#METHODS
    my $assets = File::Assets->new(
        name        => $minified_name,
        minify      => $minify,
        output_path => $output_dir,
        base        => [ $url, $base_dir ],
    );

    return var assets => $assets;
}

sub _url {
    my $url = shift
      or return _site_url();
    if ( $url =~ /^\// ) {
        return _site_url() . $url;
    }
    if ( $url !~/^[^\/]+\:\/\//i ) {
        return _site_url() . $url;
    }
    return $url;
}

sub _site_url {
    return _scheme() . "://" . _host();
}

sub _scheme {
    return request->env->{"psgi.url_scheme"};
}

sub _host {
    return request->host;
}

true;
