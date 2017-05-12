#!/usr/bin/perl

use strict;
use warnings;

use Carp ();

$SIG{__WARN__} = sub { local $Carp::CarpLevel = 1; Carp::confess("Warning: ", @_) };

use Test::More tests => 3;

BEGIN { use_ok 'App::soapcli' };

my $app = App::soapcli->new( dump_xml_request => 1, extra_argv => [
    'examples/globalweather.yml', 'examples/globalweather.wsdl', '#GlobalWeatherSoap12'
] );
is ref $app, 'App::soapcli', '$app isa App::soapcli';

my $buf;
{
    open my $fh, '>', \$buf or die $!;
    local *STDOUT = *$fh;
    $app->run;
}
is $buf, << 'END', 'XML request';
<?xml version="1.0" encoding="UTF-8"?>
<env12:Envelope xmlns:env12="http://www.w3.org/2003/05/soap-envelope">
  <env12:Body>
    <tns:GetWeather xmlns:tns="http://www.webserviceX.NET">
      <tns:CityName>Warszawa</tns:CityName>
      <tns:CountryName>Poland</tns:CountryName>
    </tns:GetWeather>
  </env12:Body>
</env12:Envelope>
END
