#!perl

use 5.010001;
use strict;
use warnings;

use Test::Data::Sah::Format;
use Test::Exception;
use Test::More 0.98;
#use Test::Needs;

subtest sci2dec => sub {
    test_format(
        format => 'sci2dec',
        data   => ["1.23e-2", "-1.23e+1", "123", "foo", undef],
        fdata  => ["0.0123" , "-12.3"   , "123", "foo", undef],
    );
};

done_testing;
