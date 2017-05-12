#!/usr/bin/perl

=head1 NAME

soapcli - SOAP client for CLI with YAML and JSON input and output

=head1 SYNOPSIS

B<soapcli>
S<[--verbose|-v]>
S<[--dump-xml-request|-x]>
S<[--json|-j]>
S<[--yaml|-y]>
data.yml|data.json|{string:"JSON"}|-
[webservice.wsdl|webservice_wsdl.url]
[[http://example.com/endpoint|endpoint.url][#port]]
[operation]

B<soapcli>
S<[--help|-h]>

Examples:

  $ soapcli calculator-correct.json

  $ soapcli -y '{add:{x:2,y:2}}' http://soaptest.parasoft.com/calculator.wsdl

  $ soapcli -v globalweather.yml globalweather.url '#GlobalWeatherSoap'

  $ soapcli '{CityName:"Warszawa",CountryName:"Poland"}' \
  http://www.webservicex.com/globalweather.asmx?WSDL \
  '#GlobalWeatherSoap' GetWeather

=head1 DESCRIPTION

This is command-line SOAP client which accepts YAML or JSON document as
an input data.

The first argument is a request data as a JSON string or a name of file which
contains data in JSON or YAML format.

The second argument is an URL address to WSDL data or a filename of WSDL data
file or a file which contains an URL address to WSDL data. This filename is
optional and can be guessed from first argument.

The third argument is an URL address of endpoint with a name of a webservice
port. The URL address of endpoint is optional if is already a part of WSDL
data. The name of port is optional if it is unambiguous for called method. The
name of port should start with C<#> character.

The fourth argument is a name of method. It is optional if a name of method is
already a part of request data.

The result will be dumped as JSON (by default) or YAML.

=cut


use 5.006;

use strict;
use warnings;

our $VERSION = '0.0300';

require App::soapcli;

App::soapcli->new_with_options->run;


=head1 INSTALLATION

=head2 Debian/Ubuntu

  $ sudo apt-get install cpanminus build-essential libxml2-dev zlib1g-dev

  $ sudo apt-get install libyaml-syck-perl libyaml-libyaml-perl \
    libjson-pp-perl libhtml-tiny-perl libgetopt-long-descriptive-perl \
    libperl6-slurp-perl libxml-libxml-simple-perl libtest-tester-perl \
    libtest-nowarnings-perl libtest-deep-perl

  $ sudo cpanm App::soapcli

=head1 SEE ALSO

L<http://github.com/dex4er/soapcli>.

=head1 BUGS

This tool has unstable features and can change in future.

The tool is limited to webservices which support SOAP with document-literal
style only.

=head1 AUTHOR

Piotr Roszatycki <dexter@cpan.org>

=head1 LICENSE

Copyright (c) 2011-2015 Piotr Roszatycki <dexter@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as perl itself.

See L<http://dev.perl.org/licenses/artistic.html>

=cut

__END__
