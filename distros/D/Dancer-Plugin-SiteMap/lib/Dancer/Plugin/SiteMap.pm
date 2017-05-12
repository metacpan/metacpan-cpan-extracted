package Dancer::Plugin::SiteMap;

use strict;
use Dancer qw(:syntax);
use Dancer::Plugin;

use Scalar::Util;
use XML::Simple;

our $VERSION     = '0.14';
my  $OMIT_ROUTES = [];
my  @sitemap_urls;

# Add syntactic sugar for omitting routes.
register 'sitemap_ignore' => sub {

    # Dancer 2 keywords receive a reference to the DSL object as a first param,
    # So if we're running under D2, we need to make sure we don't pass that on
    # to the route gathering code.
    shift if Scalar::Util::blessed($_[0]) && $_[0]->isa('Dancer::Core::DSL');
    push @$Dancer::Plugin::SiteMap::OMIT_ROUTES, @_;
};

# Add this plugin to Dancer, both Dancer 1 and Dancer 2 :-)
register_plugin( for_versions => [ qw( 1 2 ) ] );

my $conf   = plugin_setting();
my %routes = (
    html => {
        urlpath => '/sitemap',
        coderef => \&_html_sitemap,
    },
    xml  => {
        urlpath => '/sitemap.xml',
        coderef => \&_xml_sitemap,
    },
);

# If a route exists but it's not defined within the app settings, this means the
# developer wishes the app omit that particular sitemap type. If the route
# doesn't exist in the plugin settings at all, we go with the default urlpath
# for that route.
for my $route_type (keys %routes) {
    my $route      = $routes{$route_type};
    my $config_key = $route_type . "_route";

    if (exists $conf->{$config_key}) {
        $route->{urlpath} = $conf->{$config_key} || undef;
    }

    get $route->{urlpath} => $route->{coderef} if $route->{urlpath};
}

