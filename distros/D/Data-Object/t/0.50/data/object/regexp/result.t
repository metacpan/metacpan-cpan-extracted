use strict;
use warnings;
use Test::More;

use_ok 'Data::Object::Regexp::Result';


can_ok 'Data::Object::Regexp::Result', 'captures';
can_ok 'Data::Object::Regexp::Result', 'count';
can_ok 'Data::Object::Regexp::Result', 'initial';
can_ok 'Data::Object::Regexp::Result', 'last_match_end';
can_ok 'Data::Object::Regexp::Result', 'last_match_start';
can_ok 'Data::Object::Regexp::Result', 'matched';
can_ok 'Data::Object::Regexp::Result', 'named_captures';
can_ok 'Data::Object::Regexp::Result', 'postmatched';
can_ok 'Data::Object::Regexp::Result', 'prematched';
can_ok 'Data::Object::Regexp::Result', 'regexp';
can_ok 'Data::Object::Regexp::Result', 'string';

ok 1 and done_testing;
