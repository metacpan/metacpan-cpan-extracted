use strict;
use warnings;

use Test::More;
use Data::Remember DBM => file => 't/test.db';

require 't/test-brain.pl';

unlink 't/test.db';
