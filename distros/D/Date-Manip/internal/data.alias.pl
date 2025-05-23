#!/usr/bin/perl -w
# Copyright (c) 2008-2025 Sullivan Beck.  All rights reserved.
# This program is free software; you can redistribute it and/or modify it
# under the same terms as Perl itself.

# The following zones are treated specially. If they are in the tzdata
# files, they are ignored and created separately. Either there are
# problems with them, or they are defined in other standards ways.

%windows_zones =
  (
   "AUS Central Standard Time"       => "Australia/Darwin",
   "AUS Eastern Standard Time"       => "Australia/Sydney",
   "Afghanistan Standard Time"       => "Asia/Kabul",
   "Alaskan Standard Time"           => "America/Anchorage",
   "Aleutian Standard Time"          => "America/Adak",
   "Altai Standard Time"             => "Asia/Barnaul",
   "Arab Standard Time"              => "Asia/Riyadh",
   "Arabian Standard Time"           => "Asia/Dubai",
   "Arabic Standard Time"            => "Asia/Baghdad",
   "Argentina Standard Time"         => "America/Argentina/Buenos_Aires",
   "Astrakhan Standard Time"         => "Europe/Astrakhan",
   "Atlantic Standard Time"          => "America/Halifax",
   "Aus Central W. Standard Time"    => "Australia/Eucla",
   "Azerbaijan Standard Time"        => "Asia/Baku",
   "Azores Standard Time"            => "Atlantic/Azores",
   "Bahia Standard Time"             => "America/Bahia",
   "Bangladesh Standard Time"        => "Asia/Dhaka",
   "Belarus Standard Time"           => "Europe/Minsk",
   "Bougainville Standard Time"      => "Pacific/Bougainville",
   "Canada Central Standard Time"    => "America/Regina",
   "Cape Verde Standard Time"        => "Atlantic/Cape_Verde",
   "Caucasus Standard Time"          => "Asia/Yerevan",
   "Cen. Australia Standard Time"    => "Australia/Adelaide",
   "Central America Standard Time"   => "America/Guatemala",
   "Central Asia Standard Time"      => "Asia/Bishkek",
   "Central Brazilian Standard Time" => "America/Cuiaba",
   "Central Europe Standard Time"    => "Europe/Budapest",
   "Central European Standard Time"  => "Europe/Warsaw",
   "Central Pacific Standard Time"   => "Pacific/Guadalcanal",
   "Central Standard Time"           => "America/Chicago",
   "Central Standard Time (Mexico)"  => "America/Mexico_City",
   "Chatham Islands Standard Time"   => "Pacific/Chatham",
   "China Standard Time"             => "Asia/Shanghai",
   "Cuba Standard Time"              => "America/Havana",
   "Dateline Standard Time"          => "Etc/GMT+12",
   "E. Africa Standard Time"         => "Africa/Nairobi",
   "E. Australia Standard Time"      => "Australia/Brisbane",
   "E. Europe Standard Time"         => "Europe/Chisinau",
   "E. South America Standard Time"  => "America/Sao_Paulo",
   "Easter Island Standard Time"     => "Pacific/Easter",
   "Eastern Standard Time"           => "America/New_York",
   "Eastern Standard Time (Mexico)"  => "America/Cancun",
   "Egypt Standard Time"             => "Africa/Cairo",
   "Ekaterinburg Standard Time"      => "Asia/Yekaterinburg",
   "FLE Standard Time"               => "Europe/Kyiv",
   "Fiji Standard Time"              => "Pacific/Fiji",
   "GMT Standard Time"               => "Europe/London",
   "GTB Standard Time"               => "Europe/Bucharest",
   "Georgian Standard Time"          => "Asia/Tbilisi",
   "Greenland Standard Time"         => "America/Nuuk",
   "Greenwich Standard Time"         => "Africa/Abidjan",
   "Haiti Standard Time"             => "America/Port-au-Prince",
   "Hawaiian Standard Time"          => "Pacific/Honolulu",
   "India Standard Time"             => "Asia/Kolkata",
   "Iran Standard Time"              => "Asia/Tehran",
   "Israel Standard Time"            => "Asia/Jerusalem",
   "Jordan Standard Time"            => "Asia/Amman",
   "Kaliningrad Standard Time"       => "Europe/Kaliningrad",
   "Korea Standard Time"             => "Asia/Seoul",
   "Libya Standard Time"             => "Africa/Tripoli",
   "Line Islands Standard Time"      => "Pacific/Kiritimati",
   "Lord Howe Standard Time"         => "Australia/Lord_Howe",
   "Magadan Standard Time"           => "Asia/Magadan",
   "Magallanes Standard Time"        => "America/Punta_Arenas",
   "Marquesas Standard Time"         => "Pacific/Marquesas",
   "Mauritius Standard Time"         => "Indian/Mauritius",
   "Middle East Standard Time"       => "Asia/Beirut",
   "Montevideo Standard Time"        => "America/Montevideo",
   "Morocco Standard Time"           => "Africa/Casablanca",
   "Mountain Standard Time"          => "America/Denver",
   "Mountain Standard Time (Mexico)" => "America/Mazatlan",
   "Myanmar Standard Time"           => "Asia/Yangon",
   "N. Central Asia Standard Time"   => "Asia/Novosibirsk",
   "Namibia Standard Time"           => "Africa/Windhoek",
   "Nepal Standard Time"             => "Asia/Kathmandu",
   "New Zealand Standard Time"       => "Pacific/Auckland",
   "Newfoundland Standard Time"      => "America/St_Johns",
   "Norfolk Standard Time"           => "Pacific/Norfolk",
   "North Asia East Standard Time"   => "Asia/Irkutsk",
   "North Asia Standard Time"        => "Asia/Krasnoyarsk",
   "North Korea Standard Time"       => "Asia/Pyongyang",
   "Omsk Standard Time"              => "Asia/Omsk",
   "Pacific SA Standard Time"        => "America/Santiago",
   "Pacific Standard Time"           => "America/Los_Angeles",
   "Pacific Standard Time (Mexico)"  => "America/Tijuana",
   "Pakistan Standard Time"          => "Asia/Karachi",
   "Paraguay Standard Time"          => "America/Asuncion",
   "Qyzylorda Standard Time"         => "Asia/Qyzylorda",
   "Romance Standard Time"           => "Europe/Paris",
   "Russia Time Zone 10"             => "Asia/Srednekolymsk",
   "Russia Time Zone 11"             => "Asia/Kamchatka",
   "Russia Time Zone 3"              => "Europe/Samara",
   "Russian Standard Time"           => "Europe/Moscow",
   "SA Eastern Standard Time"        => "America/Cayenne",
   "SA Pacific Standard Time"        => "America/Bogota",
   "SA Western Standard Time"        => "America/La_Paz",
   "SE Asia Standard Time"           => "Asia/Bangkok",
   "Saint Pierre Standard Time"      => "America/Miquelon",
   "Sakhalin Standard Time"          => "Asia/Sakhalin",
   "Samoa Standard Time"             => "Pacific/Apia",
   "Sao Tome Standard Time"          => "Africa/Sao_Tome",
   "Saratov Standard Time"           => "Europe/Saratov",
   "Singapore Standard Time"         => "Asia/Singapore",
   "South Africa Standard Time"      => "Africa/Johannesburg",
   "South Sudan Standard Time"       => "Africa/Juba",
   "Sri Lanka Standard Time"         => "Asia/Colombo",
   "Sudan Standard Time"             => "Africa/Khartoum",
   "Syria Standard Time"             => "Asia/Damascus",
   "Taipei Standard Time"            => "Asia/Taipei",
   "Tasmania Standard Time"          => "Australia/Hobart",
   "Tocantins Standard Time"         => "America/Araguaina",
   "Tokyo Standard Time"             => "Asia/Tokyo",
   "Tomsk Standard Time"             => "Asia/Tomsk",
   "Tonga Standard Time"             => "Pacific/Tongatapu",
   "Transbaikal Standard Time"       => "Asia/Chita",
   "Turkey Standard Time"            => "Europe/Istanbul",
   "Turks And Caicos Standard Time"  => "America/Grand_Turk",
   "US Eastern Standard Time"        => "America/Indiana/Indianapolis",
   "US Mountain Standard Time"       => "America/Phoenix",
   "UTC"                             => "Etc/UTC",
   "UTC+12"                          => "Etc/GMT-12",
   "UTC+13"                          => "Etc/GMT-13",
   "UTC-02"                          => "Etc/GMT+2",
   "UTC-08"                          => "Etc/GMT+8",
   "UTC-09"                          => "Etc/GMT+9",
   "UTC-11"                          => "Etc/GMT+11",
   "Ulaanbaatar Standard Time"       => "Asia/Ulaanbaatar",
   "Venezuela Standard Time"         => "America/Caracas",
   "Vladivostok Standard Time"       => "Asia/Vladivostok",
   "Volgograd Standard Time"         => "Europe/Volgograd",
   "W. Australia Standard Time"      => "Australia/Perth",
   "W. Central Africa Standard Time" => "Africa/Lagos",
   "W. Europe Standard Time"         => "Europe/Berlin",
   "W. Mongolia Standard Time"       => "Asia/Hovd",
   "West Asia Standard Time"         => "Asia/Tashkent",
   "West Bank Standard Time"         => "Asia/Hebron",
   "West Pacific Standard Time"      => "Pacific/Port_Moresby",
   "Yakutsk Standard Time"           => "Asia/Yakutsk",
   "Yukon Standard Time"             => "America/Whitehorse",
  );

