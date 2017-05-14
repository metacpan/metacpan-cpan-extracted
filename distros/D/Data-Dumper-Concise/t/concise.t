use strict;
use warnings;
use Data::Dumper ();
use Data::Dumper::Concise;
use Test::More qw(no_plan);

my $dd = Data::Dumper->new([])
                     ->Terse(1)
                     ->Indent(1)
                     ->Useqq(1)
                     ->Deparse(1)
                     ->Quotekeys(0)
                     ->Sortkeys(1);
$dd->Trailingcomma(1) if $dd->can('Trailingcomma');

foreach my $to_dump (
  [ { foo => "bar\nbaz", quux => sub { "fleem" }  } ],
  [ 'one', 'two' ]
) {

  $dd->Values([ @$to_dump ]);

  my $example = do {
    local $Data::Dumper::Terse = 1;
    local $Data::Dumper::Indent = 1;
    local $Data::Dumper::Useqq = 1;
    local $Data::Dumper::Deparse = 1;
    local $Data::Dumper::Quotekeys = 0;
    local $Data::Dumper::Sortkeys = 1;
    no warnings 'once'; # in case Trailingcomma option is unknown in this DD
    local $Data::Dumper::Trailingcomma = 1;
    Data::Dumper::Dumper(@$to_dump);
  };

  is($example, $dd->Dump, 'Both Data::Dumper usages equivalent');

  is($example, Dumper(@$to_dump), 'Subroutine call usage equivalent');
}

my $out = DumperF { "arr: $_[0] str: $_[1]" } [qw(wut HALP)], "gnarl";

like($out, qr{^arr: \[\n  "wut",\n  "HALP",?\n\]\n str: "gnarl"\n\z}, 'DumperF works!');

like(Dumper([1..3]), qr/,\s*]\s*$/, 'trailing comma enabled')
    if $dd->can('Trailingcomma');
