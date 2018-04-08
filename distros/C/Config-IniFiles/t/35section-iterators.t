#!/usr/bin/perl

# See: https://bugs.debian.org/849298

use strict;
use warnings;

use Test::More tests => 2;

use Config::IniFiles;

my $ini_contents = <<'EOF';
[foo]
bar=baz
rab=zab
EOF

tie( my %ini, 'Config::IniFiles', -file => \$ini_contents );

my ( $k1, $v1 ) = each %{ $ini{foo} };
my ( $k2, $v2 ) = each %{ $ini{foo} };

# TEST
isnt( $k1, $k2, "got different keys with successive each() calls" );

# TEST
isnt( $v1, $v2, "got different values with successive each() calls" );
