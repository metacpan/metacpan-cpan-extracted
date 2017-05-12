use inc::Module::Install;

name            ('Acme-VarMess');
abstract        ('Blow up your variable names');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/Acme/VarMess.pm');
license         ('perl');

build_requires  ('Test::More');
requires        ('PPI');
auto_install();

&WriteAll;

