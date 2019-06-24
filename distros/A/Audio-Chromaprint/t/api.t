use strict;
use warnings;
use Test::More;
use Path::Tiny qw( path );
use Audio::Chromaprint;

# this is a port of the tests/test_api.cpp test that comes with the
# chromaprint source to the Perl API.  The subtest names match the
# test names from that test.

subtest 'TestFp' => sub {

    my $cp = Audio::Chromaprint->new( algorithm => 2 );
    is $cp->get_num_channels, 1;
    is $cp->get_sample_rate, 11025;

    $cp->start(44100, 1);
    $cp->feed( path('t/data/test_stereo_44100.raw')->slurp_raw );
    $cp->finish;

    is $cp->get_fingerprint, 'AQAAC0kkZUqYREkUnFAXHk8uuMZl6EfO4zu-4ABKFGESWIIMEQE';
    is $cp->get_fingerprint_hash, '3732003127';

};

subtest 'Test2SilenceFp' => sub {

    my $cp = Audio::Chromaprint->new( algorithm => 2 );

    $cp->start(44100, 1);

    my $zeros = "\0" x 2048;

    for (1..130) {
        $cp->feed($zeros);
    }

    $cp->finish;

    is $cp->get_fingerprint, 'AQAAA0mUaEkSRZEGAA';
    is $cp->get_fingerprint_hash, '627964279';
};

subtest 'Test2SilenceRawFp' => sub {

    my $cp = Audio::Chromaprint->new( algorithm => 2 );

    $cp->start(44100, 1);

    my $zeros = "\0" x 2048;

    for (1..130) {
        $cp->feed($zeros);
    }

    $cp->finish;

    is_deeply $cp->get_raw_fingerprint, [
        627964279,
        627964279,
        627964279,
    ];
};

subtest 'TestEncodeFingerprint' => sub {
    plan skip_all => 'Interface missing from Perl API';
};

subtest 'TestEncodeFingerprintBase64' => sub {
    plan skip_all => 'Interface missing from Perl API';
};

subtest 'TestDecodeFingerprint' => sub {
    plan skip_all => 'Interface missing from Perl API';
};

subtest 'TestHashFingerprint' => sub {
    plan skip_all => 'Interface missing from Perl API';
};

subtest 'TestDecodeFingerprintOutOfRange' => sub {
    plan skip_all => 'Interface missing from Perl API';
};

done_testing;
