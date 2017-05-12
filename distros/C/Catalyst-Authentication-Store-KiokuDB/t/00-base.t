use strict;
use warnings;
use Test::More tests => 2;

BEGIN {
    use_ok 'Catalyst::Authentication::User::KiokuDB';
    use_ok 'Catalyst::Authentication::Store::KiokuDB';
}
