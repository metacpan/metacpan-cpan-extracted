use inc::Module::Install;

name          'DateTime-Format-Duration-DurationString';
all_from      'lib/DateTime/Format/Duration/DurationString.pm';

requires 'DateTime::Duration';
requires 'Moo';
requires 'MooX::Types::MooseLike::Numeric';
requires 'Carp';

auto_install;
WriteAll;

