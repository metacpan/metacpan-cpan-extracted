use strict;
use warnings;
use Test::More;
use Business::RO::CIF;

my $text = '12345o23';
ok my $cif = Business::RO::CIF->new( cif => $text ), 'new with invalid characters';
is $cif->valid, 0, 'valid';
like $cif->errstr, qr/invalid/, 'error string';

$text = '12345';
ok $cif = Business::RO::CIF->new( cif => $text ), 'new, too short';
is $cif->valid, 0, 'valid';
like $cif->errstr, qr/short/, 'error string';

$text = '12345678901';
ok $cif = Business::RO::CIF->new( cif => $text ), 'new, too long';
is $cif->valid, 0, 'valid';
like $cif->errstr, qr/long/, 'error string';

$text = '1234567890';
ok $cif = Business::RO::CIF->new( cif => $text ), 'new non valid CIF';
is $cif->valid, 0, 'valid';
like $cif->errstr, qr/checksum/, 'error string';

$text = 1234567890;
ok $cif = Business::RO::CIF->new( cif => $text ), 'new non valid CIF (number)';
is $cif->valid, 0, 'valid';
like $cif->errstr, qr/checksum/, 'error string';

$text = '8915831';
ok $cif = Business::RO::CIF->new( cif => $text ), 'new valid CIF';
is $cif->valid, 1, 'valid';
is $cif->errstr, '', 'error string';

$text = 8915831;
ok $cif = Business::RO::CIF->new( cif => $text ), 'new valid CIF (number)';
is $cif->valid, 1, 'valid';
is $cif->errstr, '', 'error string';

$text = 'RO8915831';
ok $cif = Business::RO::CIF->new( cif => $text ), 'new valid CIF';
is $cif->valid, 1, 'valid';
is $cif->errstr, '', 'error string';

$text = 'RO  8915831';
ok $cif = Business::RO::CIF->new( cif => $text ), 'new valid CIF';
is $cif->valid, 1, 'valid';
is $cif->errstr, '', 'error string';

$text = 'RO  8915831';
ok $cif = Business::RO::CIF->new($text), 'new valid CIF param as value';
is $cif->valid, 1, 'valid';
is $cif->errstr, '', 'error string';

done_testing;
