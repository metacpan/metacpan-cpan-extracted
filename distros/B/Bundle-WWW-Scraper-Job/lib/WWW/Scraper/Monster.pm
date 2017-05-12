
package WWW::Scraper::Monster;

#####################################################################

use strict;
use vars qw(@ISA $VERSION);
@ISA = qw(WWW::Scraper);
$VERSION = sprintf("%d.%02d", q$Revision: 1.07 $ =~ /(\d+)\.(\d+)/);

use WWW::Scraper(qw(1.48 generic_option findNextForm trimLFs));
use WWW::Scraper::Response::Job;
use WWW::Scraper::FieldTranslation(1.00);

#http://jobsearch.monster.com/jobsearch.asp?cy=US&re=14&brd=1%2C1863&lid=883&lid=356&fn=6&q=Perl&sort=rv&vw=b
# detailed
#http://jobsearch.monster.com/jobsearch.asp?re=10&vw=d&pg=1&cy=US&brd=1%2C1863&lid=883&lid=356&fn=6&q=Perl&sort=rv
#http://jobsearch.monster.com/jobsearch.asp?q=Sales&re=13&sort=rv&tm=60d&brd=1%2C1863&cy=US&fn=6&lid=883&lid=356&vw=d
#http://jobsearch.monster.com/jobsearch.asp?brd=1%2C1863&cy=US&fn=6&lid=883&lid=356&q=Sales&re=10&sort=rv&tm=60&vw=d
#http://jobsearch.monster.com/jobsearch.asp?brd=1%2C1863&cy=US&fn=6&lid=883&lid=356&q=Sales&re=13&sort=rv&tm=60&vw=d
my $scraperRequest = 
   { 
      'type' => 'QUERY'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,'url' => 'http://jobsearch.monster.com/jobsearch.asp?'
      # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'q'
     ,'nativeDefaults' =>
                      {    'brd' => '1'
                          ,'cy'  => 'US'
                          ,'fn'  => '6'
                          ,'re'  => '13'
                          ,'brd' => '1,1863'
                          ,'lid'  => ['883',356]
                          ,'sort'  => 'rv'      # 'rv' - by relevance
                          ,'vw'  => 'd'         # 'd'etailed, or 'b'rief
                          ,'tm'  => '60d'
                      }
     ,'defaultRequestClass' => 'Job'
     ,'fieldTranslations' =>
             { '*' => 
                  {    'skills'    => 'q'
#                      ,'payrate'   => \&translatePayrate
#                      ,'locations' => new WWW::Scraper::FieldTranslation('Monster', 'Job', 'locations')
                      ,'*'         => '*'
                  }
             }
      # Some more options for the Scraper operation.
     ,'cookies' => 0
     # Some search engines don't connect every time - retry Monster this many times.
     ,'retry' => 2
   };

my $scraperFrame =
[ 'HTML', 
    [ 
                   #<B>Jobs <B>1</B> to <B>6</B> of <B>6</B></B>
                   #<B>Jobs <B>1</B> to <B>6</B> of more than <B>6,000</B></B>
        [ 'COUNT', 'Jobs \d+ to \d+ of (\d+)' ]  # Jobs 1 to 50 of 241
       ,[ 'NEXT', 1, 'Next' ]
       ,[ 'BODY', '<!-- Jobs \S+ of \S+ -->', undef,
          [
            [ 'TABLE' ]
            ,[ 'TABLE', 
               [
                   [ 'TABLE',
                   [
                      ['TABLE'],['TABLE'],[ 'TABLE' , 
[
['TR'], 
                      [ 'HIT*', 'Job',
                        [ 
                            [ 'TR', 
                                [
                                    [ 'TD', 'postDate' ]
                                   ,[ 'TD', 'location', \&trimLFs ]
                                   ,[ 'TD' ] # spacer.
                                   ,[ 'TD', [ [ 'A', 'url', 'title' ] ] ]
                                   ,[ 'TD', 'company' ]
                                ]
                            ]
                        ]
                    ]
#                   ,[ 'BOGUS', 1 ] # The first row is column titles.
                ]
                ]
                ]
]]
            ]
          ]
        ]
    ]
];

