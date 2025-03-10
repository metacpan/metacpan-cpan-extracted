use strict;
use warnings;

use Data::Dumper;
use Text::CSV_XS;
use Test::More tests => 4;

use_ok('File::Process');

File::Process->import(qw{ pre next_line });

my $fh    = *DATA;
my $start = tell $fh;

my $csv = Text::CSV_XS->new;

my ($csv_lines) = process_file(
  $fh,
  csv         => $csv,
  chomp       => 1,
  has_headers => 1,
  pre         => sub {
    my ( $csv_fh, $args ) = @_;

    if ( $args->{'has_headers'} ) {
      my @column_names = $args->{'csv'}->getline($csv_fh);
      $args->{'csv'}->column_names(@column_names);
    }

    return ( pre( $fh, $args ) );
  },
  next_line => sub {
    my ( $csv_fh, $all_lines, $args ) = @_;
    my $ref = $args->{'csv'}->getline_hr($csv_fh);
    return $ref;
  }
);

ok( ref $csv_lines, 'pre, next-line' )
  or diag( Dumper [$csv_lines] );

isa_ok( $csv_lines,      'ARRAY' );
isa_ok( $csv_lines->[0], 'HASH' );

__DATA__
"id","first_name","last_name"
0,"Rob","Lauer"
