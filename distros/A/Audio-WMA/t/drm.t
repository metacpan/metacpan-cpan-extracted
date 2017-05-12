#########################

use Test::More tests => 6;

BEGIN { use_ok('Audio::WMA') };

#########################

{
	my $wma = Audio::WMA->new('data/test-drm.wma');

	ok($wma);

	my $info = $wma->info();

	ok $info;

	ok($wma->info('max_bitrate') == 160639);

	my $tags = $wma->tags();

	ok $tags;

	is($wma->tags('title'), 'Love Is Strange');
}

__END__
