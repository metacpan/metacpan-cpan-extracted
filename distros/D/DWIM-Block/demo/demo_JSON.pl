#! /usr/bin/env perl

use 5.022;
use experimental 'signatures';

use DWIM::Block;

sub from_JSON ($JSON_data) {
    return eval DWIM { Please convert the following JSON object to a valid Perl hashref,
                        using => to separate keys and values.
                        Please return only the hashref, with no extra code or commentary.
                        Here is the JSON object to be converted:

                        $JSON_data
                     }
}

my $JSON_obj = q{
                    {
                        "name"   : "Leslie",
                        "staff"  : true,
                        "age"    : 33,
                        "skills" : [ "AI", "docs", "testing" ]
                    }
};


use
Data::Dump "ddx"; ddx from_JSON ($JSON_obj);