sub testParameters {
    # We can't test Dogpile, or any other TidyXML sub-class, until we know Tidy.exe is accessible.
    return {
                 'SKIP' => ''
                ,'testNativeQuery' => 'Sales'
                ,'expectedOnePage' => 25
                ,'expectedMultiPage' => 27
                ,'expectedBogusPage' => 3
                ,'testNativeDefaults' =>
                                {  'brd' => '1'
                                  ,'cy'  => 'US'
                                  ,'fn'  => '6'
                                  ,'re'  => '13'
                                  ,'brd' => '1,1863'
                                  ,'lid'  => ['883',356]
                                  ,'sort'  => 'rv'      # 'rv' - by relevance
                                  ,'vw'  => 'd'         # 'd'etailed, or 'b'rief
                                  ,'tm'  => '60d'
                                }
           };
}


# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { $scraperRequest; }
sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }


{ package WWW::Scraper::Request::Monster;
use WWW::Scraper::Request;
use vars qw(@ISA);
@ISA = qw(WWW::Scraper::Request);

sub generateQuery {
    my ($self, $query) = @_;

    # Process the inputs.
    # (Now in sorted order for consistency regardless of hash ordering.)
    my $options = $self->{'queryField'}.'='.WWW::Search::escape_query($query);
    my $options_ref = $self->{'optionsRef'};
    foreach (sort keys %$options_ref) {
        my $val = $options_ref->{$_};
        # Handle 'st' specially . . .
        $val =~ s/\+/\,/g if($_ eq 'st');
        # Convert "nam=val1 val2" into "nam=val1&nam=val2"
        $val =~ s/\+/\&$_=/g unless($_ eq 'q');

        $options .= "&$_=".WWW::Search::escape_query($val);
    };
    
    return $self->{'_base_url'}.$options
}

}

# Translate from the canonical Request->payrate to Monster's 'rate' option.
sub translatePayrate {
    my ($self, $rqst, $val) = @_;
    return ('rate', $val);
}


1;


__END__

=pod

=head1 NAME

WWW::Scraper::Monster - Scrapes Monster.com

=head1 SYNOPSIS

 use WWW::Search;
 my $oSearch = new WWW::Search('Monster');
 my $sQuery = WWW::Search::escape_query("unix and (c++ or java)");
 $oSearch->native_query($sQuery,
 			{'st' => 'CA',
			 'tm' => '14d'});
 while (my $res = $oSearch->next_result()) {
     print $res->company . "\t" . $res->title . "\t" . $res->change_date
	 . "\t" . $res->location . "\t" . $res->url . "\n";
 }

=head1 DESCRIPTION

This class is a Monster specialization of WWW::Search.
It handles making and interpreting Monster searches at
F<http://www.monster.com>. Monster supports Boolean logic with "and"s
"or"s. See F<http://jobsearch.monster.com/jobsearch_tips.asp> for a full
description of the query language.

The returned WWW::Scraper::Response objects contain B<url>, B<title>, B<company>,
B<location> and B<change_date> fields.

=head1 OPTIONS 

The following search options can be activated by sending
a hash as the second argument to native_query().

=head2 Restrict by Date

The default is to return jobs posted in last 30 days.
An example below changes the default to 14 days:

=over 2

=item   {'tm' => '14d'}

=back

=head2 lid - Restrict by Location

No restriction by default.

over 8

=item "323" => Alabama-Anniston

=item "324" => Alabama-Birmingham

=item "325" => Alabama-Mobile/Dothan

=item "328" => Alabama-Montgomery

=item "326" => Alabama-Northern/Huntsville

=item "329" => Alabama-Tuscaloosa

=item "318" => Alaska-Anchorage

=item "319" => Alaska-Fairbanks

=item "320" => Alaska-Juneau

=item "337" => Arizona-Flagstaff

=item "338" => Arizona-Phoenix

=item "340" => Arizona-Tucson

=item "941" => Arizona-Yuma

=item "333" => Arkansas-Eastern

=item "334" => Arkansas-Little Rock

=item "331" => Arkansas-Western

=item "347" => California-Anaheim/Huntington Beach

