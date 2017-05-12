use Test::More;

use strict;
use warnings;

use HTTP::Request::Common;
use JSON::XS qw(decode_json);

use lib qw(t/lib);

use Test::WWW::Mechanize::Catalyst 'MyApp';

my $mech = Test::WWW::Mechanize::Catalyst->new();
$mech->add_header( 'Content-type' => 'application/json' );

my $api = { url     => '/api/router',
            type    => 'remoting',
            actions => { JSON       => [ { name => 'exception', len => 0 }, { name => 'index', len => 0 }, ],
                         Calculator => [ { name => 'add',      len => 2 },
                                         { name => 'subtract', len => 0 },
                                         { name => 'sum',      len => 1 },
                                         { name => 'upload',   len => 0 },
                         ],
                         NestedController => [ { name => 'index', len => 0 }, ]
            } };

is_deeply( MyApp->controller('API')->api,
           $api, 'get api directly from controller' );

$mech->get_ok( '/api', undef, 'get api via a request' );
ok( my $json = decode_json( $mech->content ), 'valid json' );

is_deeply( $json, $api, 'expected api' );

my $lens    = 0;
my $content = $mech->content;
$lens++ while ( $content =~ /"len":(\d+)/g );
is( $lens, 7 );

$mech->get_ok( '/api?namespace=MyApp', undef, 'get api via a request' );
ok( $json = decode_json( $mech->content ), 'valid json' );

is_deeply( $json, { %$api, namespace => "MyApp" }, 'namespace is set on api' );

# $api = MyApp->controller('API')->api;
# use Data::Dumper; print Dumper $json;

done_testing;
