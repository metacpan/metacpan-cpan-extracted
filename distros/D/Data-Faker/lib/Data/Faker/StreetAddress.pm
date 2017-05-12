package Data::Faker::StreetAddress;
use strict;
use warnings;
use vars qw($VERSION); $VERSION = '0.10';
use base 'Data::Faker';
use Data::Faker::Name;

=head1 NAME

Data::Faker::StreetAddress - Data::Faker plugin

=head1 SYNOPSIS AND USAGE

See L<Data::Faker>

=head1 DATA PROVIDERS

=over 4

=item us_zip_code

Return a random zip or zip+4 zip code in the US zip code format.  Note that
this is not necessarily a valid zip code, just a 5 or 9 digit number in the
correct format.

=cut

__PACKAGE__->register_plugin(
	us_zip_code => ['#####','#####-####'],
);

=item us_state

Return a random US state name.

=cut


__PACKAGE__->register_plugin(
	us_state => [
		qw{
			Alabama Alaska Arizona Arkansas California Colorado Connecticut
			Delaware Florida Georgia Hawaii Idaho Illinois Indiana Iowa Kansas
			Kentucky Louisiana Maine Maryland Massachusetts Michigan Minnesota
			Mississippi Missouri Montana Nebraska Nevada Ohio Oklahoma Oregon
			Pennsylvania Tennessee Texas Utah Vermont Virginia Wisconsin
			Wyoming Washington
		},
		'New Hampshire', 'New Jersey', 'New Mexico', 'New York',
		'North Carolina', 'North Dakota', 'Rhode Island', 'South Carolina',
		'South Dakota', 'West Virginia',
	],
);

=item us_state_abbr

Return a random US state abbreviation. (Includes US Territories and AE, AA,
AP military designations.)

From the USPS list at http://www.usps.com/ncsc/lookups/usps_abbreviations.html
=cut

__PACKAGE__->register_plugin(
	us_state_abbr => [qw(
		AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY
		LA ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK
		OR PW PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY AE AA AP
	)],
);

=item street_suffix

Return a random street suffix (Drive, Street, Road, etc.)

From the USPS list at http://www.usps.com/ncsc/lookups/usps_abbreviations.html

=cut

__PACKAGE__->register_plugin(
	street_suffix => [qw(
		Alley Avenue Branch Bridge Brook Brooks Burg Burgs Bypass Camp Canyon
		Cape Causeway Center Centers Circle Circles Cliff Cliffs Club Common
		Corner Corners Course Court Courts Cove Coves Creek Crescent Crest
		Crossing Crossroad Curve Dale Dam Divide Drive Drive Drives Estate
		Estates Expressway Extension Extensions Fall Falls Ferry Field Fields
		Flat Flats Ford Fords Forest Forge Forges Fork Forks Fort Freeway
		Garden Gardens Gateway Glen Glens Green Greens Grove Groves Harbor
		Harbors Haven Heights Highway Hill Hills Hollow Inlet Inlet Island
		Island Islands Islands Isle Isle Junction Junctions Key Keys Knoll
		Knolls Lake Lakes Land Landing Lane Light Lights Loaf Lock Locks Locks
		Lodge Lodge Loop Mall Manor Manors Meadow Meadows Mews Mill Mills
		Mission Mission Motorway Mount Mountain Mountain Mountains Mountains
		Neck Orchard Oval Overpass Park Parks Parkway Parkways Pass Passage
		Path Pike Pine Pines Place Plain Plains Plains Plaza Plaza Point Points
		Port Port Ports Ports Prairie Prairie Radial Ramp Ranch Rapid Rapids
		Rest Ridge Ridges River Road Road Roads Roads Route Row Rue Run Shoal
		Shoals Shore Shores Skyway Spring Springs Springs Spur Spurs Square
		Square Squares Squares Station Station Stravenue Stravenue Stream
		Stream Street Street Streets Summit Summit Terrace Throughway Trace
		Track Trafficway Trail Trail Tunnel Tunnel Turnpike Turnpike Underpass
		Union Unions Valley Valleys Via Viaduct View Views Village Village
		Villages Ville Vista Vista Walk Walks Wall Way Ways Well Wells
	)],
);

=item street_name

Return a fake street name.

=cut


__PACKAGE__->register_plugin(
	street_name	=> [
		'$last_name $street_suffix',
		'$first_name $street_suffix',
	],
);

=item street_address

Return a fake street address.

=cut

__PACKAGE__->register_plugin(
	street_address => [
		'##### $street_name',
		'##### $street_name',
		'##### $street_name',
		'##### $street_name',
		'##### $street_name Apt. ###',
		'##### $street_name Suite ###',
		'##### $street_name \####',
		'##### $secondary_unit_designator',
	],
);

