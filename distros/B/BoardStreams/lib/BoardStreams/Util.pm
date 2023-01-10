package BoardStreams::Util;

use Mojo::Base -strict, -signatures, -async_await;

use Mojo::Promise;
use Mojo::IOLoop;
use Mojo::JSON qw/ true false from_json to_json /;
use Syntax::Keyword::Try;
use Text::Trim 'trim';
use Data::GUID::URLSafe;
use List::AllUtils 'any';
use Encode::Simple qw/ encode_utf8 decode_utf8 /;
use Carp 'croak';
use Scalar::Util 'refaddr';

use Exporter 'import';
our @EXPORT_OK = qw/
    make_one_line eqq belongs_to trim true false
    unique_id hashify next_tick_p sleep_p
    encode_json decode_json
/;
our %EXPORT_TAGS = (bool => [qw/ true false /]);

our $VERSION = "v0.0.30";

sub make_one_line :prototype(_) ($text) {
    return trim(
        $text =~ s/^\s+/ /mgr
    );
}

sub eqq ($x, $y) {
    defined $x or return !defined $y;
    defined $y or return !!0;
    ref $x eq ref $y or return !!0;
    return length(ref $x) ? refaddr($x) == refaddr($y) : $x eq $y;
}

sub belongs_to ($x, $array) {
    return any { eqq($_, $x) } @$array;
}

sub unique_id { Data::GUID->new->as_base64_urlsafe }

sub hashify ($hashes, $fields, $sub = undef) {
    my $ret = {};

    foreach my $hash (@$hashes) {
        my $cursor = \$ret;
        foreach my $field (@$fields) {
            my $value = $hash->{$field};
            $cursor = \($$cursor->{$value} //= {});
        }
        $$cursor = $sub ? do {
            local $_ = $hash;
            $sub->($hash);
        } : $hash;
    }

    return $ret;
}

sub next_tick_p {
    my $p = Mojo::Promise->new;

    Mojo::IOLoop->next_tick(sub {
        $p->resolve();
    });

    return $p;
}

sub sleep_p :prototype(_) ($duration) {
    my $p = Mojo::Promise->new;

    Mojo::IOLoop->timer($duration, sub {
        $p->resolve();
    });

    return $p;
}

sub encode_json :prototype(_) ($data) { encode_utf8 to_json $data }

sub decode_json :prototype(_) ($bytes) { from_json decode_utf8 $bytes }

1;
