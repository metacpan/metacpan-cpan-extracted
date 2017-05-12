use inc::Module::Install;

name            ('Catalyst-Model-JabberRPC');
abstract        ('JabberRPC Model Class for Catalyst');
author          ('Florian Merges <fmerges@cpan.org>');
license         ('perl');
version_from    ('lib/Catalyst/Model/JabberRPC.pm');

requires        ('Catalyst');
requires        ('Catalyst::Devel');
requires        ('NEXT');
requires        ('Jabber::RPC');
requires        ('Frontier::RPC2');

build_requires  ('Test::More');

&WriteAll;
