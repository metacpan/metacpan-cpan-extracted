use strict;
use warnings;
use inc::Module::Install;

name           'DateTime-Calendar-Liturgical-Christian';
all_from       'lib/DateTime/Calendar/Liturgical/Christian.pm';

abstract       'Calendar of the church year';
author         'Thomas Thurman <tthurman@gnome.org>';
version        '0.10';
license        'perl';

requires 'Date::Calc';
requires 'Storable';
requires 'Exporter';

WriteAll;
