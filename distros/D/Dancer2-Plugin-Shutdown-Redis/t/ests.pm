use strictures 2;

package t::ests;

use File::Temp qw(tempfile);
use File::Copy qw(copy);
use Test::Most;
use Plack::Test;
use HTTP::Request::Common;
use Exporter;
use Import::Into;
use Test::Mock::Redis;
use CBOR::XS qw(decode_cbor encode_cbor);

our @EXPORT = qw(tmpcopyfile init redis redis_hget redis_hset);

sub redis {
  Test::Mock::Redis->new(server => 'localhost');
}

sub redis_hget {
    my ($redis, $hash, $key) = @_;
    my $cbor = $redis->hget($hash, $key);
    return unless defined $cbor;
    return decode_cbor($cbor);
}

sub redis_hset {
    my ($redis, $hash, $key, $val) = @_;
    my $cbor = encode_cbor($val);
    $redis->hset($hash, $key, $cbor);
}

sub import {
  my $caller = scalar caller;
  for my $mod (qw(Test::Most Plack::Test HTTP::Request::Common)) {
    $mod->import::into($caller);
  }
  goto &Exporter::import;
}

sub tmpcopyfile {
  my $orig = shift;
  my ($fh, $copy) = tempfile;
  copy($orig, $fh) || die "cannot copy $orig to $copy: $!";
  close $fh;
  note("$orig mapped to $copy");
  return $copy;
}

sub init {
  Plack::Test->create( shift->to_app );
}

1;
