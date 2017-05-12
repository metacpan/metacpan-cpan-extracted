use 5.10.1;
use strict;
use warnings;

use Test::More tests=>9;

BEGIN { use_ok( 'Bro::Log::Parse' ); }

my $parse = Bro::Log::Parse->new('logs/sslx509.log');
my $line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
$line = $parse->getLine();
is(scalar keys %$line, 20, "Number of entries");
is($line->{uid}, 'CjhGID4nQcgTWjvg4c', "uid");
$line = $parse->getLine();
is(scalar keys %$line, 20, 'Number of entries');
is(scalar @{$parse->{headers}}, 1, 'Number of header lines');
is($parse->{headers}->[0], "#fields	ts	id	certificate.version	certificate.serial	certificate.subject	certificate.issuer	certificate.not_valid_before	certificate.not_valid_after	certificate.key_alg	certificate.sig_alg	certificate.key_type	certificate.key_length	certificate.exponent	certificate.curve	san.dns	san.uri	san.email	san.ip	basic_constraints.ca	basic_constraints.path_len", "Field definitions");
is($line->{id}, 'FlaIzV19yTmBYwWwc6', "id");
$line = $parse->getLine();
is($line->{id}, 'F0BeiV3cMsGkNML0P2', "id");
