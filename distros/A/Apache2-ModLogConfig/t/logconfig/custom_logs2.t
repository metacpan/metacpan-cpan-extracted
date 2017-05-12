#!perl

use strict;
use Apache::Test;

Apache::TestRequest::module('FRITZ');

use Apache::TestRequest 'GET_BODY_ASSERT';
print GET_BODY_ASSERT "/TestLogConfig__custom_logs?VHost";