%hpux_zones = (
   # tztab $Date: 2008/12/08 17:21:29 $Revision: r11.11/12 PATCH_11.11 (PHCO_39172)

   'ARST3ARDT'                       => 'America/Argentina/Buenos_Aires',
   'AST10ADT'                        => 'America/Adak',
   'AST4ADT#Canada'                  => 'America/Halifax',
   'BRST3BRDT'                       => 'America/Sao_Paulo',
   'BRWST4BRWDT'                     => 'America/Campo_Grande',
   'CSM6CDM'                         => 'America/Mexico_City',
   'CST-9:30CDT'                     => 'Australia/Adelaide',
   'CST6CDT#Canada'                  => 'America/Winnipeg',
   'CST6CDT#Indiana'                 => 'America/Indiana/Indianapolis',
   'CST6CDT#Mexico'                  => 'America/Mexico_City',
   'EET-2EETDST'                     => 'Europe/Helsinki',
   'EST-10EDT'                       => 'Australia/Melbourne',
   'EST-10EDT#NSW'                   => 'Australia/Sydney',
   'EST-10EDT#Tasmania'              => 'Australia/Hobart',
   'EST-10EDT#VIC'                   => 'Australia/Melbourne',
   'EST5CDT'                         => 'America/Indiana/Indianapolis',
   'EST5EDT#Canada'                  => 'America/Toronto',
   'EST5EDT#Indiana'                 => 'America/Indiana/Indianapolis',
   'EST5EST'                         => 'America/Indiana/Indianapolis',
   'EST6CDT'                         => 'America/Indiana/Indianapolis',
   'MET-1METDST'                     => 'Europe/Brussels',
   'MEZ-1MESZ'                       => 'Europe/Brussels',
   'MSM7MDM'                         => 'America/Chihuahua',
   'MST7MDT#Canada'                  => 'America/Edmonton',
   'MST7MDT#Mexico'                  => 'America/Chihuahua',
   'MXST6MXDT'                       => 'America/Mexico_City',
   'MXST6MXDT#Mexico'                => 'America/Mexico_City',
   'NST3:30NDT'                      => 'America/St_Johns',
   'NST3:30NDT#Canada'               => 'America/St_Johns',
   'PST8PDT#Canada'                  => 'America/Vancouver',
   'PWT0PST'                         => 'Europe/Lisbon',
   'SAST-2'                          => 'Africa/Johannesburg',
   'WET0WETDST'                      => 'Europe/Lisbon',
   'WST-10WSTDST'                    => 'Asia/Vladivostok',
   'WST-11WSTDST'                    => 'Asia/Srednekolymsk',
   'WST-12WSTDST'                    => 'Asia/Kamchatka',
   'WST-2WSTDST'                     => 'Europe/Minsk',
   'WST-3WSTDST'                     => 'Europe/Moscow',
   'WST-4WSTDST'                     => 'Europe/Samara',
   'WST-5WSTDST'                     => 'Asia/Yekaterinburg',
   'WST-6WSTDST'                     => 'Asia/Omsk',
   'WST-7WSTDST'                     => 'Asia/Krasnoyarsk',
   'WST-8WDT'                        => 'Australia/Perth',
   'WST-8WSTDST'                     => 'Asia/Irkutsk',
   'WST-9WSTDST'                     => 'Asia/Yakutsk',
  );

