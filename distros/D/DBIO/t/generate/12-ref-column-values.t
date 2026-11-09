use strict;
use warnings;
use Test::More;

use DBIO::Generate::Style::Vanilla;
use DBIO::Generate::Style::Candy;
use DBIO::Generate::Style::Cake;

# A column's size may be a [precision, scale] pair and its default_value a
# scalar ref (a literal SQL expression). The generated source must carry them
# as Perl source, so the compiled Result class holds exactly the value the
# introspect reported -- never the stringified ARRAY(0x..) / SCALAR(0x..).

sub spec_for {
  my ($class) = @_;
  return {
    moniker      => 'Price',
    class        => $class,
    table        => 'prices',
    column_order => [qw/id amount stamp label/],
    columns      => {
      id     => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
      amount => { data_type => 'numeric', size => [10, 2], is_nullable => 0,
                  default_value => \'0.00' },
      stamp  => { data_type => 'timestamp', is_nullable => 0,
                  default_value => \'CURRENT TIMESTAMP' },
      label  => { data_type => 'varchar', size => 50, is_nullable => 1,
                  default_value => 'none' },
    },
    pk                 => [qw/id/],
    uniq               => [],
    relationships      => [],
    extra_statements   => [],
    is_view            => 0,
    view_definition    => undef,
    result_base_class  => 'DBIO::Core',
    components         => [],
    additional_classes => [],
  };
}

for my $case (
  [ Vanilla => 'My::Gen::Vanilla::Price', 1 ],
  [ Candy   => 'My::Gen::Candy::Price',   0 ],
  [ Cake    => 'My::Gen::Cake::Price',    0 ],
) {
  my ($style, $class, $has_default) = @$case;
  my $style_class = "DBIO::Generate::Style::$style";
  my $code = $style_class->emit(spec_for($class));

  unlike($code, qr/(?:ARRAY|SCALAR)\(0x/, "$style: no stringified reference in source")
    or diag $code;

  eval $code; ## no critic (ProhibitStringyEval)
  is($@, '', "$style: emitted code compiles") or diag $code;

  my $amount = $class->column_info('amount');
  is_deeply $amount->{size}, [10, 2], "$style: size [p,s] round-trips";
  is $amount->{data_type}, 'numeric', "$style: data_type of a pair-sized column kept";
  is $class->column_info('label')->{size}, 50, "$style: integer size unchanged";

  if ($has_default) {
    is_deeply $amount->{default_value}, \'0.00',
      "$style: scalar-ref default_value round-trips";
    is_deeply $class->column_info('stamp')->{default_value}, \'CURRENT TIMESTAMP',
      "$style: CURRENT TIMESTAMP default round-trips as a scalar ref";
    is $class->column_info('label')->{default_value}, 'none',
      "$style: plain string default unchanged";
  }
}

done_testing;
