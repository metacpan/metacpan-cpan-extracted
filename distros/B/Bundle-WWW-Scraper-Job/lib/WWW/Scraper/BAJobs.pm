
package WWW::Scraper::BAJobs;

#####################################################################

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(1.48 generic_option addURL trimTags));
use WWW::Scraper::FieldTranslation;

use LWP::UserAgent;
use HTML::Form;
use HTTP::Cookies;

# As of 2002.01.26, this is what BAJobs "Refine your search" <FORM> looks like.
#<form action="/jobseeker/usersearch.jsp" method=post>
#  <input type="hidden" name="searchKeywordsMethod" value=1>
#  <input type="hidden" name="wholeWord" value="true">
#  <input type="hidden" name="displayResultsPerPage" value="20">
#  <input type="hidden" name="displaySortOrder" value="1">
#  <input type="hidden" name="postingAge" value="7">
#  <input type="hidden" name="countyList" value="">
#  <input type="hidden" name="workTermTypeList" value="">
#  <input type="hidden" name="jobPostingCategoryList" value="">
#  <input type="hidden" name="industryCategoryList" value="">
#  <p><b><font color=006699 face="arial,helvetica,sans-serif">Refine Your Search</font></b>
#  <br>
#  <input type=text name="searchKeywords" value=" Perl " size=40> &nbsp; &nbsp; <input type=submit value="Search">
#</form>

my $scraperRequest = 
   { 
      'type' => 'POST'  # 'POST' - we used to use 'FORM', which works fine, too, but this way's a little faster.
     
     # This is the basic URL on which to build the query.
     ,'url' => 'http://www.bajobs.com/jobseeker/usersearch.jsp?'
     #,'url' => 'http://www.bajobs.com/jobseeker/search.jsp' # This one is the location of the <FORM>
     
     ,'nativeQuery' => 'searchKeywords'
     
     ,'nativeDefaults' =>
                            {
                                 'searchKeywordsMethod' => 1
                                ,'wholeWord' => 'true'
                                ,'displayResultsPerPage' => '100'
                                ,'displaySortOrder' => 1
                                ,'postingAge' => '7'
                                ,'countyList' => ''
                                ,'workTermTypeList' => ''
                                ,'jobPostingCategoryList' => ''
                                ,'industryCategoryList' => ''
                            }
     ,'defaultRequestClass' => 'Job'
     ,'fieldTranslations' =>
                      { '*' => 
                              {    'skills'    => 'searchKeywords'
                                  ,'payrate'   => undef
                                  ,'locations' => new WWW::Scraper::FieldTranslation('BAJobs', 'Job', 'locations')
                                  ,'*'         => '*'
                              }
                      }
      # Some more options for the Scraper operation.
     ,'cookies' => 1
   };