%nontzdata_zones =
  (
   # The standard GMT+OFF zones don't dump well, so
   # we'll create them manually.

   "Etc/GMT-1"        => [ qw(offset   -1:00:00) ],
   "Etc/GMT-2"        => [ qw(offset   -2:00:00) ],
   "Etc/GMT-3"        => [ qw(offset   -3:00:00) ],
   "Etc/GMT-4"        => [ qw(offset   -4:00:00) ],
   "Etc/GMT-5"        => [ qw(offset   -5:00:00) ],
   "Etc/GMT-6"        => [ qw(offset   -6:00:00) ],
   "Etc/GMT-7"        => [ qw(offset   -7:00:00) ],
   "Etc/GMT-8"        => [ qw(offset   -8:00:00) ],
   "Etc/GMT-9"        => [ qw(offset   -9:00:00) ],
   "Etc/GMT-10"       => [ qw(offset  -10:00:00) ],
   "Etc/GMT-11"       => [ qw(offset  -11:00:00) ],
   "Etc/GMT-12"       => [ qw(offset  -12:00:00) ],
   "Etc/GMT-13"       => [ qw(offset  -13:00:00) ],
   "Etc/GMT-14"       => [ qw(offset  -14:00:00) ],
   "Etc/GMT+1"        => [ qw(offset    1:00:00) ],
   "Etc/GMT+2"        => [ qw(offset    2:00:00) ],
   "Etc/GMT+3"        => [ qw(offset    3:00:00) ],
   "Etc/GMT+4"        => [ qw(offset    4:00:00) ],
   "Etc/GMT+5"        => [ qw(offset    5:00:00) ],
   "Etc/GMT+6"        => [ qw(offset    6:00:00) ],
   "Etc/GMT+7"        => [ qw(offset    7:00:00) ],
   "Etc/GMT+8"        => [ qw(offset    8:00:00) ],
   "Etc/GMT+9"        => [ qw(offset    9:00:00) ],
   "Etc/GMT+10"       => [ qw(offset   10:00:00) ],
   "Etc/GMT+11"       => [ qw(offset   11:00:00) ],
   "Etc/GMT+12"       => [ qw(offset   12:00:00) ],
   "Etc/GMT"          => [ qw(offset    0:00:00) ],

   # There are some other problems in dumping zones
   # that we'll solve by aliasing some zones. They
   # could probably be handled by a more intelligent
   # handling of the tzdata files, but this is simpler.

   "GMT"              => [ qw(alias    Etc/GMT) ],
   "Etc/UTC"          => [ qw(offset   0:00:00) ],
#  "UCT"              => [ qw(alias    UTC) ],
#  "Etc/UCT"          => [ qw(alias    UTC) ],
#  "Etc/UTC"          => [ qw(alias    UTC) ],
   "Pacific/Johnston" => [ qw(alias    Pacific/Honolulu) ],
   "HST"              => [ qw(ignore) ],
   "EST"              => [ qw(ignore) ],
   "MST"              => [ qw(ignore) ],

   # The following are set by RFC-822.

   "A"                => [ qw(offset   -1:00:00) ],
   "B"                => [ qw(offset   -2:00:00) ],
   "C"                => [ qw(offset   -3:00:00) ],
   "D"                => [ qw(offset   -4:00:00) ],
   "E"                => [ qw(offset   -5:00:00) ],
   "F"                => [ qw(offset   -6:00:00) ],
   "G"                => [ qw(offset   -7:00:00) ],
   "H"                => [ qw(offset   -8:00:00) ],
   "I"                => [ qw(offset   -9:00:00) ],
   "K"                => [ qw(offset  -10:00:00) ],
   "L"                => [ qw(offset  -11:00:00) ],
   "M"                => [ qw(offset  -12:00:00) ],
   "N"                => [ qw(offset    1:00:00) ],
   "O"                => [ qw(offset    2:00:00) ],
   "P"                => [ qw(offset    3:00:00) ],
   "Q"                => [ qw(offset    4:00:00) ],
   "R"                => [ qw(offset    5:00:00) ],
   "S"                => [ qw(offset    6:00:00) ],
   "T"                => [ qw(offset    7:00:00) ],
   "U"                => [ qw(offset    8:00:00) ],
   "V"                => [ qw(offset    9:00:00) ],
   "W"                => [ qw(offset   10:00:00) ],
   "X"                => [ qw(offset   11:00:00) ],
   "Y"                => [ qw(offset   12:00:00) ],
   "Z"                => [ qw(offset    0:00:00) ],
   "UT"               => [ qw(offset    0:00:00) ],
  );

