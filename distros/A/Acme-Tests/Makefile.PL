use inc::Module::Install;

name            ('Acme-Tests');
all_from        ('lib/Acme/Tests.pm');
requires        (
    'Spiffy'     => 0.22,
    'List::Util' => 0
);
build_requires  ('Test::More');

&WriteAll;

