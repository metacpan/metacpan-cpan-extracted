# Test insertion and selection of entries (-*- cperl -*-)

use lib './t';
use harness;
use DBO::Visitor::Check;
require 't/test-begin.pl';

my @good_tests =
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
  );

test {
  my $vis = DBO::Visitor::Check->new;
  my $n;
  foreach (@good_tests) {
    ++ $n;
    $vis->{record} = $_;
    $dbo->apply_to_table("${TABLE}1", $vis)
      or die "Check $n failed: " . $vis->{error}->format;
  }
};

my @bad_tests =
  (
   {
    id			=> 'foo', ERROR => 'NUMERIC',
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> '01234567890123456789', ERROR => 'LENGTH',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 AA:AA:AA', ERROR => 'TIME',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00:00', ERROR => 'LENGTH',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 'foo', ERROR => 'NUMERIC',
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 3.14159265, ERROR => 'INTEGER',
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 'foo', ERROR => 'NUMERIC',
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 1.414, ERROR => 'INTEGER',
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> -7, ERROR => 'UNSIGNED',
    col_option_unsigned	=> 0,
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 2, ERROR => 'OPTION',
    col_option_char	=> 'red',
   },
   {
    id			=> 0,
    col_char		=> 'foo',
    col_text		=> 'foo',
    col_time1		=> '1999-06-15 14:30:56',
    col_time2		=> '1999-06-15 00:00:00',
    col_integer		=> 0,
    col_unsigned	=> 0,
    col_option_unsigned	=> 0,
    col_option_char	=> 'foo', ERROR => 'OPTION',
   },
  );

test {
  local $DBO::DEBUG;		# don't warn about failed checks
  my $vis = DBO::Visitor::Check->new;
  my $n;
  foreach (@bad_tests) {
    ++ $n;
    $vis->{record} = $_;
    $dbo->apply_to_table("${TABLE}1", $vis)
      and die "Check $n succeeded!";
    $vis->{error}{exception} eq $_->{ERROR}
      or die "Expected error $_->{ERROR} but found error $vis->{error}{exception}";
  }
};

require 't/test-end.pl';
