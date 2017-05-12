use Apache::Gallery;
use Test::More;

eval { require Test::MockObject; };
if ($@) {
	plan skip_all => 'skip because Test::MockObject not found';
}
else {

	plan tests => 4;

	my $r = Test::MockObject->new();

	$r->set_always('dir_config', '100x75');

	my ($width, $height) = Apache::Gallery::get_thumbnailsize($r, 640, 480);
	is ($width, 100, 'Width');
	is ($height, 75, 'Height');

	($width, $height) = Apache::Gallery::get_thumbnailsize($r, 480, 640);
	is ($width, 56, 'Height rotated');
	is ($height, 75, 'Width rotated');

}
