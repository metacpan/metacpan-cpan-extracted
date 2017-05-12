package WWW::Scraper::Response::News;


=head1 NAME

WWW::Scraper::Response::News - Response class for scrapes of News Listings


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Scraper::Response::News> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper::Response);
use WWW::Scraper::Response;
$VERSION = sprintf("%d.%02d", q$Revision: 1.1 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $self = WWW::Scraper::Response::new(
         'News'
        ,{
             'relevance' => ''
            ,'authors' => ''
            ,'text' => ''
            ,'section' => ''
            ,'title' => ''
            ,'creation_date' => ''
            ,'posted' => ''
            ,'dateline' => ''
            ,'source' => ''
            ,'description' => ''
            ,'url' => ''
         }
        ,@_);
    return $self;
}

sub GetFieldTitles {
    return {
                'relevance' => 'Relevance'
               ,'authors'   => 'Authors'
               ,'text'      => 'Text'
               ,'section'   => 'Section'
               ,'title'     => 'Title'
               ,'creation_date' => 'Date'
               ,'description' => 'Description'
               ,'url'       => 'URL'
           };
}

1;

