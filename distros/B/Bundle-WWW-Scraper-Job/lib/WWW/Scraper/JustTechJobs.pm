package WWW::Scraper::JustTechJobs;

=head1 NAME

WWW::Scraper::JustTechJobs - Scrapes Just*Jobs.com

=head1 SYNOPSIS

    require WWW::Search;
    $search = new WWW::Scraper('JustTechJobs');

=head1 DESCRIPTION

This class is an JustTechJobs specialization of WWW::Search.
It handles making and interpreting Just*Jobs searches
F<http://www.Just*Jobs.com> (where * is 'Perl', 'Java', etc).

=head1 OPTIONS

=over 8

=item search_debug, search_parse_debug, search_ref
Specified at L<WWW::Search>.

=back


=head1 AUTHOR

C<WWW::Scraper::JustTechJobs> is written and maintained
by Glenn Wood, http://search.cpan.org/search?mode=author&query=GLENNWOOD.

=head1 COPYRIGHT

Copyright (c) 2001 Glenn Wood
All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut

#####################################################################

require Exporter;
@EXPORT = qw();
@EXPORT_OK = qw(trimTags);
@ISA = qw(WWW::Scraper Exporter);
$VERSION = sprintf("%d.%02d", q$Revision: 1.06 $ =~ /(\d+)\.(\d+)/);

use Carp ();
use WWW::Scraper(qw(1.48 generic_option addURL trimTags));

use strict;

sub undef_to_emptystring {
    return defined($_[0]) ? $_[0] : "";
}

=head1 XML Scaffolding

Look at the idea from the perspective of the XML "scaffold" I'm suggesting for parsing the response HTML.

(This is XML, but looks superficially like HTML)

<HTML>
<BODY>
        <TABLE NAME="name" or NUMBER="number">
                <TR TYPE="header"/>
                        <TR TYPE = "detail*">
                        <TD BIND="title" />
                        <TD BIND="description" />
                        <TD BIND="location" />
                        <TD BIND="url" PARSE="anchor" />
                </TR>
        </TABLE>
</BODY>
</HTML>

This scaffold describes the relevant skeleton of an HTML document; there's HTML and BODY elements, of course.
Then the <TABLE> entry tells our parser to skip to the TABLE in the HTML named "name", or skip "number" TABLE entries
(default=0, to pick up first TABLE element.)
Then the TABLE is described. The first <TR> is described as a "header" row. 
The parser throws that one away. The second <TR> is a "detail" row (the "*" means multiple detail rows, of course). 
The parser picks up each <TD> element, extracts it's content, and places that in the hash entry corresponding to its 
BIND= attribute. Thus, the first TD goes into $result->_elem('title')
(I needed to learn to use LWP::MemberMixin. Thanks, another lesson learned!)  
The second TD goes into $result->_elem('description'), etc. 
(Of course, some of these are _elem_array, but these details will be resolved later). 
The PARSE= in the url TD suggests a way for our parser to do special handling of a data element.
The generic scaffold parser would take this XML and convert it to a hash/array to be processed at run time;
we wouldn't actually use XML at run time. A backend author would use that hash/array in his native_setup_search() code,
calling the "scaffolder" scanner with that hash as a parameter.

As I said, this works great if the response is TABLE structured,
but I haven't seen any responses that aren't that way already.

This converts to an array tree that looks like this:

    my $scaffold = [ 'HTML', 
                     [ [ 'BODY', 
                       [ [ 'TABLE', 'name' ,                  # or 'name' = undef; multiple <TABLE number=n> mean n 'TABLE's here ,
                         [ [ 'NEXT', 1, 'NEXT &gt;' ] ,       # meaning how to find the NEXT button.
                           [ 'TR', 1 ] ,                      # meaning "header".
                           [ 'TR', 2 ,                        # meaning "detail*"
                             [ [ 'TD', 1, 'title' ] ,         # meaning clear text binding to _elem('title').
                               [ 'TD', 1, 'description' ] ,
                               [ 'TD', 1, 'location' ] ,
                               [ 'TD', 2, 'url' ]             # meaning anchor parsed text binding to _elem('title').
                             ]
                         ] ]
                       ] ]
                     ] ]
                  ];
 

