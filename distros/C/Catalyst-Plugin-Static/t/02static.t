package main;

use Test::More tests => 10;
use lib 't/lib';
use Catalyst::Test 'TestApp';

use File::stat;
use File::Slurp;
use HTTP::Date;
use HTTP::Request::Common;

my $stat = stat($0);

{
    ok( my $response = request('/02static.t'),        'Request'                   );
    is( $response->code, 200,                       'OK status code'            );
    is( $response->content_length, $stat->size,     'Content length'            );
    is( $response->last_modified, $stat->mtime,     'Modified date'             );
    is( $response->content, read_file($0),          'Content'                   );
}

{

    my $request = GET( 'http://localhost/02static.t',
        'If-Modified-Since' => time2str($stat->mtime)
    );

    ok( my $response = request($request),             'If Modified Since request' );
    use Data::Dumper;
    is( $response->code , 304,                        'Not Modified status code'  ) or warn Dumper($response);
    is( $response->content , '',                      'No content'                );
}

{
    ok( my $response = request('/non/existing/file'), 'Non existing uri request'  );
    is( $response->code , 404,                        'Not Found status code'     );
}
