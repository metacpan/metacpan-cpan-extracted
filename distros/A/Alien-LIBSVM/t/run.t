#!/usr/bin/env perl

use Test::Most tests => 3;
use Path::Tiny;

use Alien::LIBSVM;
use Capture::Tiny qw(capture_merged);

# From <https://github.com/cjlin1/libsvm/blob/master/heart_scale>
my $heart_scale_data_head5 = <<EOF;
+1 1:0.708333 2:1 3:1 4:-0.320755 5:-0.105023 6:-1 7:1 8:-0.419847 9:-1 10:-0.225806 12:1 13:-1
-1 1:0.583333 2:-1 3:0.333333 4:-0.603774 5:1 6:-1 7:1 8:0.358779 9:-1 10:-0.483871 12:-1 13:1
+1 1:0.166667 2:1 3:-0.333333 4:-0.433962 5:-0.383562 6:-1 7:-1 8:0.0687023 9:-1 10:-0.903226 11:-1 12:-1 13:1
-1 1:0.458333 2:1 3:1 4:-0.358491 5:-0.374429 6:-1 7:-1 8:-0.480916 9:1 10:-0.935484 12:-0.333333 13:1
-1 1:0.875 2:-1 3:-0.333333 4:-0.509434 5:-0.347032 6:-1 7:1 8:-0.236641 9:1 10:-0.935484 11:-1 12:-0.333333 13:-1
EOF

subtest "Run svm-train" => sub {
	my $temp = Path::Tiny->tempfile;
	$temp->spew_utf8( $heart_scale_data_head5 );

	is system( Alien::LIBSVM->svm_train_path, $temp ), 0, 'svm-train runs';
};

subtest "Run svm-predict" => sub {
	like capture_merged { system( Alien::LIBSVM->svm_predict_path ) },
		qr/svm-predict/, 'svm-predict runs';
};

subtest "Run svm-scale" => sub {
	like capture_merged { system( Alien::LIBSVM->svm_scale_path ) },
		qr/svm-scale/, 'svm-scale runs';
};

done_testing;
