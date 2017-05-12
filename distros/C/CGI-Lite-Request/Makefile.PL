use inc::Module::Install;

name('CGI-Lite-Request');
author('Richard Hundt <richard NO SPAM AT protea-systems.com>');
abstract('Request class for CGI::Lite');
license('artistic');
version_from('lib/CGI/Lite/Request.pm');
build_requires('Test::More');

requires($_) for (qw(
    File::Spec
    File::Type
    File::Copy
    CGI::Lite
    IO::File
    HTTP::Headers
    URI
));

check_nmake();
&WriteAll();
