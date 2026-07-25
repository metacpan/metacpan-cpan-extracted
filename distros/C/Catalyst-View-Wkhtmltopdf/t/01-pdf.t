use strict;
use warnings;

use Test::More;
use Test::Deep;

use FindBin qw/ $Bin /;

use File::Temp qw/ tempfile /;
use File::Which qw/ which /;
use HTTP::Request::Common;
use HTTP::Status qw/ :constants /;

use lib 't/lib';
use Catalyst::Test 'App';

unless (which "wkhtmltopdf") {
    plan skip_all => "wkhtmltopdf is required";
}

my ($res, $c) = ctx_request( GET '/' );

is $res->code, HTTP_OK, 'status code';

is $res->content_type, 'application/pdf', 'content_type';

ok my $data = $res->decoded_content, 'decoded_content';

cmp_deeply $c->log->msgs, [ { level => 'debug', message => ignore() } ], 'log messages from wkhtmlpdf';

note(explain $c->log->msgs);

# my ($fh, $name) = tempfile( 'test-XXXXXXXX', SUFFIX => '.pdf' );
# print {$fh} $data;
# close $fh;

# note $name;

done_testing;
