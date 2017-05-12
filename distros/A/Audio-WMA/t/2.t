#########################

use Test::More tests => 6;

BEGIN { use_ok('Audio::WMA') };

#########################

{
	my $wma = Audio::WMA->new('data/test2.wma');

	ok $wma;

	my $info = $wma->info();

	ok $info;

	ok($wma->info('sample_rate') == 44100);

	my $tags = $wma->tags();

	ok $tags;

	# This has an extended data object.
	is($wma->tags('author')->[1], ' John Doe');
}

__END__
