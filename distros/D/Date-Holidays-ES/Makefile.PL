use inc::Module::Install;

name            ('Date-Holidays-ES');
abstract        ('Spanish holidays for Date::Holidays');
author          ('Florian Merges <fmerges@cpan.org>');
license         ('perl');
version_from    ('lib/Date/Holidays/ES.pm');
requires        ('Date::Holidays');
requires        ('Date::Holidays::Super');
requires        ('Date::Easter');
requires        ('Time::JulianDay');
requires        ('DateTime');
build_requires  ('Test::More');

&WriteAll;