=item "349" => California-Central Coast

=item "343" => California-Central Valley

=item "344" => California-Chico/Eureka

=item "882" => California-Long Beach

=item "348" => California-Los Angeles

=item "702" => California-Oakland/East Bay

=item "350" => California-Orange County

=item "352" => California-Sacramento

=item "351" => California-San Bernardino/Palm Springs

=item "354" => California-San Diego

=item "355" => California-San Francisco

=item "357" => California-Santa Barbara

=item "883" => California-Silicon Valley/Peninsula

=item "356" => California-Silicon Valley/San Jose

=item "698" => California-Ventura County

=item "361" => Colorado-Boulder/Fort Collins

=item "362" => Colorado-Colorado Springs

=item "363" => Colorado-Denver

=item "884" => Colorado-Denver South

=item "365" => Colorado-Western/Grand Junction

=item "367" => Connecticut-Danbury/Bridgeport

=item "368" => Connecticut-Hartford

=item "689" => Connecticut-New Haven

=item "885" => Connecticut-Southeast/New London

=item "369" => Connecticut-Stamford

=item "374" => Delaware-Delaware

=item "371" => District of Columbia-Washington/Metro

=item "377" => Florida-Daytona

=item "378" => Florida-Ft. Lauderdale

=item "379" => Florida-Ft. Myers/Naples

=item "380" => Florida-Gainesville/Jacksonville

=item "382" => Florida-Melbourne

=item "383" => Florida-Miami

=item "385" => Florida-Orlando

=item "386" => Florida-Pensacola/Panama City

=item "388" => Florida-St. Petersburg

=item "389" => Florida-Tallahassee

=item "390" => Florida-Tampa

=item "391" => Florida-West Palm Beach

=item "950" => Georgia-Atlanta

=item "899" => Georgia-Atlanta North

=item "886" => Georgia-Atlanta South

=item "395" => Georgia-Central/Augusta

=item "398" => Georgia-Savannah

=item "942" => Georgia-Southwest

=item "401" => Hawaii-Hawaii

=item "412" => Idaho-Boise

=item "413" => Idaho-Eastern/Twin Falls

=item "887" => Idaho-Northern

=item "700" => Illinois-Bloomington/Peoria

=item "417" => Illinois-Chicago

=item "888" => Illinois-Chicago North

=item "889" => Illinois-Chicago Northwest

=item "890" => Illinois-Chicago South

=item "422" => Illinois-Quincy

=item "423" => Illinois-Rockford

=item "419" => Illinois-Southern

=item "424" => Illinois-Springfield/Champaign

=item "426" => Indiana-Evansville

=item "427" => Indiana-Fort Wayne

=item "891" => Indiana-Gary/Merrillville

=item "428" => Indiana-Indianapolis

=item "429" => Indiana-Lafayette

=item "430" => Indiana-South Bend

=item "431" => Indiana-Terre Haute

=item "404" => Iowa-Cedar Rapids

=item "406" => Iowa-Central/Des Moines

=item "939" => Iowa-Davenport

=item "408" => Iowa-Western/Sioux City

=item "435" => Kansas-Kansas City

=item "940" => Kansas-Overland Park

=item "434" => Kansas-Topeka/Manhattan

=item "437" => Kansas-Wichita Western

=item "439" => Kentucky-Bowling Green/Paducah

=item "441" => Kentucky-Lexington

=item "442" => Kentucky-Louisville

=item "445" => Louisiana-Alexandria

=item "446" => Louisiana-Baton Rouge

=item "447" => Louisiana-Lafayette /Lake Charles

=item "450" => Louisiana-New Orleans

=item "449" => Louisiana-Northern

=item "462" => Maine-Central/Augusta

=item "463" => Maine-Northern/Bangor

=item "464" => Maine-Southern/Portland

=item "458" => Maryland-Baltimore

=item "708" => Maryland-Montgomery County

=item "460" => Maryland-Salisbury

=item "453" => Massachusetts-Boston

=item "893" => Massachusetts-Boston North

=item "892" => Massachusetts-Boston South

=item "455" => Massachusetts-Framingham/Worcester

=item "454" => Massachusetts-Western/Springfield

