use Test::More tests => 2;
use strict;
use warnings;

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my %meta = ( VARS => {} );

is parse_str('a[% comment foo bar baz %]b', \%meta), 
        'ab', 
        'comment returns empty string';
