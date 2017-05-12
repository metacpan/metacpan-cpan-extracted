use inc::Module::Install;

name ('Class-Accessor-Named');
author ('Jesse Vincent <jesse@bestpractical.com>');
version_from ('lib/Class/Accessor/Named.pm');
abstract_from('lib/Class/Accessor/Named.pm');
license('perl');
requires('Hook::LexWrap');
requires('Class::Accessor');
requires('Hook::LexWrap');
requires('Sub::Name');
requires('UNIVERSAL::require');
sign();
auto_install();
&WriteAll;
