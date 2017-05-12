#!/usr/bin/perl
use strict;
use warnings;

use Test::More  tests => 37;
use Data::BitStream::XS;


{
  my $stream = Data::BitStream::XS->new;
  die unless defined $stream;

  my $status;
  my $v;

  # Test basic operations that should succeed
  ok($stream->maxbits >= 32, "maxbits >= 32");

  $status = ($stream->writing) && ($stream->len == 0) && ($stream->pos == 0);
  ok($status, "newly opened stream");

  $stream->write(1,1);
  $stream->write(3,5);
  $status = $stream->writing && $stream->len == 4 && $stream->maxlen >= 4;
  ok($status, "simple write");

  $stream->write_close;
  $status = !$stream->writing && $stream->len == 4 && $stream->pos == 4;
  ok($status, "write close");

  $stream->rewind;
  $status = !$stream->writing && $stream->len == 4 && $stream->pos == 0;
  ok($status, "rewind");

  $v = $stream->read(4);
  is($v, 0xD, "read value correctly");
  $status = !$stream->writing && $stream->len == 4 && $stream->pos == 4;
  ok($status, "read status");

  $stream->rewind;
  $stream->write_open;
  $status = $stream->writing && $stream->len == 4;
  ok($status, "write open");

  $stream->put_unary(4);
  $status = $stream->writing && $stream->len == 9;
  ok($status, "write unary");

  $stream->rewind_for_read;
  $status = !$stream->writing && $stream->len == 9 && $stream->pos == 0;
  ok($status, "rewind for read");

  $v = $stream->readahead(2);
  is($v, 3, "readahead value");
  $status = !$stream->writing && $stream->len == 9 && $stream->pos == 0;
  ok($status, "readahead status");

  $v = $stream->read(2, 'readahead');
  is($v, 3, "read(readahead) value");
  $status = !$stream->writing && $stream->len == 9 && $stream->pos == 0;
  ok($status, "read(readahead) status");

  # Unary is 000..1
  $v = $stream->read(9);
  is($v, 0x1A1, "read value");
  $status = !$stream->writing && $stream->len == 9 && $stream->pos == 9;
  ok($status, "read status");

  $stream->rewind_for_read;
  $v = $stream->read_string(9);
  is($v, '110100001', "read_string value");

  $stream->erase_for_write;
  $status = $stream->writing && $stream->len == 0;
  ok($status, "erase for write");

  $stream->put_unary1(7);
  $status = $stream->writing && $stream->len == 8;
  ok($status, "write unary1");
  $stream->rewind_for_read;
  $status = !$stream->writing && $stream->len == 8 && $stream->pos == 0;
  ok($status, "rewind for read");
  # Unary1 is 111..0
  $v = $stream->get_unary1(-1);
  is($v, 7, "read value");
  $status = !$stream->writing && $stream->len == 8 && $stream->pos == 8;
  ok($status, "read status");

  $stream->erase_for_write;
  $status = $stream->writing && $stream->len == 0;
  ok($status, "erase for write");

  $stream->put_gamma(13);
  $status = $stream->writing && $stream->len == 7;
  ok($status, "put gamma 13");

  {
    my $str = $stream->to_string;
    is($str, '0001110', "to string returned '0001110'");
    $status = !$stream->writing && $stream->len == 7;
    ok($status, "to string status");
  }

  {
    my $vec = $stream->to_raw;
    # the '0001110' comes back as '0001110[0...]'
    #printf "veclen = %d (want 1)   vec = '%s' 0x%x (want 0x1C)\n",
    #       length($vec), unpack("b8", $vec), vec($vec,0,8);
    $status = (length($vec) >= 1) && (length($vec) <= 4)
              && (vec($vec,0,8) == 0x1C)
              && !$stream->writing && $stream->len == 7;
    ok($status, "to raw returned 0x0E");
  }

  $stream->from_string('000000011111010');
  $status = !$stream->writing && $stream->len == 15 && $stream->pos == 0;
  ok($status, "from string '000000011111010'");

  $stream->rewind_for_read;
  $v = $stream->get_gamma;
  is($v, 249, "read gamma returned 249");
  $status = !$stream->writing && $stream->len == 15 && $stream->pos == 15;
  ok($status, "read gamma status");

  {
    my $vec = '';
    vec($vec, 0, 8) = 0xC5;
    $stream->from_raw($vec, 8);
    $status = !$stream->writing && $stream->len == 8 && $stream->pos == 0;
    ok($status, "from raw 0xC5 (8)");

    $vec = $stream->to_raw;
    cmp_ok( length($vec), '>=', 1, "to raw length is at least 1" );
    cmp_ok( length($vec), '<=', 4, "to raw length is no more than 4");
    is( vec($vec,0,8), 0xC5, "to raw returned 0xC5 (8)" );
    $status = !$stream->writing && $stream->len == 8;
    ok($status, "to raw status");
  }

  {
    my $success = 1;
    $stream->erase_for_write;
    foreach my $n (0 .. 65) {
      $stream->put_unary( 2*$n+0 );
      $stream->put_gamma( 2*$n+1 );
    }
    $status = $stream->len == 5106;
    ok($stream->len == 5106, "put sequence of numbers using unary and gamma");
    $stream->rewind_for_read;
    foreach my $n (0 .. 65) {
      if ($stream->get_unary() != (2*$n+0)) { $success = 0; last; }
      if ($stream->get_gamma() != (2*$n+1)) { $success = 0; last; }
    }
    ok($success, "correctly read sequence");
  }
}