foreach my $winz (keys %windows_zones) {
   my $zone = $windows_zones{$winz};
   $nontzdata_zones{$winz} = [ 'alias', $zone ];
}
foreach my $hpuxz (keys %hpux_zones) {
   my $zone = $hpux_zones{$hpuxz};
   $nontzdata_zones{$hpuxz} = [ 'alias', $zone ];
}

# Zone aliases of the form "EST5EDT" are handled here. In most cases,
# there are more than one possibile zone that they could apply to.
# Every possibility should be included here (so that they can be
# included in the docs) but the first one will be used.

%def_alias2 =
  (
   # These are set in RFC 822 and the default (first) value will NOT
   # be modified ever.
   'CST6CDT'       => [ 'America/Chicago' => 'America/Winnipeg' ],
   'EST5EDT'       => 'America/New_York',
   'MST7MDT'       => 'America/Denver',
   'PST8PDT'       => 'America/Los_Angeles',

   # Open to discussion

   'AEST-10AEDT'   => [ 'Australia/Melbourne' => 'Australia/Hobart' ],
   'AHST10AHDT'    => 'America/Anchorage',
   'AKST9AKDT'     => 'America/Anchorage',
   'AST10APT'      => 'America/Anchorage',
   'AST4ADT'       => 'America/Halifax',
   'AST4APT'       => 'America/Glace_Bay',
   'AWST-8AWDT'    => 'Australia/Perth',
   'BST11BDT'      => 'America/Adak',
   'CAT-2CAST'     => 'Africa/Juba',
   'CAT-2WAT'      => 'Africa/Windhoek',
   'CET-1CEST'     => [ 'Europe/Brussels' => 'Europe/Berlin' ],
   'CET-1WEMT'     => 'Europe/Paris',
   'CST-8CDT'      => 'Asia/Shanghai',
   'CST5CDT'       => 'America/Havana',
   'CST6CPT'       => 'America/Belize',
   'CST6CWT'       => 'America/Belize',
   'EET-2EEST'     => [ 'Europe/Athens' => 'Asia/Beirut' ],
   'EST5EPT'       => [ 'America/New_York' => 'America/Detroit' ],
   'GMT0BST'       => 'Europe/London',
   'GMT0IST'       => 'Europe/Dublin',
   'GST-10GDT'     => 'Pacific/Guam',
   'HKT-8HKST'     => 'Asia/Hong_Kong',
   'HST10HDT'      => 'America/Adak',
   'IST-1GMT'      => 'Europe/Dublin',
   'IST-2EEST'     => 'Asia/Gaza',
   'IST-2IDT'      => 'Asia/Jerusalem',
   'JST-9JDT'      => 'Asia/Tokyo',
   'KST-9KDT'      => 'Asia/Seoul',
   'MSK-3CEST'     => [ 'Europe/Minsk' => 'Europe/Chisinau' ],
   'MSK-3MSD'      => 'Europe/Moscow',
   'MST7MPT'       => [ 'America/Denver' => 'America/Boise' ],
   'NST11NPT'      => 'America/Adak',
   'NZST-12NZDT'   => 'Pacific/Auckland',
   'PKT-5PKST'     => 'Asia/Karachi',
   'PST-8PDT'      => 'Asia/Manila',
   'PST8PPT'       => [ 'America/Los_Angeles' => 'America/Dawson_Creek' ],
   'SAST-2SAST'    => 'Africa/Johannesburg',
   'WET0WEST'      => 'Europe/Lisbon',
   'YST9YDT'       => 'America/Yakutat',
   'YST9YPT'       => [ 'America/Whitehorse' => 'America/Dawson' ],
  );

1;

# Local Variables:
# mode: cperl
# indent-tabs-mode: nil
# cperl-indent-level: 3
# cperl-continued-statement-offset: 2
# cperl-continued-brace-offset: 0
# cperl-brace-offset: 0
# cperl-brace-imaginary-offset: 0
# cperl-label-offset: 0
# End:
