#file:t/apache/upload.t
#----------------------
use strict;
use warnings FATAL => 'all';

use Apache::Test;
use Apache::TestUtil;
use Apache::TestRequest 'UPLOAD';

plan tests => 5;

ok 1;    # simple load test

my $uri  = '/TestApache__Upload?progress_id=1234567890abcdef1234567890abcdef';
my $res = UPLOAD $uri, undef, content => ('1' x 40_000);
my $data = $res->content;

ok t_cmp( $data, qr/read 40000 characters from file/, "upload succeeded", );
ok t_cmp( $data, qr/file is ok/, "upload file intact", );
ok t_cmp( $data, qr/cache entry: \d+, \d+/, "cache contains valid entries", );
ok t_cmp( $data, qr/upload progress finished successfully/, "upload progress finished successfully", );

