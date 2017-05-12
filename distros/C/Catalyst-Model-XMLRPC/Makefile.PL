use inc::Module::Install;

name            ('Catalyst-Model-XMLRPC');
abstract        ('XMLRPC Model Class for Catalyst');
author          ('Florian Merges <fmerges@cpan.org>');
license         ('perl');
version_from    ('lib/Catalyst/Model/XMLRPC.pm');

requires        ('Catalyst');
requires        ('Catalyst::Devel');
requires        ('NEXT');
requires        ('RPC::XML');

build_requires  ('Test::More');

&WriteAll;
