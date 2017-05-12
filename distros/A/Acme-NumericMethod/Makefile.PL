use inc::Module::Install;
name            ('Acme-NumericMethod');
all_from        ('lib/Acme/NumericMethod.pm');
requires        ('Lingua::EN::Words2Nums');
build_requires  ('Test::More');

&auto_install;

&WriteAll;
