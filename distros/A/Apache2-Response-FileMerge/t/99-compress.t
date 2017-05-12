
use strict;
use warnings;

my $has_zlib;
BEGIN {
    eval{ require Compress::Zlib};
    $has_zlib = ! $@;
};

use Apache::Test;
use Apache::TestRequest;
use Apache::TestUtil;

plan tests => 2, \&need_lwp;
my $r = GET('/compress/compress.js');

ok( $r->code() == 200 );

skip ( 
    ! $has_zlib,
    ( $r->content_encoding() || '' ) eq 'gzip'
);
