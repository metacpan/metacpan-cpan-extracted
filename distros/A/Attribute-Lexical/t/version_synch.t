use warnings;
use strict;

use Test::More tests => 3;

BEGIN { require_ok "Attribute::Lexical"; }
my $main_ver = $Attribute::Lexical::VERSION;
ok defined($main_ver), "have main version number";
is $Attribute::Lexical::UNIVERSAL::VERSION, $main_ver, "version number matches";

1;
