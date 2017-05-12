
use strict;
use warnings;

use Test::More tests => 1;
use Test::Fatal;
use Data::Handle;

use lib 't/lib';
use Data;

my $output = "";

sub _diag {

  # diag(@_);
  $output .= $_ for @_;
}

is(
  exception {

    # Traditional Interface

    my $data = Data::Handle->new('Data');

    while (<$data>) {
      _diag($_);
    }

    seek $data, 0, 0;

    # IO::Handle - getline()

    while ( defined( my $foo = $data->getline() ) ) {
      _diag($foo);
    }

    $data->seek( 0, 0 );

    # IO::Handle - getlines()

    for ( $data->getlines() ) {
      _diag($_);
    }

    $data->seek( 0, 0 );

    # SLURPify

    {
      local $/ = undef;
      _diag( ">>slurp>>" . scalar <$data> . "<<slurp<<" );
    }

    # other tricks.

    seek $data, 0, 0;

    _diag('::getc style>');

    while ( !eof($data) ) {
      _diag( getc $data );
    }

    seek $data, 0, 0;

    my $buffer = '';

    read $data, $buffer, 10;

    read $data, $buffer, 5, -2;

    _diag($buffer);

    fileno $data;    # its undef :(

  },
  undef,
  'Example runs'
);

# diag( $output );
