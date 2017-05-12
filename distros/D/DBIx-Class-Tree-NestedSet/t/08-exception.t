use strict;
use warnings;
use Test::More tests => 1;
use Test::Exception;

use FindBin;
use lib "$FindBin::Bin/../lib";
use lib "$FindBin::Bin/tlib";

use FailSchema;

throws_ok(sub {
    FailSchema->load_classes(qw/MissingCols/);
}, qr/required param/, 'missing params');
