#!/usr/bin/env perl
use Test::More;
use strict;
use Test::Output;
use warnings;
no strict 'refs';

use_ok('Crypt::MagicSignatures::Envelope');
use_ok('Crypt::MagicSignatures::Key');

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(
      data => 'hihi',
      data_type => 'haha',
      'fail'
    ), 'Wrong argument number');
  },
  qr/wrong number/i,
  'Wrong number of arguments'
);

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(
      data => 'hihi',
      data_type => 'haha',
      alg => 'dsa'
    ), 'algorithm not supported');
  },
  qr/algorithm is not supported/i,
  'DSA not supported'
);

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(
      data => 'hihi',
      data_type => 'haha',
      encoding => 'base64'
    ), 'encoding not supported');
  },
  qr/encoding is not supported/i,
  'Encoding not supported'
);


stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(
      alg => 'rsa-sha256',
      encoding => 'Base64URL'
    ), 'No payload');
  },
  qr/no data payload/i,
  'No data payload'
);

ok(my $empty = Crypt::MagicSignatures::Envelope->new, 'Create empty object');
is($empty->data, '', 'Empty data');

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new('           '), 'Create empty object');
  },
  qr/invalid envelope/i,
  'Invalid envelope data passed'
);

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new('kghjghjghj'), 'Create empty object');
  },
  qr/invalid envelope/i,
  'Invalid envelope data passed'
);

stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new('<kghjghjghj'), 'Create empty object');
  },
  qr/invalid envelope/i,
  'Invalid envelope data passed'
);

# Namespace is missing
stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(<<'MEXML'), 'Constructor (XML)');
  <?xml version="1.0" encoding="UTF-8"?>
  <me:env>
    <me:data type="text/plain">
      U29tZSBhcmJpdHJhcnkgc3RyaW5nLg==
    </me:data>
    <me:encoding>base64url</me:encoding>
    <me:alg>RSA-SHA256</me:alg>
    <me:sig key_id="my-01">
      S1VqYVlIWFpuRGVTX3l4S09CcWdjRVFDYVluZkI5Ulh4dmRFSnFhQW5XUmpB
      UEJqZUM0b0lReER4d0IwWGVQZDhzWHAxN3oybWhpTk1vNHViNGNVOVE9PQ==
    </me:sig>
  </me:env>
MEXML
  },
  qr/invalid envelope/i,
  'Invalid envelope data passed'
);


# Data is missing
stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(<<'MEXML'), 'Constructor (XML)');
  <?xml version="1.0" encoding="UTF-8"?>
  <me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
    <me:encoding>base64url</me:encoding>
    <me:alg>RSA-SHA256</me:alg>
    <me:sig key_id="my-01">
      S1VqYVlIWFpuRGVTX3l4S09CcWdjRVFDYVluZkI5Ulh4dmRFSnFhQW5XUmpB
      UEJqZUM0b0lReER4d0IwWGVQZDhzWHAxN3oybWhpTk1vNHViNGNVOVE9PQ==
    </me:sig>
  </me:env>
MEXML
  },
  qr/No data payload defined/i,
  'No data payload defined'
);

# Data is missing
stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(<<'MEXML'), 'Constructor (XML)');
  <?xml version="1.0" encoding="UTF-8"?>
  <me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
    <me:encoding>base64url</me:encoding>
    <me:data type="text/plain">
      ==========
    </me:data>
    <me:alg>RSA-SHA256</me:alg>
    <me:sig key_id="my-01">
      S1VqYVlIWFpuRGVTX3l4S09CcWdjRVFDYVluZkI5Ulh4dmRFSnFhQW5XUmpB
      UEJqZUM0b0lReER4d0IwWGVQZDhzWHAxN3oybWhpTk1vNHViNGNVOVE9PQ==
    </me:sig>
  </me:env>
MEXML
  },
  qr/No data payload defined/i,
  'No data payload defined'
);

# Invalid algorithm
stderr_like(
  sub {
    ok(!Crypt::MagicSignatures::Envelope->new(<<'MEXML'), 'Constructor (XML)');
  <?xml version="1.0" encoding="UTF-8"?>
  <me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
    <me:data type="text/plain">
      U29tZSBhcmJpdHJhcnkgc3RyaW5nLg==
    </me:data>
    <me:encoding>base64url</me:encoding>
    <me:alg>MD5</me:alg>
    <me:sig key_id="my-01">
      S1VqYVlIWFpuRGVTX3l4S09CcWdjRVFDYVluZkI5Ulh4dmRFSnFhQW5XUmpB
      UEJqZUM0b0lReER4d0IwWGVQZDhzWHAxN3oybWhpTk1vNHViNGNVOVE9PQ==
    </me:sig>
  </me:env>
MEXML
  },
  qr/Algorithm is not supported/i,
  'Algorithm is not supported'
);



done_testing;

__END__

ok($me = Crypt::MagicSignatures::Envelope->new(<<'MEXML'), 'Constructor (XML)');
  <?xml version="1.0" encoding="UTF-8"?>
  <me:env xmlns:me="http://salmon-protocol.org/ns/magic-env">
    <me:data type="text/plain">
      U29tZSBhcmJpdHJhcnkgc3RyaW5nLg==
    </me:data>
    <me:encoding>base64url</me:encoding>
    <me:alg>RSA-SHA256</me:alg>
    <me:sig key_id="my-01">
      S1VqYVlIWFpuRGVTX3l4S09CcWdjRVFDYVluZkI5Ulh4dmRFSnFhQW5XUmpB
      UEJqZUM0b0lReER4d0IwWGVQZDhzWHAxN3oybWhpTk1vNHViNGNVOVE9PQ==
    </me:sig>
  </me:env>
MEXML


done_testing;

1;
