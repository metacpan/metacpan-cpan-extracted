
package WWW::Scraper::techies;

=pod

=head1 NAME

WWW::Scraper::techies - Scrapes www.techies.com


=head1 SYNOPSIS

    require WWW::Scraper;
    $search = new WWW::Scraper('techies');

Unfortunately, this one does not work. I've included it here in the hope
that somebody can figure it out, since I can't.

It seems no matter what I do, techies.com responds with a demand that I
"enable cookies on your browser". I'm sure cookies are enabled via Search.pm
for techies.pm, so there's something fishy going on with this that I can't figure out.

=head1 DESCRIPTION

This class is an techies specialization of WWW::Scraper.
It handles making and interpreting techies searches
F<http://www.techies.com>.


=head1 OPTIONS

    location => a location string (becomes part of the URL).
                pick from (as of 28.May.2001)

    Alaska ( for AK )
    Midsouth ( for AL )
    Midsouth ( for AR )
    Phoenix ( for AZ )
    Bayarea ( for CA - Bay Area )   
    Losangeles ( for CA - Los Angeles Area )
    Sacramento ( for CA - Sacramento )
    Sandiego ( for CA - San Diego )
    Denver ( for CO )
    Hartford ( for CT - Hartford )
    Newyork ( for CT - NYC / Stamford )
    dc ( for DC )
    Philadelphia ( for DE )
    Southflorida ( for FL - Miami )
    Centralflorida ( for FL - Orlando / Tampa )
    Atlanta ( for GA )
    Hawaii ( for HI )
    Greatplains ( for IA )
    Mountain ( for ID )
    Chicago ( for IL - Chicago )
    Stlouis ( for IL - Southern  )
    Indianapolis ( for IN )
    Kansascity ( for KS )
    Cincinnati ( for KY )
    Midsouth ( for LA )
    Boston ( for MA )
    dc ( for MD )
    Boston ( for ME )
    Detroit ( for MI )
    Twincities ( for MN )
    Kansascity ( for MO - Kansas City )
    Stlouis ( for MO - St. Louis )
    Midsouth ( for MS )
    Mountain ( for MT )
    Northcarolina ( for NC )
    Greatplains ( for ND )
    Greatplains ( for NE )
    Boston ( for NH )
    Newyork ( for NJ - Northern / Central )
    Philadelphia ( for NJ - Southern )
    Phoenix ( for NM )
    Lasvegas ( for NV )
    Newyork ( for NY - NYC )
    Upstatenewyork ( for NY - Upstate )
    Cincinnati ( for OH - Cincinnati )
    Cleveland ( for OH - Cleveland )
    Columbus ( for OH - Columbus )
    Greatplains ( for OK )
    Portland ( for OR )
    Philadelphia ( for PA - Philadelphia )
    Pittsburgh ( for PA - Pittsburgh )
    Boston ( for RI )
    Northcarolina ( for SC )
    Greatplains ( for SD )
    Midsouth ( for TN )
    Austin ( for TX - Austin )
    Dallas ( for TX - Dallas / Ft Worth )
    Houston ( for TX - Houston )
    Saltlake ( for UT )
    dc ( for VA )
    Boston ( for VT )
    Seattle ( for WA )
    Wisconsin ( for WI )
    dc ( for WV )
    Denver ( for WY )
    headhunterjobs ( for Headhunter Jobs )


=head1 AUTHOR

C<WWW::Scraper::techies> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut


#####################################################################

@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.02 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(1.48 trimTags));

use strict;

# SAMPLE
# "http://" + marketurl + ".techies.com/Common/Includes/Main/Search_Session_include_m.jsp?Search=" + escape(searchString)
#
my $scraperRequest = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
     # This is the basic URL on which to build the query.
     ,'url' => \&makeURL
     # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'Search'
     ,'nativeDefaults' => {
                            'Location' => undef
                          }
     ,'fieldTranslations' =>
             {
                 '*' =>
                     {    '*'             => '*'
                     }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 1
   };

my $scraperFrame =
[ 'HTML', 
  [ 
      [ 'COUNT', '<strong>Matches: (\d+)</strong>' ]
     ,[ 'NEXT', 1, '<img src="/Common/Graphics/Buttons/Next\.gif" border="0">' ]
     ,[ 'BODY', undef, 'src="/Common/Graphics/Buttons/NewSearch.gif"', # result, by the same name!
         [  
            ['TABLE'],['TABLE'],
           ,['TABLE', 
              [
                [ 'HIT*' , 'Job',
                   [
                      [ 'TR', 
                         [
                            [ 'TD', 
                                [ [ 'A', 'url', 'title' ]
                                 ,[ 'A', 'companyURL', 'company' ]
                                 ,[ 'RESIDUE', 'description', \&trimTags ]
                                ]
                             ]
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
    my ($self) = @_;

    if ( ref $self ) {
        $self->{'isTesting'} = 1;
        $self->techiesLocation('bayarea'); # Set location for test.pl
    }

    return {
                 'SKIP' => "techies - 'Please enable your cookies' comes up even though cookies are enabled!"
                ,'TODO' => "techies - 'Please enable your cookies' comes up even though cookies are enabled!"
                ,'testNativeQuery' => 'Java'
                ,'expectedOnePage' => 9
                ,'expectedMultiPage' => 11
                ,'expectedBogusPage' => 0
                ,'usesPOST' => 0
           };
}

# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest  { $scraperRequest }
sub scraperFrame  { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail { undef }

sub techiesLocation {
    $_[0]->scraperRequest()->{'nativeDefaults'}{'Location'} = $_[1];
}


sub makeURL {
    my ($self, $native_query, $native_options_ref) = @_;
    my $location = $self->scraperRequest()->{'nativeDefaults'}{'Location'};
    unless ( defined $location ) {
        print STDERR "www.techies.com requires that you set a native value for 'Location'.\nSee http://www.techies.com, and set with method Scraper::techies::techiesLocation().\n";
        return undef;
    }
    my $url = "http://$location.techies.com/Common/Includes/Main/Search_Session_include_m.jsp?";
    undef $native_options_ref->{'Location'}; # This is already in the URL, don't let Scraper.pm add it again.
    $self->{'_http_method'} = 'POST';
    return $url;
}

1;
