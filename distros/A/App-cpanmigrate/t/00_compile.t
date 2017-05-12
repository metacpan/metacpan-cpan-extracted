use strict;
use warnings;
use Test::More tests => 3;

BEGIN {
    use_ok 'App::cpanmigrate';
    use_ok 'App::cpanmigrate::bash';
    use_ok 'App::cpanmigrate::csh';
}
