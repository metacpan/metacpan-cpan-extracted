use strict;
use warnings;

use Test::More tests => 3;

BEGIN {
    use_ok('CommonMark');
}

is(CommonMark->version, CommonMark->compile_time_version,
   'version matches compile_time_version');
is(CommonMark->version_string, CommonMark->compile_time_version_string,
   'version_string matches compile_time_version_string');

