use Test::More tests => 3;
use strict;
use warnings;

BEGIN { use_ok('App::Mowyw', 'parse_str'); };

my $wild_text = 'some [% foo bar {{ tags with readvar keywords';

is parse_str('[%verbatim foo%]' . $wild_text . '[%endverbatim foo%]', {}),
    $wild_text,
    'verbatim suppresses parse errors, and returns the string';

# TODO: 
#is parse_str('[% verbatim for %]' . $wild_text . '[% endverbatim for %]', {}),
#    $wild_text,
#    'verbatim works with a keyword as marker';
#
eval {
    parse_str('[% verbatim foo %] bar baz');
};

ok $@, 'verbatim without end tag dies';
