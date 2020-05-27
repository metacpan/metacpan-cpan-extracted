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
        not_regex: e
    field2:
        type: required
        length: 3,
        not_regex:
            - e
            - c
~;

my $validator = Data::Validate::WithYAML->new( \$config );

is $validator->check('field1','check'), 0;
is $validator->check('field1','test'), 0;
is $validator->check('field1','hallo'), 1;
is $validator->check('field1',''), 0;

is $validator->check('field2','check'), 0;
is $validator->check('field2','test'), 0;
is $validator->check('field2','hallo'), 1;
is $validator->check('field2','ha'), 0;
is $validator->check('field2','hal'), 1;
is $validator->check('field2','hel'), 0;
is $validator->check('field2',''), 0;

done_testing();
