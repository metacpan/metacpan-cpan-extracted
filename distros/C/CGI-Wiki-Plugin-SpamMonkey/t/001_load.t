# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 2;

BEGIN { use_ok( 'CGI::Wiki::Plugin::SpamMonkey' ); }

my $object = CGI::Wiki::Plugin::SpamMonkey->new ();
isa_ok ($object, 'CGI::Wiki::Plugin::SpamMonkey');


