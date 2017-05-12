# Test insertion and selection of entries (-*- cperl -*-)

use lib './t';
use harness;
use Data::Dumper;
use DBO::Visitor::Check;
use DBO::Visitor::Insert;
use DBO::Visitor::Select;
require 't/test-begin.pl';

my @tests =
  (
   {
    id			=> 1,
    col_char		=> '012345678901234',
    col_text		=> 'foo' x 1000,
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> -100,
    col_unsigned	=> 65536,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 2,
    col_char		=> '012345678901234',
    col_text		=> q('"="'),
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> -1234,
    col_unsigned	=> 65536,
    col_option_unsigned	=> 1,
    col_option_char	=> 'white',
   },
   {
    id			=> 3,
    col_char		=> '',
    col_text		=> '',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'blue',
   },
  );

my %test_by_id;
@test_by_id{map $_->{id}, @tests} = @tests;

test {
  my $checker  = DBO::Visitor::Check->new;
  my $inserter = DBO::Visitor::Insert->new;
  foreach (@tests) {
    $checker->{record} = $_;
    $dbo->apply_to_table("${TABLE}1", $checker)
      or die "Check $_->{id} failed: " . $checker->{error}->format;
    $inserter->{record} = $_;
    $dbo->apply_to_table("${TABLE}1", $inserter);
  }
};

test {
  my $selecter = DBO::Visitor::Select->new;
  foreach my $test (@tests) {
    $selecter->{record} = { id => $test->{id} };
    my $records = $dbo->apply_to_table("${TABLE}1", $selecter);
    my $n = scalar @$records;
    die "$n found for test $test->{id} (expected 1)" unless $n == 1;
    foreach my $col (keys %$test) {
      my ($expected,$found) = ($test->{$col}, $records->[0]{$col});
      die "Test $test->{id}, column $col: expected $expected, found $found"
	unless $expected eq $found;
    }
  }
};

test {
  my $selecter = DBO::Visitor::Select->new;
  my $records = $dbo->apply_to_table("${TABLE}1", $selecter);
  my ($nexpected, $nfound) = (scalar @tests, scalar @$records);
  die "Selecting all: expected $nexpected, found $nfound"
    unless $nexpected == $nfound;
  foreach my $record (@$records) {
    my $test = $test_by_id{$record->{id}}
      or die "No test with id $record->{id}";
    foreach my $col (keys %$test) {
      my ($expected,$found) = ($test->{$col}, $record->{$col});
      die "Test $test->{id}, column $col: expected $expected, found $found"
	unless $expected eq $found;
    }
  }
};

require 't/test-end.pl';
