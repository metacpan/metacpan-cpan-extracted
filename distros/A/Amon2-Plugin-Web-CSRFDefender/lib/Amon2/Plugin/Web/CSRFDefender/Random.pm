package Amon2::Plugin::Web::CSRFDefender::Random;
use strict;
use warnings;
use utf8;
use 5.008_001;

# DO NOT USE THIS DIRECTLY.

use MIME::Base64 ();
use Crypt::SysRandom qw(random_bytes);

sub generate_session_id {
    my $buf = random_bytes(30);
    my $result = MIME::Base64::encode_base64($buf, '');
    $result =~ tr|+/=|\-_|d; # make it url safe
    return $result;
}

1;
