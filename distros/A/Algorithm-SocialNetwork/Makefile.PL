use inc::Module::Install;

name            ('Algorithm-SocialNetwork');
abstract        ('Social Network Analysis');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Algorithm/SocialNetwork.pm');
requires        ('Spiffy' => 0.21);
requires        ('Graph' => 0.54);
requires        ('Quantum::Superpositions');
build_requires  ('Test::More');

&WriteAll;

