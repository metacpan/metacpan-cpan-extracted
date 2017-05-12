use Test::More tests => 3;
use strict;
use warnings;

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my %meta = ( OPTIONS => {}, );

is parse_str('[% option foo bar %]', \%meta), 
    '',
    '[% option ... %] returns empty string';

is $meta{OPTIONS}{foo}, 'bar', 'Option set correctly';