=item "468" => Michigan-Ann Arbor

=item "470" => Michigan-Detroit

=item "707" => Michigan-Flint/Saginaw

=item "472" => Michigan-Grand Rapids

=item "695" => Michigan-Kalamazoo

=item "473" => Michigan-Lansing

=item "467" => Michigan-Northern

=item "482" => Minnesota-Mankato/Rochester

=item "483" => Minnesota-Minneapolis

=item "480" => Minnesota-Northern/Duluth

=item "684" => Minnesota-St. Paul

=item "502" => Mississippi-Central

=item "500" => Mississippi-Northern

=item "499" => Mississippi-Southern

=item "489" => Missouri-Jefferson City

=item "491" => Missouri-Kansas City/Independence

=item "492" => Missouri-Northeastern

=item "494" => Missouri-Quincy

=item "897" => Missouri-Southeastern

=item "495" => Missouri-Springfield/Joplin

=item "497" => Missouri-St. Louis

=item "505" => Montana-Eastern/Billings

=item "508" => Montana-Great Falls

=item "699" => Montana-Helena/Butte

=item "510" => Montana-Western/Missoula

=item "526" => Nebraska-Lincoln

=item "528" => Nebraska-Omaha

=item "525" => Nebraska-West/North Platte

=item "541" => Nevada-Las Vegas

=item "542" => Nevada-Reno

=item "705" => New Hampshire-Northern

=item "530" => New Hampshire-Southern

=item "532" => New Jersey-Central

=item "534" => New Jersey-Northern

=item "533" => New Jersey-Southern

=item "537" => New Mexico-Albuquerque

=item "685" => New Mexico-Santa Fe

=item "544" => New York-Albany/Poughkeepsie

=item "545" => New York-Binghamton/Elmira

=item "546" => New York-Buffalo

=item "549" => New York-Long Island

=item "550" => New York-New York City

=item "547" => New York-Northern

=item "552" => New York-Rochester

=item "553" => New York-Syracuse

=item "554" => New York-Utica

=item "556" => New York-Westchester

=item "512" => North Carolina-Charlotte

=item "515" => North Carolina-Eastern/Greenville

=item "514" => North Carolina-Greensboro

=item "516" => North Carolina-Raleigh/Durham-RTP

=item "517" => North Carolina-Western/Asheville

=item "513" => North Carolina-Wilmington/Fayetteville

=item "519" => North Carolina-Winston Salem

=item "521" => North Dakota-Central

=item "522" => North Dakota-Eastern

=item "523" => North Dakota-Western

=item "558" => Ohio-Akron

=item "559" => Ohio-Cincinnati

=item "560" => Ohio-Cleveland

=item "561" => Ohio-Columbus/Zanesville

=item "562" => Ohio-Dayton

=item "563" => Ohio-Northwest

=item "566" => Ohio-Youngstown

=item "569" => Oklahoma-Central-Oklahoma City

=item "571" => Oklahoma-Eastern/Tulsa

=item "574" => Oregon-Central

=item "578" => Oregon-Portland

=item "579" => Oregon-Salem

=item "576" => Oregon-Southern

=item "581" => Pennsylvania-Allentown

=item "582" => Pennsylvania-Erie

=item "583" => Pennsylvania-Harrisburg

=item "584" => Pennsylvania-Johnstown

=item "585" => Pennsylvania-Philadelphia

=item "586" => Pennsylvania-Pittsburgh

=item "704" => Pennsylvania-State College

=item "588" => Pennsylvania-Wilkes Barre

=item "703" => Pennsylvania-York/Lancaster

=item "1384" => Puerto Rico-San Juan

=item "591" => Rhode Island-Providence

=item "594" => South Carolina-Columbia

=item "595" => South Carolina-Florence/Myrtle Beach

=item "596" => South Carolina-Greenville/Spartanburg

=item "593" => South Carolina-South/Charleston

=item "598" => South Dakota-East/Sioux Falls

=item "600" => South Dakota-West/Rapid City

=item "603" => Tennessee-Chattanooga

=item "604" => Tennessee-Jackson

=item "605" => Tennessee-Knoxville

