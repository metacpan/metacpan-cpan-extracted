use strict;
use warnings;
use Test2::V0;
use App::JsonLogUtils qw(lines json_grep);

my $log = <<'EOS';
{"id": 1, "foo": "bar"}
{"id": 2, "foo": "baz"}
{"id": 3, "foo": "bat"}
{"id": 4, "foo": "BAR"}
EOS

subtest basics => sub{
  open my $fh, '<', \$log or die $!;
  my $grep = json_grep {foo => [qr/bar/]}, 0, lines $fh;
  my $entry = <$grep>;
  my ($obj, $line) = @$entry;
  is $obj, {id => 1, foo => 'bar'}, 'obj';
  is $line, '{"id": 1, "foo": "bar"}', 'line';
  is <$grep>, U, 'exhausted';
};

subtest inverse => sub{
  open my $fh, '<', \$log or die $!;
  my $grep = json_grep {foo => [qr/bar/]}, 1, lines $fh;

  my @expected = (
    [{id => 2, "foo" => "baz"}, '{"id": 2, "foo": "baz"}'],
    [{id => 3, "foo" => "bat"}, '{"id": 3, "foo": "bat"}'],
    [{id => 4, "foo" => "BAR"}, '{"id": 4, "foo": "BAR"}'],
  );

  foreach (@expected) {
    my $entry = <$grep>;
    my ($obj, $line) = @$entry;
    is $obj,  $_->[0], 'obj';
    is $line, $_->[1], 'line';
  }

  is <$grep>, U, 'exhausted';
};

done_testing;
