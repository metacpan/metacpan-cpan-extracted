package Catalyst::Plugin::BigSitemap;
use Modern::Perl '2010';
use Catalyst::Plugin::BigSitemap::SitemapBuilder;
use WWW::SitemapIndex::XML;
use WWW::Sitemap::XML;
use Path::Class;
use Carp;
use Moose;

BEGIN { $Catalyst::Plugin::BigSitemap::VERSION = '0.9'; }

=encoding utf8

=head1 NAME 

Catalyst::Plugin::BigSitemap - Auto-generated Sitemaps for up to 2.5 billion URLs.

=head1 VERSION

0.02

=head1 DESCRIPTION

A compete drop-in replacement for L<Catalyst::Plugin::Sitemap> but gives you the 
following features as well.

Additional Functionality:

1. Automatic generation of a sitemap index with multiple sitemap files.

2. Writing sitemap files to disk as XML (can be gzipped as well).

3. Configurable naming of sitemap and sitemap index files.  

4. 2,500,000,000 URL maximum

Even if you don't have a site with more than 50,000 URLS, this module can
write (and rewrite) your sitemap files to disk (something the original L<Catalyst::Plugin::Sitemap> 
module lacks), so you may wish to consider this module for no other reason than that.

=head1 SYNOPSIS

    #
    # Actions you want included in your sitemap.  In this example, there's a total of 10 urls that will be written
    #

    # loc will be automatically resolved for this action
    sub single_url_action :Local :Args(0) :Sitemap() { ... }
    
    # see WWW::Sitemap::XML::URL for all the possible attributes 
    sub single_url_with_attrs : Local :Args(0) :Sitemap( changefreq => 'daily', priority => '0.5' ) { ... }
    
    # If you have multiple urls that map to an action, you need to specify the string '*' as it's only attribute
    # then you must specify a method with the same name plus '_sitemap' as your action method.  Within that action,
    # you'll need to call the ->add method on your sitemap.  
    sub multiple_url_action :Local :Args(1) :Sitemap('*') { ... }    
    sub multiple_url_action_sitemap {
        my ( $self, $c, $sitemap ) = @_;
        
        my $a = $c->controller('MyController')->action_for('multiple_url_action');
        for (my $i = 0; $i < 8; $i++) {
            my $uri = $c->uri_for($a, [ $i, ]);
            $sitemap->add( $uri );
        }
        
    }

    #
    # Action to rebuild your sitemap -- you want to protect this!
    # Best thing to do would be manually instantiate an instance of your
    # application from the cron job, mark this method private and call it.  
    # You could also go crazy and use WWW::Mechanize .. or hell.. leave it
    # public and call it from your browser.. your call.  I wouldn't do that, 
    # though ;) 
    # Your old sitemap files will automatically be overwritten.  
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


=head1 CONFIGURATION

There are a few configuration settings that must be set for this application to function properly.

=over 4

=item cache_dir - B<required>

The absolute filesystem path to where your sitemap file will be written when calling $c->write_sitemap_cache()

=item url_base - I<optional: defaults to whichever base url the request is made to>

This is the base url that will be used when building the urls for your application.

B<Note:> This is important especially if your rebuild is being launched by a cronjob that's
making a request to localhost.  In that case, if you fail the specify this setting, all your
urls will be resolved to http://localhost/my-action-here/ ... That probably isn't what you want.

B<Note:> The trailing slash is important!

=item sitemap_name_format - I<optional: defaults to sitemap%d.xml.gz>

A L<sprintf> format string.  Your sitemaps will be named beginning with 1 up through the total 
number of sitemaps that are necessary to build your data.  By default, this will end up being
something like 

B<Note:> The file extension should either be C<.xml> or C<.xml.gz>.  The proper type of file will be 
built depending on which extension you specify.

=item sitema_index_name - I<optional: defaults to sitemap_index.xml>

B<Note:> Just like with sitename_name_format, .xml or .xml.gz should be specified as the file 
extension.

=back

=head2 L<Config::General> Example

    <Plugin::BigSitemap>
        cache_dir /var/www/myapp/root/sitemaps
        url_base http://mywebsite/
        sitemap_name_format sitemap%d.xml.gz
        sitemap_index_name sitemap_index.xml
    </Plugin::BigSitemap>

=head1 ATTRIBUTES

=over 4

=item sitemap_builder

A lazy-loaded L<Catalyst::Plugin::BigSitemap::SitemapBuilder> object.  If you want access to the individual
L<WWW::Sitemap::XML> or the L<WWW::SitemapIndex::XML> file, you'll do that through this object.

=item sitemap 

B<Provided for compatability with Catalyst::Plugin::Sitemap.>  

Returns a L<WWW::Sitemap::XML> file containing
up to the first 50,000 URLs resolved from your application.

=item sitemap_as_xml

B<Provided for compatability with Catalyst::Plugin::Sitemap>.

Returns a L<XML::LibXML::Document> representation of the sitemap
generated by this module's L<sitemap> attribute.

=back

=cut

has 'sitemap_builder'   => ( is => 'rw', builder => '_get_sitemap_builder', lazy => 1, );
has 'sitemap'           => ( is => 'ro', builder => '_get_sitemap', lazy => 1, );
has 'sitemap_as_xml'    => ( is => 'ro', builder => '_get_sitemap_as_xml', lazy => 1, );

