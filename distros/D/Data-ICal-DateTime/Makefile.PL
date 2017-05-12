use inc::Module::Install;

name ('Data-ICal-DateTime');
author ('Simon Wistow <simon@thegestalt.org>');
version_from ('lib/Data/ICal/DateTime.pm');
abstract_from('lib/Data/ICal/DateTime.pm');
license('perl');
build_requires('Test::More');
build_requires('Test::Warn');
build_requires('Test::NoWarnings');
build_requires('Test::LongString');
requires('Class::Accessor');
requires('Data::ICal','0.07');
requires('Clone');
requires('DateTime::Set');
requires('DateTime::Format::ICal');
# requires('DateTime::Event::Recurrence','0.17');

&WriteAll;