=item secondary_unit_designator

Return a random secondary unit designator, with a range if needed (secondary
unit designators are things like apartment number, building number, suite,
penthouse, etc that differentiate different units with a common address.)

=cut

__PACKAGE__->register_plugin(
	secondary_unit_designator => [
		'Apartment $secondary_unit_number',
		'Building $secondary_unit_number',
		'Department $secondary_unit_number',
		'Floor #', 'Floor ##', 'Floor ###',
		'Floor \##', 'Floor \###', 'Floor \####',
		'Hangar $secondary_unit_number',
		'Lot $secondary_unit_number',
		'Pier $secondary_unit_number',
		'Room $secondary_unit_number',
		'Slip $secondary_unit_number',
		'Space $secondary_unit_number',
		'Stop $secondary_unit_number',
		'Suite $secondary_unit_number',
		'Trailer $secondary_unit_number',
		'Unit $secondary_unit_number',
		'Basement','Front','Lobby','Lower','Office',
		'Penthouse','Rear','Side','Upper',
	],
);

=item secondary_unit_number

Return a random secondary unit number, for the secondary unit designators that
take ranges.

=cut

__PACKAGE__->register_plugin(
	secondary_unit_number => [
		('A' .. 'Z'), '###','\####','##','\###','#','\##',
		'#-A','\##-A','#-B','\##-B','#-C','\##-C','#-D','\##-D','#-E','\##-E',
		'#-F','\##-F','#-G','\##-G','#-H','\##-H','#-I','\##-I','#-J','\##-J',
	],
);

=item city

Return a random city, taken from a list of larger cities in several U.S. states.

=cut

