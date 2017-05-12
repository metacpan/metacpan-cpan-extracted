#!perl

use strict; use warnings;
use Crypt::Affine;
use Test::More tests => 13;

eval { Crypt::Affine->new(); };
like($@, qr/Missing required arguments: m, r/);

eval { Crypt::Affine->new('r' => 1); };
like($@, qr/Missing required arguments: m/);

eval { Crypt::Affine->new('m' => 1); };
like($@, qr/Missing required arguments: r/);

eval { Crypt::Affine->new('r' => -1, 'm' => 1); };
like($@, qr/Positive number only/);

eval { Crypt::Affine->new('m' => -1, 'r' => 1); };
like($@, qr/Positive number only/);

eval { Crypt::Affine->new('m' => 1, 'r' => 1, 'reverse' => -1); };
like($@, qr/Only 0 or 1 allowed/);

eval { Crypt::Affine->new('m' => 1, 'r' => 1, 'source' => 'source.txt'); };
like($@, qr/Invalid file path/);

eval { Crypt::Affine->new({ 'r' => 1 }); };
like($@, qr/Missing required arguments: m/);

eval { Crypt::Affine->new({'m' => 1}); };
like($@, qr/Missing required arguments: r/);

eval { Crypt::Affine->new({ 'r' => -1, 'm' => 1 }); };
like($@, qr/Positive number only/);

eval { Crypt::Affine->new({ 'm' => -1, 'r' => 1 }); };
like($@, qr/Positive number only/);

eval { Crypt::Affine->new({ 'm' => 1, 'r' => 1, 'reverse' => -1 }); };
like($@, qr/Only 0 or 1 allowed/);

eval { Crypt::Affine->new({ 'm' => 1, 'r' => 1, 'source' => 'source.txt' }); };
like($@, qr/Invalid file path/);
