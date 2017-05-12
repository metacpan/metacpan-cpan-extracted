#!/usr/bin/env perl
# -*- Perl -*-
use warnings;
use Test::More;
use rlib '../lib';
use Test::More;
use Array::Columnize::columnize

note( "Testing when width is less than one of the items" );
my $data = ["what's", "upppppppppppppppppp"];
is(Array::Columnize::columnize($data,
                               {displaywidth => 7,
				arrange_vertical => 0}),
    "what's\nupppppppppppppppppp\n", 
    );

is(Array::Columnize::columnize($data,
                               {displaywidth => 7,
				ljust=>1,
				arrange_vertical => 1}),
    "what's\nupppppppppppppppppp\n", 
    );

is(Array::Columnize::columnize($data,
                               {displaywidth => 7,
				ljust=>0,
				arrange_vertical => 1}),
    "what's\nupppppppppppppppppp\n", 
    );


$data = ["whaaaaaat's", "up"];
is(Array::Columnize::columnize($data,
                               {displaywidth => 7,
				ljust=>0,
				arrange_vertical => 0}),
   "whaaaaaat's\n         up\n"
    );

$data = ["whaaaaaat's", "up"];
is(Array::Columnize::columnize($data,
                               {displaywidth => 7,
				ljust=>1,
				arrange_vertical => 0}),
   "whaaaaaat's\nup\n"
    );

$data = ["whaaaaaat's", "up"];
is(Array::Columnize::columnize($data,
                               {displaywidth => 7,
				ljust=>1,
				arrange_vertical => 1}),
   "whaaaaaat's\nup\n"
    );

done_testing();
