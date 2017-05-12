package WWW::Scraper::Response::Job;


=head1 NAME

WWW::Scraper::Response::Job - result class for scrapes of Job Listings


=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 AUTHOR

C<WWW::Scraper::Response::Job> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=cut

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper::Response);
use WWW::Scraper::Response;
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

sub new {
    my $self = WWW::Scraper::Response::new(
         'Job'
        ,{
             'relevance' => ''
            ,'title' => ''
            ,'description' => ''
            ,'companyProfileURL' => ''
            ,'company' => ''
            ,'location' => ''
            ,'postDate' => ''
            ,'url' => ''
         }
        ,@_);
    return $self;
}

sub FieldTitles {
    return {
                'relevance'  => 'Relevance'
               ,'title'      => 'Title'
               ,'description' => 'Description'
               ,'companyProfileURL'    => 'Company Profile URL'
               ,'company'    => 'Company'
               ,'location'   => 'Location'
               ,'postDate'   => 'Post-Date'
               ,'url'        => 'URL'
           };
}

1;

