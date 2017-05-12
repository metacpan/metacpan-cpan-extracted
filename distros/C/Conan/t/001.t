use lib 'lib';
use Test::More tests => 3;
use Conan::Deploy;

use_ok( 'Conan::Deploy' );

`mkdir -p /tmp/base/qa/ /tmp/base/prod`;

my $IMG = 'test_0.0001';

`mkdir -p /tmp/base/qa/$IMG/`;

open my $fd, ">/tmp/base/qa/$IMG/foo" || die $@;

print $fd "Foo\n" and close $fd;

open $fd, ">/tmp/base/qa/$IMG/bar" || die $@;

print $fd "Bar\n" and close $fd;

my $deploy = Conan::Deploy->new(
	srcimagebase => '/tmp/base/qa',
	targetimagebase => '/tmp/base/prod',
);

ok( $deploy => 'Conan::Deploy instance created' );

ok( $deploy->promote_image( $IMG ) => "Image $IMG promoted to prod" );

`rm -rf /tmp/base`;

__END__

my $deploy = Conan::Deploy->new(
	#srcimagebase => '/tmp/base/qa',
	#targetimagebase => '/tmp/base/prod',
);

$deploy->promote_image('test_0.0001');
