package Dancer2::Plugin::Multilang;
{
  $Dancer2::Plugin::Multilang::VERSION = '1.2.0';
}
use Dancer2::Plugin 0.156000;

register 'language' => sub {
    my $dsl = shift;
    return $dsl->app->request->params->{'multilang.lang'};
};

on_plugin_import {
    my $dsl = shift;
    my $conf = plugin_setting();
    my @managed_languages = @{$conf->{'languages'}};
    $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'before', code => sub {
            my $ignore = $conf->{'no_lang_prefix'} || 0;
            my $default_language = $conf->{'default'};
            my $match_string = "^\/(" . join('|', @managed_languages) . ")";
            my $match_regexp = qr/$match_string/;
            my $path = $dsl->app->request->path_info();
            my $method = $dsl->app->request->method();
            if(($ignore && $path !~ /^$ignore/) ||
               ! $ignore )
            {
                my $lang = '';
                if ($path =~ $match_regexp)
                {
                    $lang = $1;
                }
                if($lang eq '')
                {
                    if($dsl->app->request->params->{'multilang.lang'})
                    {
                        $dsl->cookie('multilang.lang' => $dsl->param('multilang.lang'));
                    }
                    else
                    {
                        my $accepted_language = $dsl->app->request->header('Accept-Language') ?
                                                wanted_language($dsl, $dsl->app->request->header('Accept-Language'), @managed_languages) :
                                                '';
                        if($dsl->cookie('multilang.lang'))
                        {
                            $dsl->redirect("/" . $dsl->cookie('multilang.lang') . $path, 307);
                        }
                        elsif($accepted_language ne '')
                        {
                            $dsl->redirect("/$accepted_language" . $path, 307);
                        }
                        else
                        {
                            $dsl->redirect("/$default_language" . $path, 307);
                        }
                    }
                }
                else
                {
                    $path =~ s/$match_regexp//;
                    $dsl->forward($path, {'multilang.lang' => $lang}, { method => $method });
                }
            }
        })
     );
     $dsl->app->add_hook(
        Dancer2::Core::Hook->new(name => 'after', code => sub {
            my $response = shift;
            my $content = $response->{content};
            my @managed_languages = @{$conf->{'languages'}};
            if(my $selected_lan = $dsl->app->request->params->{'multilang.lang'})
            {
                for(@managed_languages)
                {
                    my $lan = $_;
                    if($lan ne $selected_lan)
                    {
                        my $meta_for_lan = '<link rel="alternate" hreflang="' . $lan . '" href="' . $dsl->app->request->base() . $lan . $dsl->app->request->path() . "\" />\n";
                        $content =~ s/<\/head>/$meta_for_lan<\/head>/;
                    }
                }
                $response->{content} = $content;
            }
        })
    );
    for my $l( @managed_languages)
    {
        $dsl->any( ['get', 'post'] => "/" . $l . "/**", sub { $dsl->pass; });
        $dsl->any( ['get', 'post'] => "/" . $l . "/", sub { $dsl->pass; });
    }

};

sub wanted_language
{
    my $dsl = shift;
    my $header = shift;
    my @managed_languages = @_;
    my @lan_strings = split(',', $header);
    for(@lan_strings)
    {
        my $str = $_;
        $str =~ m/^(..?)(\-.+)?$/; #Only primary tag is considered
        my $lan = $1;
        if (grep {$_ eq $lan} @managed_languages) {
            return $lan;
        }
    }
    return '';
};

register_plugin for_versions => [ 2 ];

1;

=encoding utf8

=head1 NAME

Dancer2::Plugin::Multilang - Dancer2 Plugin to create multilanguage sites


=head1 DESCRIPTION

A plugin for Dancer2 to create multilanguage sites. In your app you can configure any route you want as /myroute/to/page.

Plugin will make the app answer to /en/myroute/to/page or /it/myroute/to/page giving the language path to the route manager as a Dancer keyword.
It will also redirect navigation using information from the headers transmitted from the browser. Language change during navigation will be managed via cookie.

Multilanguage SEO headers will be generated to give advice to the search engines about the language of the pages.

=head1 SYNOPSIS

    # In your Dancer2 app,
    use Dancer2::Plugin::Multilang

    #In your config.yml
    plugins:
      Multilang:
        languages: ['it', 'en']
        default: 'it'

    where languages is the array of all the languages managed and default is the response language if no information about language can be retrieved.

    #In the routes
    get '/route/to/page' => sub {
        if( language == 'en' )
        {
            /* english navigation */
        }
        elsif( language == 'it' )
        {
            /* italian navigation */
        }
        elsif...

=head1 USAGE

No language information has to be managed in route definition. Language path will be added transparently to your routes.

language keyword can be used to retrieve language information inside the route manager.

=head1 OPTIONS

The options you can configure are:

=over 4

=item C<languages> (required)

The array of the languages that will be managed.

All the languages are two characters codes as in the primary tag defined by http://www.w3.org/Protocols/rfc2616/rfc2616-sec3.html#sec3.10

=item C<default> (required)

The default language that will be used when plugin can't guess desired one (or when desired one is not managed)

=item C<no_lang_prefix> (optional)

Do not add the language path to the route if it has this prefix. Useful for Google or Facebook authentication callbacks.

    no_lang_prefix: /auth

=back

=cut

