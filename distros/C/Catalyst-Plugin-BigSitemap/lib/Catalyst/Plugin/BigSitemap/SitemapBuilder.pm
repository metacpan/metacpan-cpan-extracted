package Catalyst::Plugin::BigSitemap::SitemapBuilder;
use Modern::Perl '2010';
use WWW::Sitemap::XML;
use WWW::Sitemap::XML::URL;
use WWW::SitemapIndex::XML;
use Carp;
use Try::Tiny;
use Data::Dumper;
use Moose;

=head1 NAME 

Catalyst::Plugin::BigSitemap::SitemapBuilder - Helper object for the BigSitemap plugin

=head1 VERSION

0.02

=head1 DESCRIPTION

This object's role is to accept a collection of L<WWW::Sitemap::XML::URL> objects via the L<add>
method.  

=head1 CONSTRUCTOR

There are two required parameters that must be passed to the constructor, L<sitemap_base_uri> and
L<sitemap_name_format>.  


=head1 ATTRIBUTES

=shift 4

=item urls - I<ArrayRef> of L<WWW::Sitemap::XML::URL>

A collection of every URL in your application that will be included in the sitemap.

=item sitemap_base_uri - L<URI::http>

The base URI that should be used when resolving the action urls in your application.  
You should really specify this manually, in the event that one day you want to start
run this module from a cron job.

=item sitemap_name_format - I<Str>

A sprintf style format for the names of your sitemap files.  Note:  The names of the sitemap files
will start by inserting the number 1 and incrementing for each sitemap file written.  It's important
to note that in code, calls to the sitemap method use a 0-based-index but your sitemap filenames are
1-based.  This is just that way so the names of the individual sitemaps match to the examples given
on the L<http://www.sitemaps.org> website.

=item failed_count - I<Int>

A running count of all the URLs that failed validation in the L<WWW::Sitemap::XML::URL> module and could not 
be added to the collection.. This should always report zero unless you've screwed something up in your
C<sub my_action_sitemap> controller methods.

=back

=cut

has 'urls'               => ( is => 'rw', isa => 'ArrayRef[WWW::Sitemap::XML::URL]', default => sub { [] } );
has 'sitemap_base_uri'   => ( is => 'ro', isa => 'URI::http' );
has 'sitemap_name_format'=> ( is => 'ro', isa => 'Str' );
has 'failed_count'       => ( is => 'rw', isa => 'Int', default => 0 );

=head1 METHODS

=over 4

=item add( $myUrlString )
=item add( $myUriObject )
=item add( loc => ? [, changefreq => ?] [, priority => ?] [, lastmod => ?] )

This method comes in three flavors.  The first, take a single string parameter that should be the stringified version of the
URL you want to add to the sitemap. The second, takes a URI::http object.  The last flavor takes a hashref containing all your
input parameters. 

=item urls_count() = Int

.. how many urls total have been added to the builder.

=item sitemap_count() - Int

.. how many total sitemap files can be built with this data.

=item sitemap_index() - L<WWW::SitemapIndex::XML>

Generates and returns a new sitemapindex object based on the urls currently in this object's
urls collection, the sitemap_base_uri and the sitemap_name_format setting.  

=item sitemap($index) - L<WWW::Sitemap::XML>

Generates and returns a new sitemap object based at your requested index.

B<Note:> $index is a 0-based index of the sitemap you want to retrieve. 

=back

=cut

sub add {
    my $self = shift;
    my @params = @_;
    
    # create our url object.. for compatability with Catalyst::Plugin::Sitemap
    # we allow a single string parameter to be passed in.
    my $u;
    try {
        if (@params == 0) {
            croak "method add() requires at least one argument.";
        }
        elsif (@params == 1){  
            $u = WWW::Sitemap::XML::URL->new(loc => $params[0]);
        }
        elsif (@params % 2 == 0) {       
            my %ph = @params;      
            $u = WWW::Sitemap::XML::URL->new(%ph);
        }        
        else {                        
            croak "method add() requires either a single argument, or an even number of arguments.";  
        }
        
        push @{$self->urls}, $u;        
    }
    catch {   
        $self->failed_count($self->failed_count + 1);
    };
    
}

sub urls_count {
    my $self = shift;    
    return scalar @{$self->urls};
}

sub sitemap_count {
    my $self = shift;
    
    my $whole_pages     = int ( $self->urls_count / 50_000 );
    my $partial_pages   = $self->urls_count % 50_000 ? 1 : 0; 
    
    return $whole_pages + $partial_pages;    
}

sub sitemap_index {
    my $self = shift;
    
    my $smi = WWW::SitemapIndex::XML->new();
    
    for (my $index = 0; $index < $self->sitemap_count; $index++) {   
        # TODO: support lastupdate
        $smi->add( loc => $self->sitemap_base_uri->as_string . sprintf($self->sitemap_url_format, ($index + 1)) );
    }
    
    return $smi;    
}

sub sitemap {
    my ( $self, $index ) = @_;    
    
    my @sitemap_urls = $self->_urls_slice( $index );
    
    my $sm = WWW::Sitemap::XML->new();
    
    foreach my $url (@sitemap_urls) {
        try{            
            $sm->add($url);    
        }
        catch{
            warn "Problem adding url to sitemap: " . Dumper $url;    
        };
    }
    
    return $sm;    
}

=head1 INTERNAL USE METHODS

Methods you're not meant to use directly, so don't!  They're here for documentation
purposes only.

=over 4

=item _urls_slice($index)

Returns an array slice of URLs for the sitemap at the provided index.  
Sitemaps can consist of up to 50,000 URLS, when creating the slice, 
we use the assumption that we'll try to get up to 50,000 per each 
sitemap.

=back

=cut

sub _urls_slice {
    my ( $self, $index ) = @_;
    
    my $start_index = $index * 50_000;
    my $end_index   = 0;
    
    if ($index + 1 == $self->sitemap_count) {
        $end_index  = ($self->urls_count % 50_0000) - 1;        
    }
    else {
        $end_index  = $start_index + (50_000 - 1); 
    }
        
    return @{$self->urls}[$start_index .. $end_index];    
}

=head1 SEE ALSO

=head1 AUTHOR

Derek J. Curtis C<djcurtis at summersetsoftware dot com>

=head1 COPYRIGHT

Derek J. Curtis 2013

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;