=cut                     

    # JustTechJobs.com sets the 'whichTech' both in it's domain name, and
    #   in the CGI program's location; ergo, we need this translation table.
    # (NOTE: the ones with upper/lowercase still in the second term have not been verified, gdw.01.05.02)
    my %JustTechJobsDirectories = (
            'ACCESS' => ["http://www.JustAccessJobs.com",'jAccess j'] ,
            'AS/400' => ["http://www.JustAS400Jobs.com", 'jAS/400 j'] ,
            'ASP' => ["http://www.JustASPJobs.com", 'jASP j'] ,
            'BAAN' => ["http://www.JustBaanJobs.com", 'jBaan j'] ,
            'C/C++' => ["http://www.JustcJobs.com", 'jcj'] ,
            'CAD' => ["http://www.JustCADJobs.com", 'jCAD j'] ,
            'COBOL' => ["http://www.JustCOBOLJobs.com", 'jCOBOL j'] ,
            'COLDFUSION' => ["http://www.JustColdFusionJobs.com", 'jColdFusion j'] ,
            'CREATIVE' => ["http://www.JustCreativeJobs.com", 'jCreative j'] ,
            'DB2' => ["http://www.JustDB2Jobs.com", 'jDB2 j'] ,
            'DELPHI' => ["http://www.JustDelphiJobs.com", 'jDelphi j'] ,
            'E-COMMERCE' => ["http://www.Juste-CommerceJobs.com", 'je-Commerce j'] ,
            'ELECTRICAL ENGINEERING' => ["http://www.JustEEJobs.com", 'jElectrical Engineering j'] ,
            'EMBEDDED' => ["http://www.JustEmbeddedJobs.com", 'jembj'] ,
            'EXCHANGE' => ["http://www.JustExchangeJobs.com", 'jExchange j'] ,
            'FOXPRO' => ["http://www.JustFoxProJobs.com", 'jFoxPro j'] ,
            'HELPDESK' => ["http://www.JustHelpdeskJobs.com", 'jHelpdesk j'] ,
            'INFORMIX' => ["http://www.JustInformixJobs.com", 'jInformix j'] ,
            'JAVA' => ["http://www.JustJavaJobs.com", 'jjavj'] ,
            'JD EDWARDS' => ["http://www.JustJDEdwardsJobs.com", 'jJD Edwards j'] ,
            'MAINFRAME' => ["http://www.JustMainframeJobs.com", 'jMainframe j'] ,
            'NETWARE' => ["http://www.JustNetWareJobs.com", 'jNetWare j'] ,
            'NETWORKING' => ["http://www.JustNetworkingJobs.com", 'jnetj'] ,
            'NOTES' => ["http://www.JustNotesJobs.com", 'jnjr'] ,
            'OLAP' => ["http://www.JustOLAPJobs.com", 'jolaj'] ,
            'ORACLE' => ["http://www.JustOracleJobs.com", 'jOracle j'] ,
            'PDA' => ["http://www.JustPDAJobs.com", 'jPDA j'] ,
            'PEOPLESOFT' => ["http://www.JustPeopleSoftJobs.com", 'jPeopleSoft j'] ,
            'PERL' => ["http://www.JustPerlJobs.com", 'JSSearchJobs.asp?'] ,
            'POWERBUILDER' => ["http://www.JustPowerBuilderJobs.com", 'jPowerBuilder j'] ,
            'PROGRESS' => ["http://www.JustProgressJobs.com", 'jProgress j'] ,
            'PROJECT MANAGER' => ["http://www.JustProjectManagerJobs.com", 'jProject Manager j'] ,
            'QA' => ["http://www.JustQAJobs.com", 'jQA j'] ,
            'SAP' => ["http://www.JustSAPJobs.com", 'jSAP j'] ,
            'SECURITY' => ["http://www.JustSecurityJobs.com", 'jSecurity j'] ,
            'SIEBEL' => ["http://www.JustSiebelJobs.com", 'jSiebel j'] ,
            'SQL SERVER' => ["http://www.JustSQLServerJobs.com", 'jSQL Server j'] ,
            'SYBASE' => ["http://www.JustSybaseJobs.com", 'jSybase j'] ,
            'TECH SALES' => ["http://www.JustTechSalesJobs.com", 'jTech Sales j'] ,
            'TECH WRITER' => ["http://www.JustTechWriterJobs.com", 'jTech Writer j'] ,
            'TELEPHONY' => ["http://www.JustTelephonyJobs.com", 'jTelephony j'] ,
            'UNIX' => ["http://www.JustUNIXJobs.com", 'jUNIX j'] ,
            'VISUAL BASIC' => ["http://www.JustVBJobs.com", 'jVisual Basic j'] ,
            'WEB' => ["http://www.JustWebJobs.com", 'jWeb j'] ,
            'WINDOWS' => ["http://www.JustWindowsJobs.com", 'jWindows j'] ,
            'WIRELESS' => ["http://www.JustWirelessJobs.com", 'jWireless j'] ,
            'XML' => ["http://www.JustXMLJobs.com", 'jxmlj']
        );

