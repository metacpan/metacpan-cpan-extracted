#!perl

use strict;
use Test::More;
use Data::Dumper;
use File::Basename;

my $dir;
BEGIN {
    $dir = dirname( __FILE__ );
}

use lib $dir;

BEGIN {
    use_ok( 'Data::Validate::WithYAML' );
}

my $config = q~---
step1:
    field1:
        type: required
        regex: e
    field2:
        type: required
        regex:
            - e
            - c
~;

my $validator = Data::Validate::WithYAML->new( \$config );

is $validator->check('field1','check'), 1;
is $validator->check('field1','test'), 1;
is $validator->check('field1','hallo'), 0;
is $validator->check('field1',''), 0;

is $validator->check('field2','check'), 1;
is $validator->check('field2','test'), 0;
is $validator->check('field2','hallo'), 0;
is $validator->check('field2',''), 0;

done_testing();
