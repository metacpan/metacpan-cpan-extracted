use strict;
use warnings;

use Data::Kramerius;
use Test::More 'tests' => 6;
use Test::NoWarnings;
use Unicode::UTF8 qw(decode_utf8);

# Test.
my $obj = Data::Kramerius->new;
my $ret = $obj->get('nkp');
is($ret->id, 'nkp', 'Get Kramerius of nkp - id');
is($ret->name, decode_utf8('Národní knihovna'), 'Get Kramerius of nkp - name');
is($ret->version, 4, 'Get Kramerius of nkp - version');
is($ret->url, 'http://kramerius5.nkp.cz/', 'Get Kramerius of nkp - url');

# Test.
$obj = Data::Kramerius->new;
$ret = $obj->get('foo');
is($ret, undef, 'Unknown Kramerius system.');