# This is the LOCA list as of 2.May.2001.
# You're welcome to keep it up to date as you wish! ;-)
    my %locationList = (
        'All Locations' => 'All-Locations',
        'All US Locations' => 'US-All',
        'Alabama-All' => 'US-AL-All',
        'Alabama-Anniston' => 'US-AL-Anniston',
        'Alabama-Birmingham' => 'US-AL-Birmingham',
        'Alabama-Mobile/Dothan' => 'US-AL-Mobile/Dothan',
        'Alabama-Montgomery' => 'US-AL-Montgomery',
        'Alabama-Northern/Huntsville' => 'US-AL-Northern/Huntsville',
        'Alabama-Tuscaloosa' => 'US-AL-Tuscaloosa',
        'Alaska-All' => 'US-AK-All',
        'Alaska-Anchorage' => 'US-AK-Anchorage',
        'Alaska-Fairbanks' => 'US-AK-Fairbanks',
        'Alaska-Juneau' => 'US-AK-Juneau',
        'Arizona-All' => 'US-AZ-All',
        'Arizona-Flagstaff' => 'US-AZ-Flagstaff',
        'Arizona-Phoenix' => 'US-AZ-Phoenix',
        'Arizona-Tucson' => 'US-AZ-Tucson',
        'Arizona-Yuma' => 'US-AZ-Yuma',
        'Arkansas-All' => 'US-AR-All',
        'Arkansas-Eastern' => 'US-AR-Eastern',
        'Arkansas-Little Rock' => 'US-AR-Little Rock',
        'Arkansas-Western' => 'US-AR-Western',
        'California-All' => 'US-CA-All',
        'California-Anaheim/Huntington Beach' => 'US-CA-Anaheim/Huntington Beach',
        'California-Central Coast' => 'US-CA-Central Coast',
        'California-Central Valley' => 'US-CA-Central Valley',
        'California-Chico/Eureka' => 'US-CA-Chico/Eureka',
        'California-Long Beach' => 'US-CA-Long Beach',
        'California-Los Angeles' => 'US-CA-Los Angeles',
        'California-Oakland/East Bay' => 'US-CA-Oakland/East Bay',
        'California-Orange County' => 'US-CA-Orange County',
        'California-Sacramento' => 'US-CA-Sacramento',
        'California-San Bernardino/Palm Springs' => 'US-CA-San Bernardino/Palm Springs',
        'California-San Diego' => 'US-CA-San Diego',
        'California-San Francisco' => 'US-CA-San Francisco',
        'California-Santa Barbara' => 'US-CA-Santa Barbara',
        'California-Silicon Valley/Peninsula' => 'US-CA-Silicon Valley/Peninsula',
        'California-Silicon Valley/San Jose' => 'US-CA-Silicon Valley/San Jose',
        'California-Ventura County' => 'US-CA-Ventura County',
        'Colorado-All' => 'US-CO-All',
        'Colorado-Boulder/Fort Collins' => 'US-CO-Boulder/Fort Collins',
        'Colorado-Colorado Springs' => 'US-CO-Colorado Springs',
        'Colorado-Denver' => 'US-CO-Denver',
        'Colorado-Denver South' => 'US-CO-Denver South',
        'Colorado-Western/Grand Junction' => 'US-CO-Western/Grand Junction',
        'Connecticut-All' => 'US-CT-All',
        'Connecticut-Danbury/Bridgeport' => 'US-CT-Danbury/Bridgeport',
        'Connecticut-Hartford' => 'US-CT-Hartford',
        'Connecticut-New Haven' => 'US-CT-New Haven',
        'Connecticut-Southeast/New London' => 'US-CT-Southeast/New London',
        'Connecticut-Stamford' => 'US-CT-Stamford',
        'Delaware-All' => 'US-DE-All',
        'District of Columbia-All' => 'US-DC-All',
        'Florida-All' => 'US-FL-All',
        'Florida-Daytona' => 'US-FL-Daytona',
        'Florida-Ft. Lauderdale' => 'US-FL-Ft. Lauderdale',
        'Florida-Ft. Myers/Naples' => 'US-FL-Ft. Myers/Naples',
        'Florida-Gainesville/Jacksonville' => 'US-FL-Gainesville/Jacksonville',
        'Florida-Melbourne' => 'US-FL-Melbourne',
        'Florida-Miami' => 'US-FL-Miami',
        'Florida-Orlando' => 'US-FL-Orlando',
        'Florida-Pensacola/Panama City' => 'US-FL-Pensacola/Panama City',
        'Florida-St. Petersburg' => 'US-FL-St. Petersburg',
        'Florida-Tallahassee' => 'US-FL-Tallahassee',
        'Florida-Tampa' => 'US-FL-Tampa',
        'Florida-West Palm Beach' => 'US-FL-West Palm Beach',
        'Georgia-All' => 'US-GA-All',
        'Georgia-Atlanta' => 'US-GA-Atlanta',
        'Georgia-Atlanta North' => 'US-GA-Atlanta North',
        'Georgia-Atlanta South' => 'US-GA-Atlanta South',
        'Georgia-Central/Augusta' => 'US-GA-Central/Augusta',
        'Georgia-Savannah' => 'US-GA-Savannah',
        'Georgia-Southwest' => 'US-GA-Southwest',
        'Hawaii-All' => 'US-HI-All',
        'Idaho-All' => 'US-ID-All',
        'Idaho-Boise' => 'US-ID-Boise',
        'Idaho-Eastern/Twin Falls' => 'US-ID-Eastern/Twin Falls',
        'Idaho-Northern' => 'US-ID-Northern',
        'Illinois-All' => 'US-IL-All',
        'Illinois-Bloomington/Peoria' => 'US-IL-Bloomington/Peoria',
        'Illinois-Chicago' => 'US-IL-Chicago',
        'Illinois-Chicago North' => 'US-IL-Chicago North',
        'Illinois-Chicago Northwest' => 'US-IL-Chicago Northwest',
        'Illinois-Chicago South' => 'US-IL-Chicago South',
        'Illinois-Quincy' => 'US-IL-Quincy',
        'Illinois-Rockford' => 'US-IL-Rockford',
        'Illinois-Southern' => 'US-IL-Southern',
        'Illinois-Springfield/Champaign' => 'US-IL-Springfield/Champaign',
        'Indiana-All' => 'US-IN-All',
        'Indiana-Evansville' => 'US-IN-Evansville',
        'Indiana-Fort Wayne' => 'US-IN-Fort Wayne',
        'Indiana-Gary/Merrillville' => 'US-IN-Gary/Merrillville',
        'Indiana-Indianapolis' => 'US-IN-Indianapolis',
        'Indiana-Lafayette' => 'US-IN-Lafayette',
        'Indiana-South Bend' => 'US-IN-South Bend',
        'Indiana-Terre Haute' => 'US-IN-Terre Haute',
        'Iowa-All' => 'US-IA-All',
        'Iowa-Cedar Rapids' => 'US-IA-Cedar Rapids',
        'Iowa-Central/Des Moines' => 'US-IA-Central/Des Moines',
        'Iowa-Davenport' => 'US-IA-Davenport',
        'Iowa-Western/Sioux City' => 'US-IA-Western/Sioux City',
        'Kansas-All' => 'US-KS-All',
        'Kansas-Kansas City' => 'US-KS-Kansas City',
        'Kansas-Overland Park' => 'US-KS-Overland Park',
        'Kansas-Topeka/Manhattan' => 'US-KS-Topeka/Manhattan',
        'Kansas-Wichita Western' => 'US-KS-Wichita Western',
        'Kentucky-All' => 'US-KY-All',
        'Kentucky-Bowling Green/Paducah' => 'US-KY-Bowling Green/Paducah',
        'Kentucky-Lexington' => 'US-KY-Lexington',
        'Kentucky-Louisville' => 'US-KY-Louisville',
        'Louisiana-All' => 'US-LA-All',
        'Louisiana-Alexandria' => 'US-LA-Alexandria',
        'Louisiana-Baton Rouge' => 'US-LA-Baton Rouge',
        'Louisiana-Lafayette /Lake Charles' => 'US-LA-Lafayette /Lake Charles',
        'Louisiana-New Orleans' => 'US-LA-New Orleans',
        'Louisiana-Northern' => 'US-LA-Northern',
        'Maine-All' => 'US-ME-All',
        'Maine-Central/Augusta' => 'US-ME-Central/Augusta',
        'Maine-Northern/Bangor' => 'US-ME-Northern/Bangor',
        'Maine-Southern/Portland' => 'US-ME-Southern/Portland',
        'Maryland-All' => 'US-MD-All',
        'Maryland-Baltimore' => 'US-MD-Baltimore',
        'Maryland-Montgomery County' => 'US-MD-Montgomery County',
        'Maryland-Salisbury' => 'US-MD-Salisbury',
        'Massachusetts-All' => 'US-MA-All',
        'Massachusetts-Boston' => 'US-MA-Boston',
        'Massachusetts-Boston North' => 'US-MA-Boston North',
        'Massachusetts-Boston South' => 'US-MA-Boston South',
        'Massachusetts-Framingham/Worcester' => 'US-MA-Framingham/Worcester',
        'Massachusetts-Western/Springfield' => 'US-MA-Western/Springfield',
        'Michigan-All' => 'US-MI-All',
        'Michigan-Ann Arbor' => 'US-MI-Ann Arbor',
        'Michigan-Detroit' => 'US-MI-Detroit',
        'Michigan-Flint/Saginaw' => 'US-MI-Flint/Saginaw',
        'Michigan-Grand Rapids' => 'US-MI-Grand Rapids',
        'Michigan-Kalamazoo' => 'US-MI-Kalamazoo',
        'Michigan-Lansing' => 'US-MI-Lansing',
        'Michigan-Northern' => 'US-MI-Northern',
        'Minnesota-All' => 'US-MN-All',
        'Minnesota-Mankato/Rochester' => 'US-MN-Mankato/Rochester',
        'Minnesota-Minneapolis' => 'US-MN-Minneapolis',
        'Minnesota-Northern/Duluth' => 'US-MN-Northern/Duluth',
        'Minnesota-St. Paul' => 'US-MN-St. Paul',
        'Mississippi-All' => 'US-MS-All',
        'Mississippi-Central' => 'US-MS-Central',
        'Mississippi-Northern' => 'US-MS-Northern',
        'Mississippi-Southern' => 'US-MS-Southern',
        'Missouri-All' => 'US-MO-All',
        'Missouri-Jefferson City' => 'US-MO-Jefferson City',
        'Missouri-Kansas City/Independence' => 'US-MO-Kansas City/Independence',
        'Missouri-Northeastern' => 'US-MO-Northeastern',
        'Missouri-Quincy' => 'US-MO-Quincy',
        'Missouri-Southeastern' => 'US-MO-Southeastern',
        'Missouri-Springfield/Joplin' => 'US-MO-Springfield/Joplin',
        'Missouri-St. Louis' => 'US-MO-St. Louis',
        'Montana-All' => 'US-MT-All',
        'Montana-Eastern/Billings' => 'US-MT-Eastern/Billings',
        'Montana-Great Falls' => 'US-MT-Great Falls',
        'Montana-Helena/Butte' => 'US-MT-Helena/Butte',
        'Montana-Western/Missoula' => 'US-MT-Western/Missoula',
        'Nebraska-All' => 'US-NE-All',
        'Nebraska-Lincoln' => 'US-NE-Lincoln',
        'Nebraska-Omaha' => 'US-NE-Omaha',
        'Nebraska-West/North Platte' => 'US-NE-West/North Platte',
        'Nevada-All' => 'US-NV-All',
        'Nevada-Las Vegas' => 'US-NV-Las Vegas',
        'Nevada-Reno' => 'US-NV-Reno',
        'New Hampshire-All' => 'US-NH-All',
        'New Hampshire-Northern' => 'US-NH-Northern',
        'New Hampshire-Southern' => 'US-NH-Southern',
        'New Jersey-All' => 'US-NJ-All',
        'New Jersey-Central' => 'US-NJ-Central',
        'New Jersey-Northern' => 'US-NJ-Northern',
        'New Jersey-Southern' => 'US-NJ-Southern',
        'New Mexico-All' => 'US-NM-All',
        'New Mexico-Albuquerque' => 'US-NM-Albuquerque',
        'New Mexico-Santa Fe' => 'US-NM-Santa Fe',
        'New York-All' => 'US-NY-All',
        'New York-Albany/Poughkeepsie' => 'US-NY-Albany/Poughkeepsie',
        'New York-Binghamton/Elmira' => 'US-NY-Binghamton/Elmira',
        'New York-Buffalo' => 'US-NY-Buffalo',
        'New York-Long Island' => 'US-NY-Long Island',
        'New York-New York City' => 'US-NY-New York City',
        'New York-Northern' => 'US-NY-Northern',
        'New York-Rochester' => 'US-NY-Rochester',
        'New York-Syracuse' => 'US-NY-Syracuse',
        'New York-Utica' => 'US-NY-Utica',
        'New York-Westchester' => 'US-NY-Westchester',
        'North Carolina-All' => 'US-NC-All',
        'North Carolina-Charlotte' => 'US-NC-Charlotte',
        'North Carolina-Eastern/Greenville' => 'US-NC-Eastern/Greenville',
        'North Carolina-Greensboro' => 'US-NC-Greensboro',
        'North Carolina-Raleigh/Durham RTP' => 'US-NC-Raleigh/Durham RTP',
        'North Carolina-Western/Asheville' => 'US-NC-Western/Asheville',
        'North Carolina-Wilmington/Fayetteville' => 'US-NC-Wilmington/Fayetteville',
        'North Carolina-Winston Salem' => 'US-NC-Winston Salem',
        'North Dakota-All' => 'US-ND-All',
        'North Dakota-Central' => 'US-ND-Central',
        'North Dakota-Eastern' => 'US-ND-Eastern',
        'North Dakota-Western' => 'US-ND-Western',
        'Ohio-All' => 'US-OH-All',
        'Ohio-Akron' => 'US-OH-Akron',
        'Ohio-Cincinnati' => 'US-OH-Cincinnati',
        'Ohio-Cleveland' => 'US-OH-Cleveland',
        'Ohio-Columbus/Zanesville' => 'US-OH-Columbus/Zanesville',
        'Ohio-Dayton' => 'US-OH-Dayton',
        'Ohio-Northwest' => 'US-OH-Northwest',
        'Ohio-Youngstown' => 'US-OH-Youngstown',
        'Oklahoma-All' => 'US-OK-All',
        'Oklahoma-Central-Oklahoma City' => 'US-OK-Central-Oklahoma City',
        'Oklahoma-Eastern/Tulsa' => 'US-OK-Eastern/Tulsa',
        'Oregon-All' => 'US-OR-All',
        'Oregon-Central' => 'US-OR-Central',
        'Oregon-Portland' => 'US-OR-Portland',
        'Oregon-Salem' => 'US-OR-Salem',
        'Oregon-Southern' => 'US-OR-Southern',
        'Pennsylvania-All' => 'US-PA-All',
        'Pennsylvania-Allentown' => 'US-PA-Allentown',
        'Pennsylvania-Erie' => 'US-PA-Erie',
        'Pennsylvania-Harrisburg' => 'US-PA-Harrisburg',
        'Pennsylvania-Johnstown' => 'US-PA-Johnstown',
        'Pennsylvania-Philadelphia' => 'US-PA-Philadelphia',
        'Pennsylvania-Pittsburgh' => 'US-PA-Pittsburgh',
        'Pennsylvania-State College' => 'US-PA-State College',
        'Pennsylvania-Wilkes Barre' => 'US-PA-Wilkes Barre',
        'Pennsylvania-York/Lancaster' => 'US-PA-York/Lancaster',
        'Puerto Rico-All' => 'US-PR-All',
        'Rhode Island-All' => 'US-RI-All',
        'South Carolina-All' => 'US-SC-All',
        'South Carolina-Columbia' => 'US-SC-Columbia',
        'South Carolina-Florence/Myrtle Beach' => 'US-SC-Florence/Myrtle Beach',
        'South Carolina-Greenville/Spartanburg' => 'US-SC-Greenville/Spartanburg',
        'South Carolina-South/Charleston' => 'US-SC-South/Charleston',
        'South Dakota-All' => 'US-SD-All',
        'South Dakota-East/Sioux Falls' => 'US-SD-East/Sioux Falls',
        'South Dakota-West/Rapid City' => 'US-SD-West/Rapid City',
        'Tennessee-All' => 'US-TN-All',
        'Tennessee-Chattanooga' => 'US-TN-Chattanooga',
        'Tennessee-Jackson' => 'US-TN-Jackson',
        'Tennessee-Knoxville' => 'US-TN-Knoxville',
        'Tennessee-Memphis' => 'US-TN-Memphis',
        'Tennessee-Nashville' => 'US-TN-Nashville',
        'Texas-All' => 'US-TX-All',
        'Texas-Abilene/Odessa' => 'US-TX-Abilene/Odessa',
        'Texas-Amarillo/Lubbock' => 'US-TX-Amarillo/Lubbock',
        'Texas-Austin' => 'US-TX-Austin',
        'Texas-Dallas' => 'US-TX-Dallas',
        'Texas-East/Tyler/Beaumont' => 'US-TX-East/Tyler/Beaumont',
        'Texas-El Paso' => 'US-TX-El Paso',
        'Texas-Fort Worth' => 'US-TX-Fort Worth',
        'Texas-Houston' => 'US-TX-Houston',
        'Texas-San Antonio' => 'US-TX-San Antonio',
        'Texas-South/Corpus Christi' => 'US-TX-South/Corpus Christi',
        'Texas-Waco' => 'US-TX-Waco',
        'Texas-Wichita Falls' => 'US-TX-Wichita Falls',
        'Utah-All' => 'US-UT-All',
        'Utah-Provo' => 'US-UT-Provo',
        'Utah-Salt Lake City' => 'US-UT-Salt Lake City',
        'Vermont-All' => 'US-VT-All',
        'Vermont-Northern' => 'US-VT-Northern',
        'Vermont-Southern' => 'US-VT-Southern',
        'Virgin Islands-All' => 'US-VI-All',
        'Virginia-All' => 'US-VA-All',
        'Virginia-Alexandria' => 'US-VA-Alexandria',
        'Virginia-Charlottesville/Harrisonburg' => 'US-VA-Charlottesville/Harrisonburg',
        'Virginia-Fairfax' => 'US-VA-Fairfax',
        'Virginia-McLean/Arlington' => 'US-VA-McLean/Arlington',
        'Virginia-Norfolk/Hampton Roads' => 'US-VA-Norfolk/Hampton Roads',
        'Virginia-Northern' => 'US-VA-Northern',
        'Virginia-Richmond' => 'US-VA-Richmond',
        'Virginia-Roanoke' => 'US-VA-Roanoke',
        'Virginia-Vienna' => 'US-VA-Vienna',
        'Washington-All' => 'US-WA-All',
        'Washington-Bellevue/Redmond' => 'US-WA-Bellevue/Redmond',
        'Washington-Central/Yakima' => 'US-WA-Central/Yakima',
        'Washington-Eastern/Spokane' => 'US-WA-Eastern/Spokane',
        'Washington-Seattle' => 'US-WA-Seattle',
        'Washington-Tacoma/Olympia' => 'US-WA-Tacoma/Olympia',
        'West Virginia-All' => 'US-WV-All',
        'West Virginia-Northern' => 'US-WV-Northern',
        'West Virginia-Southern' => 'US-WV-Southern',
        'Wisconsin-All' => 'US-WI-All',
        'Wisconsin-Eau Claire/LaCrosse' => 'US-WI-Eau Claire/LaCrosse',
        'Wisconsin-Green Bay/Appleton' => 'US-WI-Green Bay/Appleton',
        'Wisconsin-Madison' => 'US-WI-Madison',
        'Wisconsin-Milwaukee' => 'US-WI-Milwaukee',
        'Wisconsin-Northern' => 'US-WI-Northern',
        'Wyoming-All' => 'US-WY-All',
        'Wyoming-Casper' => 'US-WY-Casper',
        'Wyoming-Cheyenne' => 'US-WY-Cheyenne',
        'Non-US Locations' => 'label',
        '------ Non-US Locations ------' => 'label',
        'Afghanistan' => 'Afghanistan',
        'Albania' => 'Albania',
        'Algeria' => 'Algeria',
        'Andorra' => 'Andorra',
        'Angola' => 'Angola',
        'Antigua and Barbuda' => 'Antigua and Barbuda',
        'Argentina' => 'Argentina',
        'Armenia' => 'Armenia',
        'Australia' => 'Australia',
        'Austria' => 'Austria',
        'Azerbaijan' => 'Azerbaijan',
        'Bahamas' => 'Bahamas',
        'Bahrain' => 'Bahrain',
        'Bangladesh' => 'Bangladesh',
        'Barbados' => 'Barbados',
        'Belarus' => 'Belarus',
        'Belgium' => 'Belgium',
        'Belize' => 'Belize',
        'Benin' => 'Benin',
        'Bermuda' => 'Bermuda',
        'Bhutan' => 'Bhutan',
        'Bolivia' => 'Bolivia',
        'Bosnia and Herzegovina' => 'Bosnia and Herzegovina',
        'Botswana' => 'Botswana',
        'Brazil' => 'Brazil',
        'Brunei' => 'Brunei',
        'Bulgaria' => 'Bulgaria',
        'Burkina Faso' => 'Burkina Faso',
        'Burundi' => 'Burundi',
        'Cambodia' => 'Cambodia',
        'Cameroon' => 'Cameroon',
        'Canada-All' => 'Canada-All',
        'Canada-Edmonton' => 'Canada-Edmonton',
        'Canada-Montreal' => 'Canada-Montreal',
        'Canada-Toronto' => 'Canada-Toronto',
        'Canada-Vancouver' => 'Canada-Vancouver',
        'Canada-Windsor' => 'Canada-Windsor',
        'Canada-Winnipeg' => 'Canada-Winnipeg',
        'Cape Verde' => 'Cape Verde',
        'Central African Republic' => 'Central African Republic',
        'Chad' => 'Chad',
        'Chile' => 'Chile',
        'China' => 'China',
        'Colombia' => 'Colombia',
        'Comoros' => 'Comoros',
        'Congo' => 'Congo',
        'Costa Rica' => 'Costa Rica',
        'Croatia' => 'Croatia',
        'Cuba' => 'Cuba',
        'Cyprus' => 'Cyprus',
        'Czech Republic' => 'Czech Republic',
        'Denmark' => 'Denmark',
        'Djibouti' => 'Djibouti',
        'Dominica' => 'Dominica',
        'Dominican Republic' => 'Dominican Republic',
        'Ecuador' => 'Ecuador',
        'Egypt' => 'Egypt',
        'El Salvador' => 'El Salvador',
        'Equatorial Guinea' => 'Equatorial Guinea',
        'Eritrea' => 'Eritrea',
        'Estonia' => 'Estonia',
        'Ethiopia' => 'Ethiopia',
        'Fiji' => 'Fiji',
        'Finland' => 'Finland',
        'France' => 'France',
        'Gabon' => 'Gabon',
        'Gambia' => 'Gambia',
        'Georgia' => 'Georgia',
        'Germany' => 'Germany',
        'Ghana' => 'Ghana',
        'Greece' => 'Greece',
        'Grenada' => 'Grenada',
        'Guatemala' => 'Guatemala',
        'Guinea' => 'Guinea',
        'Guinea-Bissau' => 'Guinea-Bissau',
        'Guyana' => 'Guyana',
        'Haiti' => 'Haiti',
        'Honduras' => 'Honduras',
        'Hong Kong' => 'Hong Kong',
        'Hungary' => 'Hungary',
        'Iceland' => 'Iceland',
        'India' => 'India',
        'Indonesia' => 'Indonesia',
        'Iran' => 'Iran',
        'Iraq' => 'Iraq',
        'Ireland' => 'Ireland',
        'Israel' => 'Israel',
        'Italy' => 'Italy',
        'Jamaica' => 'Jamaica',
        'Japan' => 'Japan',
        'Jordan' => 'Jordan',
        'Kazakhstan' => 'Kazakhstan',
        'Kenya' => 'Kenya',
        'Kiribati' => 'Kiribati',
        'Kuwait' => 'Kuwait',
        'Kyrgyzstan' => 'Kyrgyzstan',
        'Laos' => 'Laos',
        'Latvia' => 'Latvia',
        'Lebanon' => 'Lebanon',
        'Lesotho' => 'Lesotho',
        'Liberia' => 'Liberia',
        'Libya' => 'Libya',
        'Liechtenstein' => 'Liechtenstein',
        'Lithuania' => 'Lithuania',
        'Luxembourg' => 'Luxembourg',
        'Macedonia' => 'Macedonia',
        'Madagascar' => 'Madagascar',
        'Malawi' => 'Malawi',
        'Malaysia' => 'Malaysia',
        'Maldives' => 'Maldives',
        'Mali' => 'Mali',
        'Malta' => 'Malta',
        'Marshall Islands' => 'Marshall Islands',
        'Mauritania' => 'Mauritania',
        'Mauritius' => 'Mauritius',
        'Mexico' => 'Mexico',
        'Micronesia' => 'Micronesia',
        'Moldova' => 'Moldova',
        'Monaco' => 'Monaco',
        'Mongolia' => 'Mongolia',
        'Morocco' => 'Morocco',
        'Mozambique' => 'Mozambique',
        'Myanmar' => 'Myanmar',
        'Namibia' => 'Namibia',
        'Nauru' => 'Nauru',
        'Nepal' => 'Nepal',
        'Netherlands' => 'Netherlands',
        'New Zealand' => 'New Zealand',
        'Nicaragua' => 'Nicaragua',
        'Niger' => 'Niger',
        'Nigeria' => 'Nigeria',
        'North Korea' => 'North Korea',
        'Norway' => 'Norway',
        'Oman' => 'Oman',
        'Pakistan' => 'Pakistan',
        'Palau' => 'Palau',
        'Panama' => 'Panama',
        'Papua New Guinea' => 'Papua New Guinea',
        'Paraguay' => 'Paraguay',
        'Peru' => 'Peru',
        'Philippines' => 'Philippines',
        'Poland' => 'Poland',
        'Portugal' => 'Portugal',
        'Qatar' => 'Qatar',
        'Romania' => 'Romania',
        'Russia' => 'Russia',
        'Rwanda' => 'Rwanda',
        'Saint Kitts and Nevis' => 'Saint Kitts and Nevis',
        'Saint Lucia' => 'Saint Lucia',
        'Samoa' => 'Samoa',
        'San Marino' => 'San Marino',
        'Sao Tome and Principe' => 'Sao Tome and Principe',
        'Saudi Arabia' => 'Saudi Arabia',
        'Senegal' => 'Senegal',
        'Seychelles' => 'Seychelles',
        'Sierra Leone' => 'Sierra Leone',
        'Singapore' => 'Singapore',
        'Slovakia' => 'Slovakia',
        'Slovenia' => 'Slovenia',
        'Solomon Islands' => 'Solomon Islands',
        'Somalia' => 'Somalia',
        'South Africa' => 'South Africa',
        'South Korea' => 'South Korea',
        'Spain' => 'Spain',
        'Sri Lanka' => 'Sri Lanka',
        'Sudan' => 'Sudan',
        'Suriname' => 'Suriname',
        'Swaziland' => 'Swaziland',
        'Sweden' => 'Sweden',
        'Switzerland' => 'Switzerland',
        'Syria' => 'Syria',
        'Taiwan' => 'Taiwan',
        'Tajikistan' => 'Tajikistan',
        'Tanzania' => 'Tanzania',
        'Thailand' => 'Thailand',
        'Togo' => 'Togo',
        'Tonga' => 'Tonga',
        'Trinidad and Tobago' => 'Trinidad and Tobago',
        'Tunisia' => 'Tunisia',
        'Turkey' => 'Turkey',
        'Turkmenistan' => 'Turkmenistan',
        'Tuvalu' => 'Tuvalu',
        'Uganda' => 'Uganda',
        'Ukraine' => 'Ukraine',
        'United Arab Emirates' => 'United Arab Emirates',
        'United Kingdom' => 'United Kingdom',
        'Uruguay' => 'Uruguay',
        'Uzbekistan' => 'Uzbekistan',
        'Vanuatu' => 'Vanuatu',
        'Vatican City' => 'Vatican City',
        'Venezuela' => 'Venezuela',
        'Vietnam' => 'Vietnam',
        'Western Sahara' => 'Western Sahara',
        'Yemen' => 'Yemen',
        'Yugoslavia' => 'Yugoslavia',
        'Zambia' => 'Zambia',
        'Zimbabwe' => 'Zimbabwe'
    );


