use inc::Module::Install 0.87;

name 'Catalyst-Engine-HTTP-Prefork';
all_from 'lib/Catalyst/Engine/HTTP/Prefork.pm';

requires 'Catalyst::Runtime'        => '5.7012';
requires 'Cookie::XS'               => '0.08';
requires 'HTTP::Body'               => '1.01';
requires 'Net::Server'              => '0.97';
requires 'HTTP::HeaderParser::XS'   => '0.20';

tests 't/0*.t';

auto_install;
resources repository => 'http://dev.catalyst.perl.org/repos/Catalyst/trunk/Catalyst-Engine-HTTP-Prefork/';

WriteAll;
