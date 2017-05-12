# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use Test::Fatal;

my $mod = 'DBIx::TableLoader';
eval "require $mod" or die $@;
my $loader;
my $dbh;

## decided against doing it this way in the base module - rwstauner 2011-02-22
##{
##  { package DTL_GRR; @DTL_GRR::ISA = $mod; sub get_raw_row { } }
##  # test that subclasses store the right "get_row"
##  no strict 'refs';
##  my $args = [dbh => $dbh, data => [ [qw(a b)], [1, 2] ]];
##  ok(new_ok($mod, $args)->{get_row} == \&{"${mod}::get_raw_row"}, 'expected coderef');
##  ok(new_ok($mod, $args)->{get_row} == \&DTL_GRR::get_raw_row, 'expected coderef');
##}

{
  package # shh...
    DTL_Log;
  @DTL_Log::ISA = $mod;
  sub defaults {
    return {
      log_lines => undef,
    }
  }
  sub default_name { 'log lines' }
  sub get_raw_row {
    my ($self) = @_;
    [ (shift @{$self->{log_lines}} || return undef) =~ /^(\d+)\s+"([^"]+)"\s+(\S+)$/ ];
  }
  sub prepare_data { $_[0]->{prepared}++ }
  sub validate_row {
    my ($self, $row) = @_;
    # don't ever log the password
    $row->[1] =~ s/./X/g
      if $row->[2] eq 'PW';
    # something's wrong
    die $row->[1] . "\n"
      if $row->[2] eq 'FY';
    $row;
  }
}

is(eval { DTL_Log->new(arg_that_surely_does_not_exist => 1) }, undef, 'still dies with bad option');
$loader = new_ok('DTL_Log', [
  columns => [qw(ts info id)],
  log_lines => [
    qq[1234 "ahoy thare, matey" A1],
    qq[2345 "thar she blows!"   B2],
    qq[2445 "blast!"            FY],
    qq[3456 "yo ho ho"          C3],
    qq[3467 "password"          PW],
    qq[4567 "walk the plank!"   D4],
  ],
  name_prefix => 'me ',
  handle_invalid_row => 'die',
]
);

is($loader->{prepared}, 1, 'prepared once');
is($loader->name, "me log lines", 'override default table name');
is_deeply($loader->get_row, [1234, 'ahoy thare, matey', 'A1'], 'got row');
is_deeply($loader->get_row, [2345, 'thar she blows!',   'B2'], 'got row');
is(exception { $loader->get_row }, "blast!\n", 'validation failed');
is_deeply($loader->get_row, [3456, 'yo ho ho',          'C3'], 'got row');
is_deeply($loader->get_row, [3467, 'XXXXXXXX',          'PW'], 'got row mangled by validator');
is_deeply($loader->get_row, [4567, 'walk the plank!',   'D4'], 'got row');
is($loader->get_row, undef, 'no more rows');

done_testing;
