use Test::More;
use Test::Exception;
use Image::Info qw(image_info image_type dim);
use FindBin;
use lib "$FindBin::Bin/lib";

use Catalyst::Test 'TestApp';

#
# sanity check -- controller there?
#
my $controller = TestApp->controller('Image');
is(ref($controller), 'TestApp::Controller::Image', 'Controller is OK');

#
# get a context object and test mime-types
#
my ($res, $c) = ctx_request('/image/thumbnail/catalyst_logo.png');
is( ref($c), 'TestApp', 'context is OK' );
is( $res->content_type, 'image/png', 'MIME type is image/png');
ok( $res->is_success, 'status is 200');

# another format
$res = request('/image/thumbnail/catalyst_logo.png.jpg');
is( $res->content_type, 'image/jpeg', 'converted MIME type is image/jpeg');
ok( $res->is_success, 'status is 200');

# unknown uri
$res = request('/image/nonsense/catalyst_logo.png');
ok( $res->code(404), 'status is 404');
$res = request('/image/thumbnail/rails_logo.png');
ok( $res->code(404), 'status is 404');

#
# fire some requests
#
my $content;
lives_ok { $content = get('/image/thumbnail/catalyst_logo.png'); }
         'thumbnail retrieval works';
ok(length($content) > 1000, 'thumbnail length is OK');
file_type_is('thumbnail/catalyst_logo.png', 'PNG');
file_dimension_is('thumbnail/catalyst_logo.png', 80,80);

undef $content;
lives_ok { $content = get('/image/original/catalyst_logo.png'); }
         'original retrieval works';
ok(length($content) > 10000, 'original length is OK');
file_type_is('original/catalyst_logo.png', 'PNG');
file_dimension_is('original/catalyst_logo.png', 171,244);

done_testing;


#################################################
#
# helper subs
#
sub file_type_is {
    my $name = shift;
    my $format = shift;

    my $image_type = image_type(\$content);
    ok(ref($image_type) eq 'HASH' &&
       exists($image_type->{file_type}) &&
       $image_type->{file_type} eq $format, "$name is '$format'");
}

sub file_dimension_is {
    my $name = shift;
    my $w = shift;
    my $h = shift;

    is_deeply([dim(image_info(\$content))], [$w, $h], "$name is $w x $h");
}
