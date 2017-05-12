#!perl

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest qw(GET_BODY);

plan tests => 1;

ok GET_BODY "/TestApache__conf";