=head1 METHODS

=over 4

=item write_sitemap_cache()

Writes your sitemap_index and sitemap files to whichever cache_dir you've specified in your configuration.

On success, returns an array with the absolute path to the sitemap index (element 0), and all sitemap files.

=back

=cut

sub write_sitemap_cache {
    my $self = shift;

    my $cache_dir   = dir( $self->config->{'Plugin::BigSitemap'}->{cache_dir} || croak 'cache_dir setting MUST be specified in your app\'s config' );
    
    my $sitemap_index_filename = $self->config->{'Plugin::BigSitemap'}->{sitemap_index_name} || 'sitemap_index.xml';
    my $sitemap_index_full_name = $cache_dir->file($sitemap_index_filename)->stringify;    
    
    $self->sitemap_builder->sitemap_index->write( $sitemap_index_full_name );         
    
    my @sitemaps_written;
    for (my $i = 0; $i < $self->sitemap_builder->sitemap_count; $i++) {  
              
        my $filename    = sprintf($self->sitemap_builder->sitemap_name_format, ($i + 1));        
        my $full_name   = $cache_dir->file($filename)->stringify;        
    
        $self->sitemap_builder->sitemap($i)->write( $full_name );
        
        push @sitemaps_written, $full_name;        
    }
    
    return ( $sitemap_index_full_name, @sitemaps_written );
}

=head1 INTERNAL USE METHODS

Methods you shouldn't be calling directly.. They're listed here for documentation purposes.

=over 4

=item _get_sitemap_builder()

Returns a sitemap builder object that's fully populated with all the sitemap urls registered.
This can take quite some time depending on the number of urls you're registering with the sitemap
and how they're being generated.  

You shouldn't ever need to call this directly -- it's set as the builder method for the L<sitemap_builder> attribute.

B<Note>:  This can take an incredibly long time especially if you have a lot of URLs!  Use with care!

=item _get_sitemap()

Builder method for sitemap attribute. 

=item _get_sitemap_as_xml()

Builder method for sitemap_as_xml attribute.

=back

=cut

sub _get_sitemap_builder {
    my $self = shift;
    
    # setup our builder
    my $sb = Catalyst::Plugin::BigSitemap::SitemapBuilder->new(
        sitemap_base_uri    => $self->config->{'Plugin::BigSitemap'}->{url_base} || $self->req->base,
        sitemap_name_format => $self->config->{'Plugin::BigSitemap'}->{sitemap_name_format} || 'sitemap%d.xml.gz',
    );
    
    # Ugly ugly .. but all we're doing here is looping over every action of every controller in our application.
    foreach my $controller ( map { $self->controller($_) } $self->controllers ) {          
        ACTION: 
        foreach my $action ( map { $controller->action_for( $_->name ) } $controller->get_action_methods ) {

            # Make sure there's at least one sitemap action .. 
            # Throw an exception if there's more than one sitemap attribute
            my $attr = $action->attributes->{Sitemap} or next ACTION;
            croak "more than one attribute 'Sitemap' for sub " if @$attr > 1;

            my @attr = split /\s*(?:,|=>)\s*/, $attr->[0];

            my %uri_params;

            if ( @attr == 1 ) {                
                if ( $attr[0] eq '*' ) {
                    my $sitemap_method = $action->name . "_sitemap";

                    if ( $controller->can($sitemap_method) ) {
                        $controller->$sitemap_method( $self, $sb );
                        next ACTION;
                    }
                }

                if ( $attr[0] + 0 > 0 ) {
                    # it's a number 
                    $uri_params{priority} = $attr[0];
                }
            }
            elsif ( @attr > 0 ) {
                %uri_params = @attr;
            }

            $uri_params{loc} = $self->uri_for_action( $action->private_path );
            $sb->add(%uri_params);
                               
        } # foreach $action             
    } # foreach $controller
    
    return $sb;
}

sub _get_sitemap { $_[0]->sitemap_builder->sitemap(0) }

sub _get_sitemap_as_xml { $_[0]->sitemap->as_xml }

=head1 ACKNOWLEDGEMENTS

This module is based on the great work of two other CPAN authors:

L<< Yanick Champoux|http://search.cpan.org/~yanick/ >> - Author of the original L<Catalyst::Plugin::Sitemap>
module.  Some of his ideas (and some of his module code) was used to make this module.

L<< Alex J. G. Burzyński|http://search.cpan.org/~ajgb/ >> - Author of L<WWW::Sitemap::XML>, which is the underlying
module used by BigSitemap to do it's work.

=head1 SEE ALSO

L<Catalyst::Plugin::Sitemap>, L<WWW::Sitemap::XML>, L<< Sitemaps.org|http://www.sitemaps.org/ >>, L<< Catalyst Framework|http://catalystframework.org/ >>

=head1 AUTHOR

Derek J. Curtis C<< <djcurtis at summersetsoftware dot com>> >>

Summerset Software, LLC

L<http://www.summersetsoftware.com>

=head1 LICENSE AND COPYRIGHT

Copyright 2013 Derek J. Curtis.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

=cut

1;
