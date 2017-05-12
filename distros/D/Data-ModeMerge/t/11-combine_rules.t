#!perl

use strict;
use warnings;
use Test::More tests => 36;

use lib './t';
do 'testlib.pm';

use Data::ModeMerge;

merge_is  ({"+a"=>2}, {"+a"=>7}, {"+a"=>9 }, 'add+add');
merge_fail({"+a"=>2}, {".a"=>7},             'add+concat');
merge_is  ({"+a"=>2}, {"!a"=>7}, {        }, 'add+delete');
merge_fail({"+a"=>2}, {"^a"=>7},             'add+keep');
merge_is  ({"+a"=>2}, {"*a"=>7}, { "a"=>7 }, 'add+normal');
merge_is  ({"+a"=>2}, {"-a"=>7}, {"+a"=>-5}, 'add+subtract');

merge_fail({".a"=>2}, {"+a"=>7},             'concat+add');
merge_is  ({".a"=>2}, {".a"=>7}, {".a"=>27}, 'concat+concat');
merge_is  ({".a"=>2}, {"!a"=>7}, {        }, 'concat+delete');
merge_fail({".a"=>2}, {"^a"=>7},             'concat+keep');
merge_is  ({".a"=>2}, {"*a"=>7}, { "a"=>7 }, 'concat+normal');
merge_fail({".a"=>2}, {"-a"=>7},             'concat+subtract');

merge_is  ({"!a"=>2}, {"+a"=>7}, {"+a"=>7 }, 'delete+add');
merge_is  ({"!a"=>2}, {".a"=>7}, {".a"=>7 }, 'delete+concat');
merge_is  ({"!a"=>2}, {"!a"=>7}, {        }, 'delete+delete');
merge_is  ({"!a"=>2}, {"^a"=>7}, {"^a"=>7 }, 'delete+keep');
merge_is  ({"!a"=>2}, {"*a"=>7}, { "a"=>7 }, 'delete+normal');
merge_is  ({"!a"=>2}, {"-a"=>7}, {"-a"=>7 }, 'delete+subtract');

merge_is  ({"^a"=>2}, {"+a"=>7}, {"^a"=>2 }, 'keep+add');
merge_is  ({"^a"=>2}, {".a"=>7}, {"^a"=>2 }, 'keep+concat');
merge_is  ({"^a"=>2}, {"!a"=>7}, {"^a"=>2 }, 'keep+delete');
merge_is  ({"^a"=>2}, {"^a"=>7}, {"^a"=>2 }, 'keep+keep');
merge_is  ({"^a"=>2}, {"*a"=>7}, {"^a"=>2 }, 'keep+normal');
merge_is  ({"^a"=>2}, {"-a"=>7}, {"^a"=>2 }, 'keep+subtract');

merge_is  ({"*a"=>2}, {"+a"=>7}, { "a"=>9 }, 'normal+add');
merge_is  ({"*a"=>2}, {".a"=>7}, { "a"=>27}, 'normal+concat');
merge_is  ({"*a"=>2}, {"!a"=>7}, {        }, 'normal+delete');
merge_is  ({"*a"=>2}, {"^a"=>7}, {"^a"=>7 }, 'normal+keep');
merge_is  ({"*a"=>2}, {"*a"=>7}, { "a"=>7 }, 'normal+normal');
merge_is  ({"*a"=>2}, {"-a"=>7}, { "a"=>-5}, 'normal+subtract');

merge_is  ({"-a"=>2}, {"+a"=>7}, {"-a"=>-5}, 'subtract+add');
merge_fail({"-a"=>2}, {".a"=>7},             'subtract+concat');
merge_is  ({"-a"=>2}, {"!a"=>7}, {        }, 'subtract+delete');
merge_fail({"-a"=>2}, {"^a"=>7},             'subtract+keep');
merge_is  ({"-a"=>2}, {"*a"=>7}, { "a"=>7 }, 'subtract+normal');
merge_is  ({"-a"=>2}, {"-a"=>7}, {"-a"=>9 }, 'subtract+subtract');