#'http://www.justperljobs.com/jperj.nsf/SearchResults?OpenForm&POST=&VISA=&CONT=&ENTL=&STRT=&COMP=&LOCA=&KEYW=Perl&LOGF=AND&NEXT=1'
#'http://www.JustPerlJobs.com/jperj.nsf/SearchResults?OpenForm&COMP=&CONT=&ENTL=&LOCA=&LOGF=AND&NEXT=1&POST=&SKIL=01&STRT=&VISA=&query=Perl'
my $scraperRequest = 
   { 
      'type' => 'FORM'       # Type of query generation is 'QUERY'
      # This is the basic URL on which to build the query.
     ,'url' => '' # Calculated by scraperRequest().
      # This is the Scraper attributes => native input fields mapping
     ,'nativeQuery' => 'KEYW'
     ,'nativeDefaults' => {
                          'SKIL' => '01',
                          'POST' => '',
                          'VISA' => '',
                          'CONT' => '',
                          'ENTL' => '',
                          'STRT' => '',
                          'COMP' => '',
                          'LOCA' => '',
                          'LOGF' => 'AND',
                          'NEXT' => '1',
                          'whichTech' => 'Perl'
                      }
     ,'defaultRequestClass' => 'Job'
     ,'fieldTranslations' =>
              { '*' => 
                      {    'skills'    => 'KEYW'
                          ,'payrate'   => ''
                          ,'locations' => \&translateLocations
                          ,'whichTech' => ''
                          ,'*'       => '*'
                      }
              }
           # Some more options for the Scraper operation.
     ,'cookies' => 1
   };

