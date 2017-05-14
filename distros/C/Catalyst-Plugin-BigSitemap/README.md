# Catalyst::Plugin::BigSitemap

## Version 0.9

## Change History 

### 0.9

* Unit tests written 
* Minor bugfix in SitemapBuilder->\_urls\_slice method.  

### 0.02

* Added **sitemap** and **sitemap_as_xml** attributes to the plugin module to make for complete interface compatability with **Catalyst::Plugin::Sitemap 1.0.0**

### 0.01

* Initial version

## Description

A [Catalyst Framework](http://catalystframework.org) Plugin that allows for automatic generation, and caching to disk
of [Sitemap](http://sitemaps.org/protocol.html) and [Sitemap Index](http://sitemaps.org/protocol.html#index) files to support
beyond the 50,000 URL max of a single sitemap, to a maximum of 2.5 billion urls.

```
cpan install Catalyst::Plugin::BigSitemap
```

## Synopsis

### MyCatalystApp.pm
```
use Catalyst qw/BigSitemap/;
```

### MyCatalystApp.conf (Config::General flavored)
```
<Plugin::BigSitemap>
    cache_dir /var/www/myapp/root/sitemaps
    url_base http://mywebsite/
    sitemap_name_format sitemap%d.xml.gz
    sitemap_index_name sitemap_index.xml
</Plugin::BigSitemap>
```

### MyApacheConf.conf

Assuming you have [mod_alias](http://httpd.apache.org/docs/2.2/mod/mod_alias.html#aliasmatch) installed
and you want to store your sitemap files on the disk and serve them straight through apache (Seriously.. 
if your sitemaps are large enough to warrant using this module, then you definitely don't want to be 
building and serving from Catalyst for each request..)

```
<VirtualHost *.80>
    ... your standard configuration ... 
    Alias /sitemap_index.xml /var/www/mysite/root/sitemaps/sitemap_index.xml
    AliasMatch ^/sitemap(\d+).xml.gz$ /var/www/mysite/root/sitemaps/sitemap$1.xml.gz
</VirtualHost>
```

### MyController.pm
```
#
# Actions you want included in your sitemap.  In this example, there's a total of 10 urls that will be written
#

sub single_url_action :Local :Args(0) :Sitemap() { ... }
sub single_url_with_attrs : Local :Args(0) :Sitemap( loc => 'http://www.mysite/here', changefreq => 'daily', priority => '0.5' ) { ... }

sub multiple_url_action :Local :Args(1) :Sitemap('*') { ... }    
sub multiple_url_action_sitemap {
    my ( $self, $c, $sitemap ) = @_;
    
    # just add 8 more arbitrary urls
    my $a = $c->controller('MyController')->action_for('multiple_url_action');
    for (my $i = 0; $i < 8; $i++) {
        my $uri = $c->uri_for($a, [ $i, ]);
        $sitemap->add( $uri );
    }
    
}

#
# Action to rebuild your sitemaps and writes them to your harddisk 
# !!! You want to protect this !!!
# Best thing to do would be manually instantiate an instance of your
# application from the cron job, mark this method private and call it.  
# You could also go crazy and use WWW::Mechanize .. or hell.. leave it
# public and call it from your browser.. your call.  I wouldn't do that, 
# though ;) 
# Your old sitemap files will automatically be overwritten each time this
# is called.
#

sub rebuild_cache :Private {
    my ( $self, $c ) = @_;
    $c->write_sitemap_cache();
}

#
# Serving the sitemap files is best to do directly through apache.. 
# New version of catalyst have depreciated regex actions, which
# makes doing sitemap files a little more difficult (though you
# can still manually include support for regex actions)
# 
# Also, if you only have a single sitemap, and want to use this like 
# Catalyst::Plugin::Sitemap, see sub single_sitemap below. 
#

sub sitemap_index :Private {
    my ( $self, $c ) = @_;
    
    my $smi_xml = $c->sitemap_builder->sitemap_index->as_xml;
    $c->response->body( $smi_xml );
}

sub single_sitemap :Private {
    my ( $self, $c ) = @_;
    
    my $sm_xml = $c->sitemap_builder->sitemap(0)->as_xml;
    $c->response->body( $sm_xml );
}
```

## Note

This is designed to _almost_ be a drop-in replacement for the existing [Catalyst::Plugin::Sitemap](https://metacpan.org/module/Catalyst::Plugin::Sitemap), 
and the URL attributes work the exact same way.  Your controller actions are attributed in the EXACT same way.  
The only difference is when you want to serve your sitemap file.

## TODO List

* Allow for lastmodified on SitemapIndex files.  

