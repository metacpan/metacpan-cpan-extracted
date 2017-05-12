use Test::More;

use App::Kit;

diag("Testing ctype() for App::Kit $App::Kit::VERSION");

my $app = App::Kit->new();

ok( !exists $app->{'ctype'} || !exists $app->{'ctype'}{'mimeobj'}, 'mimeobj not set before mimeobj called' );
isa_ok( $app->ctype->mimeobj, 'MIME::Types' );
ok( exists $app->{'ctype'} && exists $app->{'ctype'}{'mimeobj'}, 'mimeobj is set after mimeobj called' );
is( $app->ctype->mimeobj, $app->{'ctype'}{'mimeobj'}, 'mime obj cached' );

my $js_mime = $app->ctype->mimeobj->mimeTypeOf('js')->type();
is( $app->ctype->get_ctype_of_ext('js'),     $js_mime, 'get_ctype_of_ext() ext only' );
is( $app->ctype->get_ctype_of_ext('.js'),    $js_mime, 'get_ctype_of_ext() ext w/ dot' );
is( $app->ctype->get_ctype_of_ext('foo.js'), $js_mime, 'get_ctype_of_ext() ext in path' );

my @plain = $app->ctype->mimeobj->type("text/plain")->extensions();
is_deeply(
    [ scalar $app->ctype->get_ext_of_ctype("text/plain") ],
    [ $plain[0] ],
    'get_ctype_of_ext() returns first in scalar context'
);
is_deeply(
    [ $app->ctype->get_ext_of_ctype("text/plain") ],
    \@plain,
    'get_ctype_of_ext() returns all in array context'
);

done_testing;
