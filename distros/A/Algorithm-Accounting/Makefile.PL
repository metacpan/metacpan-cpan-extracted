use inc::Module::Install;

name            ('Algorithm-Accounting');
abstract        ('Generate accounting statistic for general logs');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Algorithm/Accounting.pm');
requires        ('Spiffy');
requires        ('Perl6::Form');
requires        ('Array::Compare');
requires        ('List::Util');
requires        ('Array::Iterator::Reusable');
requires        ('FreezeThaw');
requires        ('Clone');
requires        ('YAML');
requires	('Imager::Graph::Pie');
requires	('GD::Graph');
build_requires  ('Test::More');


&WriteAll;

