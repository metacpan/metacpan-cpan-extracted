use Test::More;

use Data::LNPath;

my $string = 'thing%20okay';
is(Data::LNPath::_unescape($string), 'thing okay');
$string = 'thing+okay';
is(Data::LNPath::_unescape($string), 'thing okay');
$string = 'thing+okay/okay/21';
is(Data::LNPath::_unescape($string), 'thing okay/okay/21');
$string = 'thing+okay/okay/%21';
is(Data::LNPath::_unescape($string), 'thing okay/okay/!');

$string = q!method( "arg1", 'arg2', {a => 'b'}, [ 1, 2, 3 ], meth )!;
is(Data::LNPath::_unescape($string), $string);

done_testing();
