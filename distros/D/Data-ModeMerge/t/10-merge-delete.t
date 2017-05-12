#!perl

use strict;
use warnings;
use Test::More tests => 15;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

merge_is({"!a"=>undef}, {}, {}, 'left side only');
merge_is({}, {"!a"=>undef}, {}, 'right side only');

merge_is({a=>1}, {"!a"=>undef}, {}, 'scalar-scalar');
merge_is({a=>1}, {"!a"=>1    }, {}, 'scalar-scalar 2');
merge_is({a=>1}, {"!a"=>[]   }, {}, 'scalar-array');
merge_is({a=>1}, {"!a"=>{}   }, {}, 'scalar-hash');

merge_is({a=>[]}, {"!a"=>undef}, {}, 'array-scalar');
merge_is({a=>[]}, {"!a"=>1    }, {}, 'array-scalar 2');
merge_is({a=>[]}, {"!a"=>[]   }, {}, 'array-array');
merge_is({a=>[]}, {"!a"=>{}   }, {}, 'array-hash');

merge_is({a=>{}}, {"!a"=>undef}, {}, 'hash-scalar');
merge_is({a=>{}}, {"!a"=>1    }, {}, 'hash-scalar 2');
merge_is({a=>{}}, {"!a"=>[]   }, {}, 'hash-array');
merge_is({a=>{}}, {"!a"=>{}   }, {}, 'hash-hash 1');

merge_is({a=>{b=>1}}, {"a"=>{"!b"=>1}}, {a=>{}}, 'hash-hash 2');
