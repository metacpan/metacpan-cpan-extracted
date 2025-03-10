use strict;
use warnings;

use Test::More tests => 2;
use Data::Dumper;

use_ok('File::Process');

my $fh = *DATA;

my ( $lines, %args ) = process_file(
  $fh,
  chomp     => 1,
  keep_open => 1,
);

ok( @{$lines} == 6, 'read all lines' )
  or diag( Dumper [$lines] );

1;

__DATA__
# comment
line2
  line3 

line5
line6