__PACKAGE__->register_plugin(
	city => [
            'Agoura Hills',
            'Akron',
            'Alameda',
            'Alhambra',
            'Aliso Viejo',
            'Anaheim',
            'Anchorage',
            'Apple Valley',
            'Arcadia',
            'Artesia',
            'Ashland',
            'Athens',
            'Atwater',
            'Auburn',
            'Avalon',
            'Azusa',
            'Bakersfield',
            'Baldwin Park',
            'Barrow',
            'Bell Gardens',
            'Bell',
            'Bellflower',
            'Bentonville',
            'Berkeley',
            'Bessemer',
            'Beverly Hills',
            'Birmingham',
            'Bloomington',
            'Blythe',
            'Bowling Green',
            'Bradbury',
            'Brea',
            'Buena Park',
            'Burbank',
            'Burlingame',
            'Calabasas',
            'Canton',
            'Carson',
            'Cerritos',
            'Chandler',
            'Chico',
            'Chino Hills',
            'Chino',
            'Chula Vista',
            'Cincinnati',
            'Citrus Heights',
            'City of Industry',
            'Claremont',
            'Cleveland',
            'Columbus',
            'Commerce',
            'Compton',
            'Concord',
            'Corona',
            'Costa Mesa',
            'Covina',
            'Covington',
            'Crown Point',
            'Cudahy',
            'Culver City',
            'Cypress',
            'Daly City',
            'Dana Point',
            'Danville',
            'Dayton',
            'Decatur',
            'Delta Junction',
            'Demopolis',
            'Diamond Bar',
            'Dothan',
            'Downey',
            'Duarte',
            'El Cerrito',
            'El Monte',
            'El Segundo',
            'Elkhart',
            'Escondido',
            'Eufaula',
            'Eureka',
            'Evansville',
            'Fairbanks',
            'Fairfield',
            'Fayetteville',
            'Flagstaff',
            'Florence',
            'Florence',
            'Fontana',
            'Forrest City',
            'Fort Smith',
            'Fort Wayne',
            'Fountain Valley',
            'Frankfort',
            'Fremont',
            'Fresno',
            'Fullerton',
            'Gadsden',
            'Garden Grove',
            'Gardena',
            'Gary',
            'Gilbert',
            'Glendale',
            'Glendale',
            'Glendora',
            'Gulf Shores',
            'Half Moon Bay',
            'Hamilton',
            'Hammond',
            'Hawaiian Gardens',
            'Hawthorne',
            'Hayward',
            'Hermosa Beach',
            'Hidden Hills',
            'Hollister',
            'Hollywood',
            'Homer',
            'Hoover',
            'Hope',
            'Hopkinsville',
            'Hot Springs',
            'Huntington Beach',
            'Huntington Park',
            'Huntsville',
            'Indianapolis',
            'Indio',
            'Inglewood',
            'Irvine',
            'Irwindale',
            'Jasper',
            'Jeffersontown',
            'Jonesboro',
            'Juneau',
            'Kent',
            'Ketchikan',
            'Kettering',
            'Kokomo',
            'La Cañada Flintridge',
            'La Habra Heights',
            'La Habra',
            'La Jolla',
            'La Mirada',
            'La Palma',
            'La Puente',
            'La Verne',
            'Lafayette',
            'Laguna Beach',
            'Laguna Hills',
            'Laguna Niguel',
            'Laguna Woods',
            'Lake Forest',
            'Lakewood',
            'Lakewood',
            'Lancaster',
            'Lawndale',
            'Lexington',
            'Lima',
            'Little Rock',
            'Lodi',
            'Lomita',
            'Long Beach',
            'Los Alamitos',
            'Los Angeles',
            'Louisville',
            'Lynwood',
            'Malibu',
            'Manhattan Beach',
            'Marana',
            'Maywood',
            'Mentor',
            'Mentor-on-the-Lake',
            'Merced',
            'Mesa',
            'Michigan City',
            'Middletown',
            'Mission Viejo',
            'Mobile',
            'Modesto',
            'Monrovia',
            'Montebello',
            'Monterey Park',
            'Monterey',
            'Montgomery',
            'Moraga',
            'Moreno Valley',
            'Muncie',
            'Murray',
            'Murrieta',
            'Nenana',
            'Newport Beach',
            'Nogales',
            'Nome',
            'North Little Rock',
            'North Pole',
            'Norwalk',
            'Oakland',
            'Ontario',
            'Orange',
            'Oro Valley',
            'Owensboro',
            'Oxford',
            'Oxnard',
            'Paducah',
            'Palm Springs',
            'Palmdale',
            'Palo Alto',
            'Palos Verdes Estates',
            'Paramount',
            'Parma',
            'Pasadena',
            'Peoria',
            'Phenix City',
            'Phoenix',
            'Pico Rivera',
            'Pine Bluff',
            'Placentia',
            'Pomona',
            'Prescott',
            'Rancho Cordova',
            'Rancho Cucamonga',
            'Rancho Palos Verdes',
            'Rancho Santa Margarita',
            'Redding',
            'Redlands',
            'Redondo Beach',
            'Rialto',
            'Richmond',
            'Riverside',
            'Rohnert Park',
            'Rolling Hills Estates',
            'Rolling Hills',
            'Rosemead',
            'Roseville',
            'Sacramento',
            'Sahuarita',
            'Salinas',
            'San Bernardino',
            'San Clemente',
            'San Diego',
            'San Dimas',
            'San Fernando',
            'San Francisco',
            'San Gabriel',
            'San Jose',
            'San Juan Capistrano',
            'San Luis Obispo',
            'San Marino',
            'San Mateo',
            'San Rafael',
            'Santa Ana',
            'Santa Barbara',
            'Santa Clara',
            'Santa Clarita',
            'Santa Cruz',
            'Santa Fe Springs',
            'Santa Monica',
            'Santa Rosa',
            'Scottsdale',
            'Seal Beach',
            'Selma',
            'Seward',
            'Sierra Madre',
            'Sierra Vista',
            'Signal Hill',
            'Simi Valley',
            'Sitka',
            'Sonoma',
            'South Bend',
            'South El Monte',
            'South Gate',
            'South Pasadena',
            'Springdale',
            'Springfield',
            'Stanton',
            'Steubenville',
            'Stockton',
            'Sunnyvale',
            'Sutter Creek',
            'Temecula',
            'Tempe',
            'Temple City',
            'Terre Haute',
            'Texarkana',
            'Thousand Oaks',
            'Tok',
            'Toledo',
            'Torrance',
            'Troy',
            'Tucson',
            'Tuscaloosa',
            'Tuskegee',
            'Tustin',
            'Two Rivers',
            'Union City',
            'Valdez',
            'Valencia',
            'Vallejo',
            'Valparaiso',
            'Ventura',
            'Vernon',
            'Villa Park',
            'Vincennes',
            'Visalia',
            'Walnut',
            'West Covina',
            'West Hollywood',
            'West Lafayette',
            'West Memphis',
            'Westlake Village',
            'Westminster',
            'Whittier',
            'Wynne',
            'Yorba Linda',
            'Youngstown',
            'Yuma',
            'Zanesville',
    ],
);

=back

=head1 SEE ALSO

L<Data::Faker>

=head1 AUTHOR

Jason Kohles, E<lt>email@jasonkohles.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2004-2005 by Jason Kohles

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
