
use inc::Module::Install;

name            ('Algorithm-HITS-Lite');
abstract        ('HITS Algorithm implementation not using PDL');
author          ('Kang-min Liu (gugod@gugod.org)');
license         ('perl');
version_from    ('lib/Algorithm/HITS/Lite.pm');
requires        ('Spiffy');

&WriteAll;

