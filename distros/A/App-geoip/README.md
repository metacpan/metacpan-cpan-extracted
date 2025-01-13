## GeoIP2

Based on [PerlMonks](https://www.perlmonks.org/) posts
[1226112](https://www.perlmonks.org/?node_id=1226112) and
[1226223](https://www.perlmonks.org/?node_id=1226223) by
[cavac](https://www.perlmonks.org/?node_id=890813), this is my attempt in
opening the GeoIP2 data from [MAXMIND](https://dev/maxmind.com)
available [here](https://dev.maxmind.com/geoip/geoip2/geolite2/)

The [download section](https://dev.maxmind.com/geoip/geoip2/geolite2/#Downloads)
has three CSV databases available:

 - [Country](http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip)
 - [Provider](http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN-CSV.zip)
 - [City](http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip)

If you download all three, and create a postgres database `geoip`, then
[geoip](geoip) will convert all CSV data to database tables.

## Use

``` sh
 $ perl geoip
 $ perl geoip 66.39.54.27 209.197.123.153 216.92.34.251
 $ perl geoip perlmonks.org
```

Once the database is filled, the last call might return something like

```
GeoIP data for 66.39.54.27 - www.perlmonks.com:
   CIDR      : 66.39.0.0/16
   IP range  : 66.39.0.0 - 66.39.255.255
   Provider  : pair Networks
   City      : Pittsburgh, 508, 15203
   Country   : US  United States
   Continent : North America
   Location  :   40.4254 /  -79.9799 (1000)   40°25'31.44" /  -79°58'47.64"
               https://www.openstreetmap.org/#map=10/40.4254/-79.9799
               https://www.google.com/maps/place/@40.4254,-79.9799,10z
   Timezone  : America/New_York
   EU member : No
   Satellite : No
   Anon Proxy: No
```

and, when you also use the `--dist` option
```
Using GeoIP to determine own location
GeoIP data for 66.39.54.27 - www.perlmonks.com:
   CIDR      : 66.39.0.0/16
   IP range  : 66.39.0.0 - 66.39.255.255
   Provider  : pair Networks
   City      : Pittsburgh, 508, 15203
   Country   : US  United States
   Continent : North America
   Location  :   40.4254 /  -79.9799 (1000)   40°25'31.44" /  -79°58'47.64"
               https://www.openstreetmap.org/#map=10/40.4254/-79.9799
               https://www.google.com/maps/place/@40.4254,-79.9799,10z
   Location  :   52.3824 /    4.8995          52°22'56.64" /    4°53'58.20"
   Distance  : ± 6258.19km
   Timezone  : America/New_York
   EU member : No
   Satellite : No
   Anon Proxy: No
```

## PREREQUISITES

- perl-5.14.0
- Socket (CORE since per-5.000)
- [Archive::Zip](https://metacpan.org/release/Archive-Zip)
- [Text::CSV_XS](https://metacpan.org/release/Text-CSV_XS)-1.35
- [Net::CIDR](https://metacpan.org/release/Net-CIDR)

For use of the `--dist` option, two additional modules are required.
This functionality is optional, `geoip` will work perfectly fine
without these.

- [LWP::UserAgent](https://metacpan.org/release/LWP-UserAgent)
- [HTML::TreeBuilder](https://metacpan.org/release/HTML-TreeBuilder)

## INSTALLATION

Using PostgreSQL:
```
$ echo "create database geoip;" | psql -f -
$ perl ./geoip --fetch
$ ln geoip ~/bin/
```

Using SQLite (database will be close to 500 Mb):
```
$ perl ./geoip --fetch --DB=dbi:SQLite:dbname=geoip.db
```
or
```
$ export GEOIP_DBI_DSN=dbi:SQLite:dbname=/my/databases/geoip.db
$ perl ./geoip --fetch
```

Depending on the amount of memory you have, this might take a while.

You can also fetch the files yourself

```
$ wget -m -L -nd -np -nH \
 http://geolite.maxmind.com/download/geoip/database/GeoLite2-ASN-CSV.zip  \
 http://geolite.maxmind.com/download/geoip/database/GeoLite2-City-CSV.zip \
 http://geolite.maxmind.com/download/geoip/database/GeoLite2-Country-CSV.zip
```

## TODO

- IPv6. The current version only implements the IPv4 part. The CSV files however
  also the IPv6 data, so it should not be too hard to add.

## SEE ALSO

This tool uses the following modules from CORE and CPAN:

- [Archive::Zip](https://metacpan.org/release/Archive-Zip)
- [Data::Dumper](https://metacpan.org/release/Data-Dumper) (core)
- [Data::Peek](https://metacpan.org/release/Data-Peek) (optional)
- [Getopt::Long](https://metacpan.org/release/Getopt-Long) (core)
- [GIS::Distance](https://metacpan.org/release/GIS-Distance) (optional)
- [HTML::TreeBuilder](https://metacpan.org/release/HTML-TreeBuilder) (optional)
- [LWP::Simple](https://metacpan.org/release/LWP-Simple)
- [LWP::UserAgent](https://metacpan.org/release/LWP-UserAgent) (optional)
- [Math::Trig](https://metacpan.org/release/Math-Complex) (core)
- [Net::CIDR](https://metacpan.org/release/Net-CIDR)
- [Socket](https://metacpan.org/release/Socket) (core)
- [Text::CSV_XS](https://metacpan.org/release/Text-CSV_XS)

Modules on CPAN with similar and/or related functionality:

- [Geo::Coder::HostIP](https://metacpan.org/release/Geo-Coder-HostIP)
- [Geo::IP](https://metacpan.org/release/Geo-IP) - from maxmind
- [Geo::IP2Location](https://metacpan.org/release/Geo-IP2Location)
- [Geo::IP2Proxy](https://metacpan.org/release/Geo-IP2Proxy)
- [Geo::IP6](https://metacpan.org/release/Geo-IP6)
- [Geo::IPfree](https://metacpan.org/release/Geo-IPfree) - using [software77](http://software77.net/geo-ip/) database
- [Geo::IP::RU::IpGeoBase](https://metacpan.org/release/Geo-IP-RU-IpGeoBase)
- [IP::Country](https://metacpan.org/release/IP-Country)
- [IP::Country::DB_File](https://metacpan.org/release/IP-Country-DB_File)
- [IP::Country::DNSBL](https://metacpan.org/release/IP-Country-DNSBL)
- [IP::Info](https://metacpan.org/release/IP-Info)
- [IP::Location](https://metacpan.org/release/IP-Location)
- [IP::QQWry](https://metacpan.org/release/IP-QQWry)
- [IP::World](https://metacpan.org/release/IP-World)
- [Metabrik::Lookup::Iplocation](https://metacpan.org/release/Metabrik-Lookup-Iplocation)
- [Pcore::GeoIP](https://metacpan.org/release/Pcore-GeoIP)

Check [CPAN](https://metacpan.org/search?q=geoip) for more

## THANKS

Thanks to cavac for the inspiration

## AUTHOR

H.Merijn Brand <hmbrand@cpan.org>

## COPYRIGHT AND LICENSE

The GeoLite2 end-user license agreement, which incorporates components of the
Creative Commons Attribution-ShareAlike 4.0 International License 1) can be found
[here](https://www.maxmind.com/en/geolite2/eula) 2). The attribution requirement
may be met by including the following in all advertising and documentation
mentioning features of or use of this database.

This tool uses, but does not include, the GeoLite2 data created by MaxMind,
available from [http://www.maxmind.com](http://www.maxmind.com).

 Copyright (C) 2018-2025 H.Merijn Brand.  All rights reserved.

This library is free software;  you can redistribute and/or modify it under
the same terms as Perl itself.
See [here](https://opensource.org/licenses/Artistic-2.0) 3).

 1) [https://creativecommons.org/licenses/by-sa/4.0/](https://creativecommons.org/licenses/by-sa/4.0/)
 2) [https://www.maxmind.com/en/geolite2/eula](https://www.maxmind.com/en/geolite2/eula)
 3) [https://opensource.org/licenses/Artistic-2.0](https://opensource.org/licenses/Artistic-2.0)