my $scraperFrame =
        [ 'HTML', 
           [ 
               [ 'COUNT', 'Job Postings.*?[- 0-9]+.*?of.*?<b>([,0-9]+)</b></font> total']
              ,[ 'BODY', '<!-- top prev/next -->', '<!-- end top prev/next -->',
                 [ 
               [ 'NEXT', 1, '<b>NEXT</b>' ]
                ] #, \&fixNext ] ]
               ]
              ,[ 'BODY', '<!-- job list -->', '',
                 [  
                    [ 'TABLE', '#0' ,
                       [
                          [ 'TR' ] , # There's an actual title row! Imagine that!
                          [ 'HIT*' ,
                            [  
                               [ 'TR',
                                  [
                                     [ 'TD', [ [ 'A', 'corpURL', 'corporateBackground' ] ] ]
                                    ,[ 'TD', 'postingDate' ]
                                    ,[ 'A', 'url', 'title' ]
                                    ,[ 'TD', 'company' ]
                                    ,[ 'TD', '_clear_gif_' ]
                                    ,[ 'TD', 'location' ]
                                  ]
                               ]
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
    $self->searchEngineHome('http://www.BAJobs.com');
    $self->searchEngineLogo('<IMG SRC="http://www.bajobs.com/graphics/bajlogo118x80.gif">');
    return $self;
}

sub testParameters {
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
    }
    
    # 'POST' style scraperFrames can't be tested cause of a bug in WWW::Search(2.2[56]) !
    my $isNotTestable = WWW::Scraper::isGlennWood()?'':'';
    return { 
             'SKIP' => $isNotTestable
            ,'testNativeQuery' => 'Sales'
            ,'expectedOnePage' => 9
            ,'displayResultsPerPage' => 10
            ,'expectedMultiPage' => 11
            ,'expectedBogusPage' => 0
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }


1;


=pod

=head1 NAME

WWW::Scraper::BAJobs - Scrapes BAJobs.com

=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('BAJobs');


=head1 DESCRIPTION

This class is an BAJobs specialization of WWW::Search.
It handles making and interpreting BAJobs searches
F<http://www.BAJobs.com>.

This class exports no public interface; all interaction should
be done through WWW::Search objects.


=head1 OPTIONS

None at this time (2001.05.06)

=over 8

=item search_url=URL

Specifies who to query with the BAJobs protocol.
The default is at
C<http://www.BAJobs.com/cgi-bin/job-search>.

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back

=head1 SEARCH FIELDS

=head2 displayResultsPerPage - I<Results per Page>

=over 8

=item "5" => 5

=item "10" => 10

=item "20" => 20

=item "50" => 50

=item "100" => 100

=back

=head2 postingAge - I<Age of Posting>

=over 8

=item "0" => any time

=item "1" => 1 day

=item "3" => 3 days

=item "7" => 1 week

=item "8" => 2 weeks

=item "10" => 1 month

=back

=head2 workTermTypeIDs - I<Work Term>

=over 8

=item "1" => Full Time

=item "2" => Part Time

=item "3" => Contract

=item "4" => Temporary/Seasonal

=item "5" => Internship

=back

=head2 countyIDs - I<Job Location-County>

=over 8

=item "0" => Any

=item "1" => Alameda

=item "2" => Contra Costa

=item "3" => Marin

=item "4" => Napa

=item "5" => San Benito

=item "6" => San Francisco

=item "7" => San Mateo

=item "8" => Santa Clara

=item "9" => Santa Cruz

=item "10" => Solano

=item "11" => Sonoma

=item "12" => Other

=back

=head2 jobPostingCategoryIDs => I<Job Category>

=over 8

=item "0" => Any

=item "1" => Accounting/Finance

=item "2" => Administrative/Clerical

=item "3" => Advertising

=item "4" => Aerospace/Aviation

=item "5" => Agricultural

=item "6" => Architecture

=item "7" => Arts/Entertainment

=item "8" => Assembly

=item "9" => Audio/Visual

=item "10" => Automotive

=item "11" => Banking/Financial Services

=item "12" => Biotechnology

=item "13" => Bookkeeping

=item "14" => Business Development

=item "15" => Child Care Services

=item "16" => Colleges & Universities

=item "17" => Communications/Media

=item "18" => Computer

=item "19" => Computer - Hardware

=item "20" => Computer - Software

=item "21" => Construction

=item "22" => Consulting/Professional Services

=item "23" => Customer Service/Support

=item "24" => Data Entry/Processing

=item "25" => Education/Training

=item "26" => Engineering

=item "27" => Engineering - Civil

=item "28" => Engineering - Hardware

=item "29" => Engineering - Software

=item "30" => Environmental

=item "31" => Executive/Management

=item "32" => Fund Raising/Development

=item "33" => Government/Civil Service

=item "34" => Graphic Design

=item "35" => Health Care/Health Services

=item "36" => Hospitality/Tourism

=item "37" => Human Resources

=item "38" => Information Technology

=item "39" => Insurance

=item "40" => Internet/E-Commerce

=item "41" => Law Enforcement/Security

=item "42" => Legal

=item "43" => Maintenance/Custodial

=item "44" => Manufacturing

=item "45" => Marketing

=item "46" => Miscellaneous

=item "47" => Non-Profit

=item "48" => Pharmaceutical

=item "49" => Printing/Publishing

=item "50" => Property Management/Facilities

=item "51" => Public Relations

=item "74" => Purchasing

=item "52" => QA/QC

=item "53" => Radio/Television/Film/Video

=item "54" => Real Estate

=item "57" => Receptionist

=item "55" => Recruiting/Staffing

=item "56" => Research

=item "58" => Restaurant/Food Service

=item "59" => Retail

=item "60" => Sales

=item "61" => Sales - Inside/Telemarketing

=item "62" => Sales - Outside

=item "63" => Security/Investment

=item "64" => Shipping/Receiving

=item "65" => Social Work/Services

=item "66" => Technical Support

=item "67" => Telecommunications

=item "68" => Training

=item "69" => Transportation

=item "70" => Travel

=item "71" => Warehouse

=item "72" => Web Design

=item "73" => Writer

=back

=head1 AUTHOR

C<WWW::Scraper::BAJobs> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.


=cut



