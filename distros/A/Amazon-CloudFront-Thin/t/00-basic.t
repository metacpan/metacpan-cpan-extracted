use strict;
use warnings;
use Test::More tests => 2;

use Amazon::CloudFront::Thin;
pass 'Amazon::CloudFront::Thin loaded successfully.';

can_ok 'Amazon::CloudFront::Thin', qw(
    new
    create_invalidation
    ua
);

