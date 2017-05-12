use inc::Module::Install;

name            ('Acme-PerlTidy');
abstract        ('Clean code every time');
author          ('Yung-chung Lin <xern@cpan.org>');
version_from    ('lib/Acme/PerlTidy.pm');
license         ('perl');

build_requires  ('Test::More');
requires        ('Perl::Tidy');
auto_install();

&WriteAll;

