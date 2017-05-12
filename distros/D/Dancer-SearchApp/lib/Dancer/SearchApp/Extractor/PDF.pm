package Dancer::SearchApp::Extractor::PDF;
use strict;
use Carp 'croak';
use Promises 'deferred';
use Dancer::SearchApp::HTMLSnippet;

use vars qw($VERSION);
$VERSION = '0.06';

=head1 File types

        # index pdfs page by page and link to it by #page=10
        # rewrite Tika PDF pages to include the page number for easy snippet
        # location
        # lightning talk ;)

This rewrites the HTML created by Tika for PDF files to include line
numbers.

=cut

sub examine {
    my( $class, %options ) = @_;
    my $info = $options{info};
    
    my $result = deferred;
    my $meta = $options{meta};
    my $mime_type = $meta->{"Content-Type"};
    
    if( $mime_type =~ m!^application/pdf$! ) {
        my %res = (
            url    => $options{ url },
            file   => $options{ filename },
            folder => $options{ folder },
        );
        my $file = $options{ filename };
        
        my $c = $info->content;
        my $r = Dancer::SearchApp::HTMLSnippet->cleanup_tika( $c );

        $res{ title } = $meta->{"dc:title"} || $meta->{"title"} || $file->basename;
        $res{ author } = $meta->{"meta:author"}; # as HTML
        $res{ language } = $meta->{"meta:language"};
        $res{ mime_type } = $meta->{"Content-Type"};
        $res{ content } = $r; # as HTML        
        
        $result->resolve( \%res );
    } else {
        $result->resolve();
    }
    
    $result->promise
}

1;