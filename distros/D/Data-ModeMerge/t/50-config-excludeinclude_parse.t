#!perl

use strict;
use warnings;
use Test::More tests => 19;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

mmerge_fail({}, {}, {exclude_parse=> 1}, "error exclude_parse 1");
mmerge_fail({}, {}, {exclude_parse=>{}}, "error exclude_parse 2");
mmerge_fail({}, {}, {exclude_parse_regex=>'('}, "error exclude_parse_regex");

mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_parse=>[]              }, {a=>3, b=>5}                           , "no exclude_parse");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_parse=>['a']           }, {a=>3, b=>5}                           , "exclude_parse 0");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_parse=>['+a']          }, {a=>1, '+a'=>2, b=>5}                  , "exclude_parse 1");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_parse=>['+a','-b']     }, {a=>1, '+a'=>2, b=>8, '-b'=>3}         , "exclude_parse 2");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_parse=>['+a','-b','+b']}, {a=>1, '+a'=>2, b=>1, '-b'=>3, '+b'=>7}, "exclude_parse 3");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {exclude_parse_regex=>'^.b$'    }, {a=>3, b=>1, '-b'=>3, '+b'=>7}         , "exclude_parse_regex 1");

mmerge_fail({}, {}, {include_parse=> 1}, "error include_parse 1");
mmerge_fail({}, {}, {include_parse=>{}}, "error include_parse 2");
mmerge_fail({}, {}, {include_parse_regex=>'('}, "error include_parse_regex");

mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse=>['+a','-b','+b']}, {a=>3, b=>5}                           , "include_parse 0");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse=>['-b','+b']     }, {a=>1, '+a'=>2, b=>5}                  , "include_parse 1");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse=>['+b']          }, {a=>1, '+a'=>2, b=>8, '-b'=>3}         , "include_parse 2");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse=>[]              }, {a=>1, '+a'=>2, b=>1, '-b'=>3, '+b'=>7}, "include_parse 3");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse_regex=>'^.a$'    }, {a=>3, b=>1, '-b'=>3, '+b'=>7}         , "include_parse_regex 1");

mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse=>['-b','+a'], exclude_parse=>['+a']              }, {a=>1, '+a'=>2, b=>-2, '+b'=>7}, "include_parse+exclude_parse");
mmerge_is({a=>1, b=>1}, {"+a"=>2, "-b"=>3, "+b"=>7}, {include_parse_regex=>'^(-b|\+a)$', exclude_parse_regex=>'^\+a$'}, {a=>1, '+a'=>2, b=>-2, '+b'=>7}, "include_parse_regex+exclude_parse");