=item "606" => Tennessee-Memphis

=item "607" => Tennessee-Nashville

=item "610" => Texas-Abilene/Odessa

=item "611" => Texas-Amarillo/Lubbock

=item "612" => Texas-Austin

=item "615" => Texas-Dallas

=item "613" => Texas-East/Tyler/Beaumont

=item "616" => Texas-El Paso

=item "686" => Texas-Fort Worth

=item "619" => Texas-Houston

=item "624" => Texas-San Antonio

=item "618" => Texas-South/Corpus Christi

=item "627" => Texas-Waco

=item "628" => Texas-Wichita Falls

=item "692" => Utah-Provo

=item "630" => Utah-Salt Lake City

=item "529" => Vermont-Northern

=item "706" => Vermont-Southern

=item "1383" => Virgin Islands-St. Croix

=item "1381" => Virgin Islands-St. John

=item "1382" => Virgin Islands-St. Thomas

=item "894" => Virginia-Alexandria

=item "634" => Virginia-Charlottesville/Harrisonburg

=item "693" => Virginia-Fairfax

=item "895" => Virginia-McLean/Arlington

=item "635" => Virginia-Norfolk/Hampton Roads

=item "701" => Virginia-Northern

=item "637" => Virginia-Richmond

=item "638" => Virginia-Roanoke

=item "694" => Virginia-Vienna

=item "896" => Washington-Bellevue/Redmond

=item "649" => Washington-Central/Yakima

=item "648" => Washington-Eastern/Spokane

=item "647" => Washington-Seattle

=item "697" => Washington-Tacoma/Olympia

=item "663" => West Virginia-Northern

=item "661" => West Virginia-Southern

=item "654" => Wisconsin-Eau Claire/LaCrosse

=item "653" => Wisconsin-Green Bay/Appleton

=item "655" => Wisconsin-Madison

=item "656" => Wisconsin-Milwaukee

=item "659" => Wisconsin-Northern

=item "667" => Wyoming-Casper

=item "668" => Wyoming-Cheyenne

=back

=head2 st - State

Only jobs in state $state. To select multiple states separate them with
a "+", e.g. {'st' => 'NY+NJ+CT'}

=head2 fn - Job Function

Use {'fn' => $cat_id}  to select one to five (5) job categories.
For multiple selection separate selections with a space, e.g. 'fn' => '1 2'.
Leave blank to select all categories.

=over 8

=item "1" => Accounting/Auditing

=item "2" => Administrative and Support Services

=item "8" => Advertising/Marketing/Public Relations

=item "540" => Agriculture, Forestry, & Fishing

=item "541" => Architectural Services

=item "12" => Arts, Entertainment, and Media

=item "576" => Banking

=item "46" => Biotechnology and Pharmaceutical

=item "542" => Community, Social Services, and Nonprofit

=item "543" => Computers, Hardware

=item "6" => Computers, Software

=item "544" => Construction, Mining and Trades

=item "546" => Consulting Services

=item "545" => Customer Service and Call Center

=item "3" => Education, Training, and Library

=item "547" => Employment Placement Agencies

=item "4" => Engineering

=item "548" => Finance/Economics

=item "549" => Financial Services

=item "550" => Government and Policy

=item "551" => Healthcare, Other

=item "9" => Healthcare, Practitioner and Technician

=item "552" => Hospitality/Tourism

=item "5" => Human Resources

=item "660" => Information Technology

=item "553" => Installation, Maintenance, and Repair

=item "45" => Insurance

=item "554" => Internet/E-Commerce

=item "555" => Law Enforcement, and Security

=item "7" => Legal

=item "47" => Manufacturing and Production

=item "556" => Military

=item "11" => Other

=item "557" => Personal Care and Service

=item "558" => Real Estate

=item "13" => Restaurant and Food Service

=item "44" => Retail/Wholesale

=item "10" => Sales

=item "559" => Science

=item "560" => Sports and Recreation

=item "561" => Telecommunications

=item "562" => Transportation and Warehousing

=back

=head1 AUTHOR

Glenn Wood, Chttp://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (C) 2001 Glenn Wood. All rights reserved.
This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

