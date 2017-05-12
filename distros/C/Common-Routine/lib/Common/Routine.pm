package Common::Routine;
use Modern::Perl;
#use Carp;
use Exporter;
#use Data::Dumper;
use POSIX qw/ceil floor/;
use Number::Format qw/format_number/;
#use Math::Round;

our @ISA = ("Exporter");
our @EXPORT = ();
our @EXPORT_OK = qw/max min sum mean median var sd
                    trim ltrim rtrim ceil floor round format_number/;
our %EXPORT_TAGS = (
  math  => [qw/max min sum mean median var sd/],
  str   => [qw/trim ltrim rtrim/],
  num   => [qw/ceil floor round format_number/],
  all   => [qw/max min sum mean median var sd trim ltrim rtrim ceil floor round format_number/]
);

our $VERSION = '0.0.5'; # VERSION
# ABSTRACT: Provide and synthesize very commonly used routines that are not provided in perl's build-in routines.



sub round {
  return unless @_;
  my $decimal = @_ == 1 ? 0 : pop;
  return Number::Format::round($_[0], $decimal);
}


sub max {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  my $max = $elements[0];
  map { $max = $_ if ($max < $_) } @elements;
  return $max;
}


sub min {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  my $min = $elements[0];
  map { $min = $_ if ($_ < $min) } @elements;
  return $min;
}


sub sum {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  my $sum;
  $sum += $_ for @elements;
  return $sum;
}


sub mean {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  my $sum = &sum(@elements);
  return $sum / @elements;
}


sub median {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  @elements = sort { $a <=> $b } @elements;
  my $len = @elements;
  my $mid = int($len /2 );
  return $len % 2 ? $elements[$mid] : ($elements[$mid-1] + $elements[$mid]) / 2;
}


sub var {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  my $mean = &mean(@elements);
  my $sum = 0;
  $sum += ($_ - $mean) ** 2 for @elements;
  return  $sum / $#elements;
}


sub sd {
  return unless @_;
  my @elements = ref $_[0] ? @{$_[0]} : @_;
  return (&var(@elements)) ** 0.5;
}


sub trim {
  return unless @_;
  my $str = pop;
  $str =~s/^\s+|\s+$//g;
  return $str;
}


sub ltrim {
  return unless @_;
  my $str = pop;
  $str =~s/^\s+//g;
  return $str;
}


sub rtrim {
  return unless @_;
  my $str = pop;
  $str =~s/\s+$//g;
  return $str;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Common::Routine - Provide and synthesize very commonly used routines that are not provided in perl's build-in routines.

=head1 VERSION

version 0.0.5

=head1 SYNOPSIS

  use Common::Routine ":all";

  # routines used for math caculation
  my @array = 1..10;
  my $max = max @array          # return 10
  my $min = min @array          # return 1
  my $mean = mean @array        # return 5.5
  my $median = median @array    # return 5.5
  my $sum = sum @array          # return 55
  my $var = var @array          # return 9.166667
  my $sd = sd @array            # return 3.02765

  # routines for processing of string
  my $str = "  abc  ";
  my $t = trim $str;            # return "abc"
  my $l = ltrim $str;           # return "abc  "
  my $r = rtrim $str;           # return "  abc"

  # format number
  my $num = 1234.3567;
  my $re = round $num;          # return 1234
  my $re = round $num, 2;       # return 1234.36
  my $re = ceil $num;           # return 1235
  my $re = floor $num;          # return 1234
  my $re = format_number $num   # return 1,234.36
  my $re = format_number $num,1 # return 1,234.4

=head1 DESCRIPTION

The aim of this module is to provide the very common used functions that are not existed in perl's build-in functions

In my daily work, I will used some very common function that are very simple and useful, but I have to write it by
myself or find and utilize them from different module. It's really boring to do this, and the purpose of this module is
to combat this problem.

=head1 METHODS

=head2 round($number, $precison)

Rounds the number to the specified precision. if C<$precision> is omitted, it will be setted C<0> (default:0).

=head2 max(@elements)

Return the entry in the list with the highest numerical value. If the list is empty then C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 min(@elements)

Similar to L</max> but returns the entry in the list with the lowest numberical value. If the list is empty
then C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 sum(@elements)

Returns the numerical sum of all the elements in C<@elements>. If C<@elements> is empty then
C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 mean(@elements)

Returns the numerical mean of all the elements in C<@elements>. If C<@elements> is empty
then C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 median(@elements)

Returns the numerical mean of all the elements in C<@elements>. If C<@elements> is empty
then C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 var(@elements)

Returns the variance of list C<@elements>
If C<@elements> is empty then C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 sd(@elements)

Returns the standard deviation of list C<@elements>
If C<@elements> is empty then C<undef> is returned.
Arguments can be a Array or ArrayRef

=head2 trim($string)

Remove the whitespaces at the beginning or end of C<$string>
if $string is C<undef>, then C<undef> is returned

=head2 ltrim($string)

Remove the whitespaces at the beginning of C<$string>
if $string is C<undef>, then C<undef> is returned

=head2 rtrim($string)

Remove the whitespaces at the end of C<$string>
if $string is C<undef>, then C<undef> is returned

=head1 AUTHOR

Yan Xueqing <yanxueqing621@163.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Yan Xueqing.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
