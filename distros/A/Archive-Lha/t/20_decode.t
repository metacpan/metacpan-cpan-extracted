use strict;
use warnings;
use Test::More qw( no_plan );
use Archive::Lha::Header;
use Archive::Lha::Decode;

test( hex_stream() );
foreach my $name (qw( lh5 lh7 lh0 )) {
  test( string_stream( $name ) );
  test( file_stream( $name ) );
}

test( file_stream('lh5_lvl1') );

sub test {
  my ($stream, $value) = @_;

  while ( defined ( my $level = $stream->search_header ) ) {
    my $header = Archive::Lha::Header->new(
      level  => $level,
      stream => $stream
    );
    $stream->seek( $header->data_top );

    my $pathname = $header->pathname;
    ok $pathname !~ m{\xff}, '\xff-free';

    my $decoded = '';
    my $decoder = Archive::Lha::Decode->new(
      header => $header,
      read   => sub { $stream->read(@_) },
      write  => sub { $decoded .= join '', @_ },
    );
    my $crc = $decoder->decode;
    if ( $header->crc16 ) {
      ok $crc == $header->crc16, "CRC: $crc / ".$header->crc16;
    }

    if ( defined $value ) {
      ok $decoded eq $value, "decoded content matches expected for " . $header->pathname;
    }
    else {
      ok $decoded, "decoded content non-empty for " . $header->pathname;
    }
  }
}

sub hex_stream {
  require Archive::Lha::Stream::Hex;
  Archive::Lha::Stream::Hex->new( hex => [qw(
    4D 00 2D 6C 68 35 2D 12 00 00 00 26 00 00 00 16
    01 60 47 20 02 81 41 4D 07 00 46 A4 03 00 00 0B
    00 01 74 65 73 74 2E 74 78 74 1B 00 41 5A 30 61
    38 D1 3B C8 01 1C 3D 00 6B D5 3C C8 01 5A 30 61
    38 D1 38 C8 01 06 00 00 C9 98 07 00 00 00 08 3B
    68 61 38 ED 7F 22 10 DB 4E 12 7C 09 71 F9 C0 00
  )]) => "testtesttesttesttesttesttesttesttest\r\n";
}

sub file_stream {
  my $name = shift;
  require Archive::Lha::Stream::File;
  Archive::Lha::Stream::File->new( file => "t/archive/$name.lzh" )
}

sub string_stream {
  my $name = shift;
  require File::Slurp;
  require Archive::Lha::Stream::String;
  Archive::Lha::Stream::String->new(
    string => scalar File::Slurp::read_file( "t/archive/$name.lzh", binmode => ':raw' )
  )
}
