use inc::Module::Install;

name            ('DBD-Multi');
abstract        ('Failover and Load Balancing of DBI Handles');
author          ('Dan Wright <dwright@cpan.org>');
version_from    ('lib/DBD/Multi.pm');
license         ('perl');
requires        ('perl' => 5.008);
requires        ('Class::Accessor::Fast' => 0.19 );
requires        ('Sys::SigAction'        => 0.10 );
requires        ('List::Util'            => 1.18 );
requires        ('DBI');
build_requires  ('Test::Pod::Coverage'   => 1.04 );
build_requires  ('Test::Pod'             => 1.14 );
build_requires  ('Test::Exception'       => 0.21 );
build_requires  ('DBD::SQLite'           => 1.09 );
build_requires  ('Pod::Simple');  # This is a pre-req for Test::Pod, but isn't listed.
build_requires  ('Test::More');

&WriteAll;
