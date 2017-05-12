# -*- perl -*-

# t/001_basic.t - check to make sure its all working

use Test::More 'no_plan';

BEGIN { use_ok( 'Convert::Bencode', qw(bdecode bencode) ); }

my $test_string = "d7:Integeri42e4:Listl6:item 1i2ei3ee6:String9:The Valuee";
my $hashref = bdecode($test_string);

ok( defined $hashref, 'bdecode() returned something' );
is( ref($hashref), "HASH", 'bdecode() returned a valid hash ref' );
ok( defined ${$hashref}{'Integer'}, 'Integer key present' );
is( ${$hashref}{'Integer'}, 42, '  and its the correct value' );
ok( defined ${$hashref}{'String'}, 'String key present' );
is( ${$hashref}{'String'}, 'The Value', '  and its the correct value' );
ok( defined ${$hashref}{'List'}, 'List key present' );
is( @{${$hashref}{'List'}}, 3, '  list has 3 elements' );
is( ${${$hashref}{'List'}}[0], 'item 1', '    first element correct' );
is( ${${$hashref}{'List'}}[1], 2, '    second element correct' );
is( ${${$hashref}{'List'}}[2], 3, '    third element correct' );

my $encoded_string = bencode($hashref);

ok( defined $encoded_string, 'bencode() returned something' );
is( $encoded_string, $test_string, '  and it appears to be the correct value' );
