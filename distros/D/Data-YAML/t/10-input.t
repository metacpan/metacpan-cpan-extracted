use strict;
use warnings;
use Test::More tests => 12;
use Data::Dumper;

use Data::YAML::Reader;

my $in = [
  "---",
  "bill-to:",
  "  address:",
  "    city: \"Royal Oak\"",
  "    lines: \"458 Walkman Dr.\\nSuite #292\\n\"",
  "    postal: 48046",
  "    state: MI",
  "  family: Dumars",
  "  given: Chris",
  "comments: \"Late afternoon is best. Backup contact is Nancy Billsmer \@ 338-4338\\n\"",
  "date: 2001-01-23",
  "invoice: 34843",
  "product:",
  "  -",
  "    description: Basketball",
  "    price: 450.00",
  "    quantity: 4",
  "    sku: BL394D",
  "  -",
  "    description: \"Super Hoop\"",
  "    price: 2392.00",
  "    quantity: 1",
  "    sku: BL4438H",
  "tax: 251.42",
  "total: 4443.52",
  "...",
];

my $out = {
  'bill-to' => {
    'given'   => 'Chris',
    'address' => {
      'city'   => 'Royal Oak',
      'postal' => '48046',
      'lines'  => "458 Walkman Dr.\nSuite #292\n",
      'state'  => 'MI'
    },
    'family' => 'Dumars'
  },
  'invoice' => '34843',
  'date'    => '2001-01-23',
  'tax'     => '251.42',
  'product' => [
    {
      'sku'         => 'BL394D',
      'quantity'    => '4',
      'price'       => '450.00',
      'description' => 'Basketball'
    },
    {
      'sku'         => 'BL4438H',
      'quantity'    => '1',
      'price'       => '2392.00',
      'description' => 'Super Hoop'
    }
  ],
  'comments' =>
   "Late afternoon is best. Backup contact is Nancy Billsmer @ 338-4338\n",
  'total' => '4443.52'
};

my @lines = @$in;
my $scalar = join( "\n", @lines ) . "\n";

my @source = (
  {
    name   => 'Array reference',
    source => $in,
  },
  {
    name   => 'Closure',
    source => sub { shift @lines },
  },
  {
    name   => 'Scalar',
    source => $scalar,
  },
  {
    name   => 'Scalar ref',
    source => \$scalar,
  },
);

for my $src ( @source ) {
  my $name = $src->{name};
  ok my $yaml = Data::YAML::Reader->new, "$name: Created";
  isa_ok $yaml, 'Data::YAML::Reader';

  my $got = eval { $yaml->read( $src->{source} ) };
  unless ( is_deeply $got, $out, "$name: Result matches" ) {
    local $Data::Dumper::Useqq = $Data::Dumper::Useqq = 1;
    diag( Data::Dumper->Dump( [$got], ['$got'] ) );
    diag( Data::Dumper->Dump( [$out], ['$expected'] ) );
  }
}
