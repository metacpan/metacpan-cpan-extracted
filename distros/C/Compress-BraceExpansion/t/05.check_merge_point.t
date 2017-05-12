#!/usr/bin/perl
use strict;
use warnings;
use Data::Dumper;

use Test::More qw(no_plan);
use Compress::BraceExpansion;

use lib "t";
use CompressBraceExpansionTestCases;

while ( my $test_case = CompressBraceExpansionTestCases::get_next_test_case() ) {

    is( Compress::BraceExpansion::_check_merge_point ( @{ $test_case->{'expanded'} } ),
        $test_case->{'merge_point'},
        $test_case->{'description'},
    );

}

is( Compress::BraceExpansion::_check_merge_point ( qw( abc xyc ) ),
    3,
    'abc xyc'
);

is( Compress::BraceExpansion::_check_merge_point ( qw( abc xyc ijc ) ),
    3,
    'abc xyc ijc'
);

is( Compress::BraceExpansion::_check_merge_point ( qw( abc xyc iyc ) ),
    3,
    'abc xyc iyc'
);

is( Compress::BraceExpansion::_check_merge_point ( qw( abc xyc ijc lmc ) ),
    3,
    'abc xyc ijc lmc'
);

is( Compress::BraceExpansion::_check_merge_point ( qw( abcd xyzd ) ),
    4,
    'abcd xyzd'
);

is( Compress::BraceExpansion::_check_merge_point ( qw( abcd xyzd ijkd ) ),
    4,
    'abcd xyzd ijkd'
);

is( Compress::BraceExpansion::_check_merge_point ( qw( abcd xyzd ijkd ) ),
    4,
    'abcd xyzd iyzd'
);

