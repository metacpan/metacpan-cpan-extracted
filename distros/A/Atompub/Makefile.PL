use strict;
use warnings;
use inc::Module::Install;

name('Atompub');
all_from('lib/Atompub.pm');
license('perl');

requires('Class::Accessor::Fast');
requires('Class::Data::Inheritable');
requires('DateTime');
requires('DateTime::Format::W3CDTF');
requires('DateTime::TimeZone');
requires('Digest::SHA');
requires('File::Slurp');
requires('HTTP::Date');
requires('HTTP::Headers');
requires('HTTP::Request');
requires('HTTP::Response');
requires('HTTP::Status');
requires('MIME::Base64');
requires('MIME::Types');
requires('Module::Build::Compat');
requires('Perl6::Export::Attrs');
requires('Test::Perl::Critic');
requires('Time::Local');
requires('URI::Escape');
requires('XML::Atom::Service', 0.016);

requires('version', 0.74);

build_requires('Test::More');
build_requires('Test::Perl::Critic');

#auto_include;
auto_install;

WriteAll;
