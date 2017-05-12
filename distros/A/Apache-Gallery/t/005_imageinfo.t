use Apache::Gallery;
use Test::More;

eval { require Apache::FakeRequest; };
if ($@) {
	plan skip_all => 'skip Apache::FakeRequest not found';
}
else {

	plan tests => 1;

	my $request = Apache::FakeRequest->new('get_remote_host' => 'localhost');

	my $info = Apache::Gallery::get_imageinfo($request, "t/005_jpg.jpg", "JPG", 15, 11);

	is ( $info->{Comment}, "Created with The GIMP", 'Comment');
}
