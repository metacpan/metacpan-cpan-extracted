use Test::More tests => 2;
use strict;
use warnings;
use Data::Dumper;

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my %meta = ( VARS => {}, FILES => [qw(t/include.t)]);
$App::Mowyw::config{default}{include} = 't/';
$App::Mowyw::config{default}{postfix} = '';

is parse_str('[%setvar t foo %][%include sample-include%]', \%meta),
    "sample include file !foo!\n",
    'Can include file, and read variable in the include file';
