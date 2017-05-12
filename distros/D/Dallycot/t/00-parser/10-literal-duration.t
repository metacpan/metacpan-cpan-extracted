use lib 't/lib';

use Test::More;
use ParserHelper;

test_simple_parses(
  'P1Y' => durationLit(years => 1),
  'P1YT1H' => durationLit(years => 1, hours => 1),
  'PT1S' => durationLit(seconds => 1),
  'P15M' => durationLit(years => 1, months => 3)
);

done_testing();

sub test_simple_parses {
  my(%trees) = @_;

  my $parser = Dallycot::Parser->new;
  $Data::Dumper::Indent = 1;
  foreach my $expr (sort { length($a) <=> length($b) } keys %trees ) {

    my $parse = $parser->parse($expr)->[0];
    isa_ok $parse, 'Dallycot::Value::Duration';
    ok(!DateTime::Duration->compare($parse->value, $trees{$expr}->value)) or do {
    # is_deeply($parse, $trees{$expr}, "Parsing ($expr)") or do {
      print STDERR "($expr): ", Data::Dumper->Dump([$parse]);
      # if('ARRAY' eq ref $parse) {
      #   print STDERR "\n   " . join("; ", map { $_ -> to_string } @$parse). "\n";
      # }
      # elsif($parse) {
      #   print STDERR "\n   " . $parse->to_string . "\n";
      # }
      print STDERR "expected: ", Data::Dumper->Dump([$trees{$expr}]);
    };
  }
}
