use 5.10.1;
use strict;
use warnings;

use Test::More tests=>8;

BEGIN { use_ok( 'Bro::Log::Parse' ); }

my $parse = Bro::Log::Parse->new({ file => 'logs/ssl.log' });
my $line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");

open(my $fh, '<', 'logs/ssl.log');
$parse = Bro::Log::Parse->new({ fh => $fh });
$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");
close($fh);

@ARGV = ( 'logs/ssl.log' );
$parse = Bro::Log::Parse->new({ diamond => 1 });
$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CXWv6p3arKYeMETxOg', "uid");

$@ = undef;
eval {
	$parse = Bro::Log::Parse->new({ });
};
like($@, qr/^No filename given in constructor\./, "No file");
