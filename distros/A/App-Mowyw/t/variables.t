use Test::More tests => 8;
use strict;
use warnings;

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my %meta = ( VARS => {} );

is parse_str('[%setvar foo bar baz %]', \%meta), 
        '', 
        'setvar returns empty string';

is parse_str('[%readvar foo%]', \%meta), 
        'bar baz',  
        'readvar returns previous value';  

is parse_str('[%setvar a <>&"a%][%readvar a escape:html%]', \%meta),
        '&lt;&gt;&amp;&quot;a',
        'HTML escape';

is parse_str('[%ifvar foo%]bar[%endifvar%]', \%meta), 
        'bar',  
        'ifvar works on defined variables';  

is parse_str('[%ifvar undef%]bar[%readvar argl %][%endifvar%]', \%meta), 
        '',  
        'ifvar works on undefined variables';  

%meta = ( VARS => { foo => { bar =>  'baz' } } );

is parse_str('[% readvar foo.bar %]', \%meta),
        'baz',
        'variable access to nested hashes';

$meta{NO_VAR_WARN} = 1;

is parse_str('[% readvar foo.bar.baz %]', \%meta),
        '',
        q{Don't die while accessing non-hash};


#eval {
#    parse_str('[% readvar foo bar %]');
#};
#
# TODO:
#ok $@, 'parse error on invalid input';
