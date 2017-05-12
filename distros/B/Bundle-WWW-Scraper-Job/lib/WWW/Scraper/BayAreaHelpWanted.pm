
package WWW::Search::Scraper::BayAreaHelpWanted;


#####################################################################
use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Search::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.0 $ =~ /(\d+)\.(\d+)/);

use WWW::Search::Scraper(qw(1.48 trimLFs trimLFLFs removeScriptsInHTML trimTags trimXPathHref cleanupHeadBody));


# SAMPLE
# http://bayareahelpwanted.com/Search/index.cfm?SN=194&S=Perl&A=all&D=short&RP=datedesc&M=25&R=1
my $scraperRequest = 
   { 
      'type' => 'QUERY'
     # This is the basic URL on which to build the query.
     ,'url' => 'http://bayareahelpwanted.com/Search/index.cfm?'
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'S'
     ,'defaultRequestClass' => 'Job'
     ,'nativeDefaults' =>
                      {    
                          #'SN' => '1984' # unnecessary
                           'A' => 'All'
                          ,'D' => 'short'
                          ,'RP' => 'datedesc'
                          ,'M' => '25'
                          ,'R' => '1' # unnecessary
                      }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    'skills' => 'S'
                         ,'*'        => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'TidyXML', \&removeScriptsInHTML, \&cleanupHeadBody, 
    [ 
        [ 'COUNT', 'Your search returned (\d+) help wanted ads' ]
       ,[ 'NEXT', 'Job Search Results \d+-\d+ &gt;&gt;' ]
       ,[ 'XPath', '/html/body/table/tr/td[2]/table/tr/td/form/table[6]', 
                    [  
                        [ 'HIT*',
                            [ 
                                [ 'XPath', 'tr[ ( hit() * 2 ) ]',
                                    [
                                        [ 'XPath', 'td[2]/i/a/@href', 'url', \&trimXPathHref ]
                                       ,[ 'XPath', 'td[2]/i/a/b/text()', 'title', \&trimTags, \&trimLFs ]
                                       ,[ 'XPath', 'td[3]/font/b/text()', 'headline', \&trimTags, \&trimLFs ]
                                       ,[ 'XPath', 'td[4]/b/text()', 'company', \&trimTags, \&trimLFs ]
                                       ,[ 'XPath', 'td[5]/font/text()', 'postdate', \&trimTags, \&trimLFs ]
                                    ]
                                ]
                            ]
                        ]
                    ]
        ]
    ]
];


sub init {
    my ($self) = @_;
    $self->searchEngineHome('http://www.BayAreaHelpWanted.com');
#    $self->searchEngineLogo('<IMG SRC="http://www.BayAreaHelpWanted.com/images/nav/BayAreaHelpWanted_job_careers_here.gif">');
    return $self;
}


sub testParameters {
    my ($self) = @_;
    
    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    return {
                 'SKIP' => &WWW::Search::Scraper::TidyXML::isNotTestable('BayAreaHelpWanted')
                .'TODO' => 'Changed their format(?). How can I keep up with these, that is the question.'
                ,'testNativeQuery' => 'Service'
                ,'expectedOnePage' => 24
                ,'expectedMultiPage' => 26
                ,'expectedBogusPage' => 0
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

1;

__END__
=pod

=head1 NAME

WWW::Search::Scraper::BayAreaHelpWanted - Scrapes www.BayAreaHelpWanted.com


=head1 SYNOPSIS

    use WWW::Search::Scraper;
    use WWW::Search::Scraper::Response::Job;

    $search = new WWW::Search::Scraper('BayAreaHelpWanted');

    $search->setup_query($query, {options});

    while ( my $response = $scraper->next_response() ) {
        # $response is a WWW::Search::Scraper::Response::Job.
    }

=head1 DESCRIPTION

BayAreaHelpWanted extends WWW::Search::Scraper.

It handles making and interpreting BayAreaHelpWanted searches of F<http://www.BayAreaHelpWanted.com>.

=head1 AUTHOR

C<WWW::Search::BayAreaHelpWanted> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


