use inc::Module::Install;

name            ('Catalyst-Contoller-View');
abstract        ('Catalyst Controller that directly delegates to View');
author          ('Kang-min Liu <gugod@gugod.org>');
license         ('perl');
version_from    ('lib/Catalyst/Contoller/View.pm');
requires        ('Catalyst');
build_requires  ('Test::More');

include('ExtUtils::AutoInstall');
auto_install();
&WriteAll;