# Add omissions defined in the robots.txt file, if that option is specified in
# the config.
if ( defined $conf->{'robots_disallow'} ) {

    # Read the Disallow lines from robots.txt and add to $OMIT_ROUTES
    my $robots_txt = $conf->{'robots_disallow'};
    my @disallowed_list = ();
    open my $robots_fh, '<', $robots_txt or die "Error reading $robots_txt $!";

    while (my $line = <$robots_fh>) {
        if ($line =~ m/^\s*Disallow: \s*(\/[^\s#]*)/) {
            push @disallowed_list, $1;
        }
    }

    close $robots_fh;
    sitemap_ignore(@disallowed_list);
}

# The action handler for the automagic /sitemap route. Uses the list of
# URLs from _retreive_get_urls and outputs a basic HTML template to the
# browser using the standard layout if one is defined.
sub _html_sitemap {
    my @urls = _retreive_get_urls();

    my $content = qq[<h2>Site Map</h2>\n<ul class="sitemap">\n];
    for my $url (@urls) {
        $content .= qq[  <li><a href="$url">$url</a></li>\n];
    }
    $content .= qq[</ul>\n];

    # If the config specifies a HTML Wrapper for the HTML SiteMap - then use
    # that (which handily also stuffs it in the layout). Failing that, we need
    # to just take the sitemap and whack it in the site layout
    return ($conf->{html_template})
        ? template $conf->{html_template}, { sitemap => $content }
        : engine('template')->apply_layout($content);
};


# The action handler for the automagic /sitemap.xml route. Uses the list of
# URLs from _retreive_get_urls and outputs an XML document to the browser.
sub _xml_sitemap {
    my @urls = _retreive_get_urls();
    my @sitemap_urls;

    # add the "loc" key to each url so XML::Simple creates <loc></loc> tags.
    for my $url (@urls) {
        my $uri = uri_for($url);
        push @sitemap_urls, { loc => [ "$uri" ] }; # $uri has to be stringified
    }

    # create a hash for XML::Simple to turn into XML.
    my %urlset = (
        xmlns => 'http://www.sitemaps.org/schemas/sitemap/0.9',
        url   => \@sitemap_urls
    );

    my $xs  = new XML::Simple( KeepRoot   => 1,
                               ForceArray => 0,
                               KeyAttr    => {urlset => 'xmlns'},
                               XMLDecl    => '<?xml version="1.0" encoding="UTF-8"?>' );
    my $xml = $xs->XMLout( { urlset => \%urlset } );

    content_type "text/xml";
    return $xml;
};


# Obtains the list of URLs from Dancers Route Registry.
sub _retreive_get_urls {
    return @sitemap_urls if @sitemap_urls;

    my $version = (exists &dancer_version) ? int( dancer_version() ) : 1;
    my @apps    = ($version == 2) ? @{ runner->server->apps }
                                  : Dancer::App->applications;

    my ($route, @urls);
    for my $app ( @apps ) {
        my $routes = ($version == 2) ? $app->routes
                                     : $app->{registry}->{routes};

        # push the static get routes into an array.
        get_route:
        for my $get_route ( @{ $routes->{get} } ) {
            my $pattern = ($version == 2) ? $get_route->spec_route
                                          : $get_route->{pattern};

            if (ref($pattern) !~ m/HASH/i) {

                # If the pattern is a true comprehensive regexp or the route
                # has a :variable element to it, then omit it. Dancer 2 also
                # has /** entries - we'll dump them too.
                next get_route if ($pattern =~ m/[()[\]|]|:\w/);
                next get_route if ($pattern =~ m{/\*\*});

                # If there is a wildcard modifier, then drop it and have the
                # full route.
                $pattern =~ s/\?//g;

                # Only add any given route once.
                next get_route if grep { $_ eq $pattern } @urls;

                # Other than that, its cool to be added.
                push (@urls, $pattern)
                    if ! grep { $pattern =~ m/^$_/i }
                              @$Dancer::Plugin::SiteMap::OMIT_ROUTES;
            }
        }
    }

    return @sitemap_urls = sort(@urls);
}


1; # End of Dancer::Plugin::SiteMap
__END__

=head1 NAME

Dancer::Plugin::SiteMap - Automated site map for the Dancer web framework.

=head1 SYNOPSIS

    use Dancer;
    use Dancer::Plugin::SiteMap;

Yup, its that simple. Optionally you can omit routes by passing a list of
B<regex patterns> to be filtered out.:

    sitemap_ignore( 'ignore/this/route', 'orthese/.*' );

    # you can make several calls to sitemap_ignore, the new patterns
    # will be added without removing the old ones.
    sitemap_ignore( '/other/route' );

Note that your specified routes will be tied to the beginning of the route,
so if you say C<sitemap_ignore('/path')> then the sitemap will exclude routes
like '/path', but not '/some/other/path'.

You may also tell this plugin to omit all routes disallowed in robots.txt.
In the config.yml of the application:

    plugins:
        SiteMap:
            robots_disallow: /local/path/to/robots.txt

Should you require more HTML around the sitemap, for styling / structure
purposes, you can define the config option html_template.  If this key is
present the sitemap will try to render within the template view named. That view
should be created in the location of your app's views setting as with any other
template and contain at least a <% sitemap %> token.

    plugins:
        SiteMap:
            html_template: 'mysitemap_template.t'

    ---
    <div class="extra_thing">
    <% sitemap %>
    </div>
    ---

Finally, you can change the default route for the sitemap by adding fields to
the plugin config. It's worth noting that this must be a full route path,
ie. start with a slash. Having a route option in the config but with no value
will disable that particular sitemap.

eg, in the config.yml of the application:

    plugins:
        SiteMap:
            xml_route: '/sitemap_static.xml'
            html_route:                           # html sitemap is disabled.

=head1 DESCRIPTION

B<This plugin now supports Dancer 1 and 2!>

Plugin module for the Dancer web framwork that automagically adds sitemap
routes to the webapp. Currently adds /sitemap and /sitemap.xml where the
former is a basic HTML list and the latter is an XML document of URLS.

Currently it only adds staticly defined routes for the GET method.

Using the module is literally that simple... 'use' it and your app will
have a site map.

The HTML site map list can be styled throught the CSS class 'sitemap'

Added additional functionality in 0.06 as follows:

Firstly, fixed the route selector so the sitemap doesn't show the "or not"
operator ('?'), any route defined with a ':variable' in the path or a pure
regexp as thats just dirty.

More importantly, I came across the requirement to not have a few admin pages
listed in the sitemap, so I've added the ability to tell the plugin to ignore
certain routes via the sitemap_ignore keyword.


=head1 AUTHOR

James Ronan, C<< <james at ronanweb.co.uk> >>

=head1 CONTRIBUTORS

Many thanks to the following guys for adding features (and tests!) to this
plugin:

Breno G. de Oliveira, B<GARU> C<< <garu at cpan.org> >>

David Pottage, B<SPUDSOUP> C<< <spudsoup at cpan.org> >>

Xavier Caron, B<XAV> C<< <xav at cpan.org> >>

=head1 BUGS

Please report any bugs or feature requests to the web interface at
L<https://github.com/jamesronan/Dancer-Plugin-SiteMap/issues>.
Alternatively, you can also use the CPAN RT request tracker at
L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SiteMap>

Pull Requests are welcome for bug fixes and features alike. The plugin is under
version control on GitHub at:
L<https://github.com/jamesronan/Dancer-Plugin-SiteMap>

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Dancer::Plugin::SiteMap


You can also look for information at:

=over 4

=item * Github's Issue Tracker

L<https://github.com/jamesronan/Dancer-Plugin-SiteMap/issues>

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Dancer-Plugin-SiteMap>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Dancer-Plugin-SiteMap>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Dancer-Plugin-SiteMap>

=item * MetaCPAN

L<http://metacpan.org/pod/Dancer::Plugin::SiteMap>

=back


=head1 LICENSE AND COPYRIGHT

Copyright 2010-2014 James Ronan.

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

