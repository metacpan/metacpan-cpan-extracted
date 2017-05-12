use Test::More tests => 8;
use File::Spec::Functions qw(:ALL);

BEGIN {
	use_ok('Audio::APE');
	use_ok('Audio::Musepack');
};

{
	my $ape  = Audio::APE->new(catdir('data', 'test.ape'));

	ok($ape);

	my $tags = $ape->tags;

	ok($tags);

	is($tags->{'ARTIST'}, 'Beach Boys');
}

{
	my $mpc  = Audio::Musepack->new(catdir('data', 'test.mpc'));

	ok($mpc);

	my $tags = $mpc->tags;

	ok($tags);

	is($tags->{'ARTIST'}, 'Massive Attack');
}