my $scraperFrame =
    [ 'HTML', 
      [ [ 'BODY', '<BODY', '</BODY>' , # Make the parsing easier for scrapeTable() by stripping off the adminstrative clutter.
          [ [ 'COUNT', '\d+ - \d+ of (\d+) matches' ] ,
            [ 'NEXT', 1, '<b>Next ' ] ,        # meaning how to find the NEXT button.
              [ 'HIT*', 'Job',                 # meaning the content of this array element represents Job hits! '
                  [
                    [ 'BODY', '<input type="checkbox" name="check_', undef,
                      [  [ 'A', 'url', 'title' ] ,
                         [ 'TD', '_blank_' ],
                         [ 'TABLE', '#0',
                            [ [ 'TD', '_label_' ] ,
                              [ 'TD', 'payrate' ],
                              [ 'TD', '_label_' ] ,
                              [ 'TD', 'company' ],
                              [ 'TD', '_label_' ] ,
                              [ 'TD', 'locations' ],
                              [ 'TD', '_label_' ] ,
                              [ 'TD', 'description' ]
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
    if ( $self ) {
        $self->whichTech('Perl');
    }
    return {
                 'SKIP' => 'JustTechJobs.pm has gone the way of "user/password" - or something about session/cookies, anyway.'
                ,'testNativeOptions' => { 'whichTech' => 'Perl' }                                         
           };
}



# Access methods for the structural declarations of this Scraper engine.
sub scraperRequest { 
    my ($self, $native_query, $native_options) = @_;    

    $native_options->{'whichTech'} = $self->whichTech() unless $native_options->{'whichTech'};
    my $siteKey = $JustTechJobsDirectories{uc $native_options->{'whichTech'}};
    die "'$native_options->{'whichTech'}' is not a recognized 'whichTech' for JustTechJobs" unless $siteKey;
    $scraperRequest->{'url'} = $$siteKey[0].'/'.$$siteKey[1];
    return $scraperRequest;
}

sub scraperFrame { $_[0]->SUPER::scraperFrame($scraperFrame); }
sub scraperDetail{ undef }

sub whichTech {
    my ($self, $whichTech) = @_;
    $self->{'whichTech'} = $whichTech if ( $whichTech );
    return $self->{'whichTech'};
}

sub import
{
    my $package = shift;

    my @exports = grep { "HASH" ne ref($_) } @_;
    my @options = grep { "HASH" eq ref($_) } @_;

    foreach (@options)
    {
        if ( $_->{'scraperBaseURL'} ) {
            $scraperRequest->{'url'} = $_->{'scraperBaseURL'};  # new form
        }
        if ( $_->{'whichTech'} ) {
            my $siteKey = $JustTechJobsDirectories{uc $_->{'whichTech'}};
            $scraperRequest->{'url'} = $$siteKey[0].'/'.$$siteKey[1];
            $package->whichTech($_->{'whichTech'});
        }
    }

    @_ = ($package, @exports);
    goto &Exporter::import;
}


# Translate from the canonical Request->locations to Brainpower's 'state' option.
sub translateLocations {
    my ($self, $rqst, $val) = @_;
    my @results;
    my %alreadyDone;

    my $aval = $val;
    $aval = [$val] unless 'ARRAY' eq ref $val;
    for my $val ( @$aval ) {
        $val = 'CA-Silicon Valley/San Jose' if $val eq 'CA-San Jose';
        # hmmm . . .
        # US-CA-Silicon Valley/Peninsula
        push @results, 'US-'.$val;
    }
    return ('LOCA', \@results);
}

1;
