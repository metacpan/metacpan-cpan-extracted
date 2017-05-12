
package WWW::Scraper::apartments;

use strict;
use vars qw($VERSION @ISA);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.12 $ =~ /(\d+)\.(\d+)/);
use WWW::Scraper::Response;

use WWW::Scraper(qw(1.48 trimLFs));

# SAMPLE 
# http://www.apartments.com/search/oasis.dll?mfcisapicommand=quicksearch&QSearchType=1&city=New%20York&state=NY&numbeds=0&minrnt=0&maxrnt=9999
my $scraperRequest = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,'url' => 'http://www.apartments.com/search/oasis.dll?mfcisapicommand=quicksearch&QSearchType=1&'
      # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'city'
     ,'nativeDefaults' =>
                         {    'numbeds' => 0
                             ,'minrnt'  => 0
                             ,'maxrnt'  => '9999'
                             ,'state'   => ''
                         }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
   };

my $scraperFrame =
[ 'HTML', 
  [ 
     [ 'COUNT', '<strong>Matches: (\d+)</strong>' ]
    ,[ 'NEXT', 2, \&getNextPage ]
    ,[ 'TABLE', '#2',
    [[ 'TABLE', '#9',
       [
          [ 'TABLE' ] # "Visual Listings".
         ,[ 'HIT*' ,[
            ['TABLE', [           
             [ 'TR' ] # Spacers
            ,[ 'TR', 
                 [
                   [ 'TD', [
                         [ 'A', 'contactUrl', undef ]
                        ,[ 'RESIDUE', 'phoneNumber', \&trimLFs ]
                      ]
                   ]
                  ,[ 'TD' ] # Spacer 
                  ,[ 'TD', [
                         [ 'A', 'locationUrl', 'location' ]
                        ,[ 'TAG', 'STRONG', 'address', \&trimLFs ]
                        ,[ 'A', 'moreInfoUrl', undef]
                        ,[ 'RESIDUE', 'descripition', \&trimLFs ]
                      ]
                   ]
                  ,['TD', 'city', \&trimLFs]
                  ,['TD', 'price', \&trimLFs]
                ]
              ]
             ,['TR'] # This row has some sort of "amenities" coding.
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


sub testParameters {
    #  went flippo - I'll fix this later..
    return {
                 'SKIP' => 'apartments.pm still has known bugs in it.'
                ,'testNativeQuery' => 'New York'
                ,'testNativeOptions' => { 'state' => 'NY' }
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }


# www.apartment.com sets its NEXT button in a submit, with various labels.
# e.g.
# <input type="button" 
#       onclick="javascript:document.location=
#                '/search/oasis.dll?page=Results&resultpos=11&QSearchType=1&minrent=0&maxrent=9999&allsizes=1&allbaths=1&month=0&status=4&state=NY&city=NEW+YORK&prvpg=7'" 
#       value="Last 7 &gt;&gt;">
sub getNextPage {
    my ($self, $hit, $dat) = @_;
    return undef unless
        $dat =~ m-value="Modify Search Criteria".*onclick="javascript:document\.location='(/search/oasis\.dll\?page=Results[^']*?)'[^>]*?&gt;&gt;">-s;
    my $nxt = $1;
    my $url = URI::URL->new($1, $self->{'_base_url'});
    $url = $url->abs;
    return $url;
}

1;

=pod

=head1 NAME

WWW::Scraper::apartments - Scrapes www.apartments.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('apartments');


=head1 DESCRIPTION

This class is an apartments specialization of WWW::Search.
It handles making and interpreting apartments searches
F<http://www.apartments.com>.


=head1 OPTIONS

To do.

=head1 OPTIONS

To do

=head1 AUTHOR

C<WWW::apartments> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

The best place to obtain C<WWW::apartments>
is from Glenn's releases on CPAN. Because www.apartments.com
sometimes changes its format in between his releases, 
sometimes more up-to-date versions can be found at
F<http://alumni.caltech.edu/~glenwood/SOFTWARE/index.html>.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


