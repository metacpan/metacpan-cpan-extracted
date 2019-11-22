use 5.10.1;
use strict;
use warnings;

use Test::More tests=>5;

BEGIN { use_ok( 'Bro::Log::Parse' ); }

my $parse = Bro::Log::Parse->new('logs/x509-incomplete.log');
my $line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{ts}, '1394747126.862409', "ts");

$line = $parse->getLine();
is($line, undef, 'EOF');
