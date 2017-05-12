#!perl

package Other::Package;
sub other_package
{
    return 'hooray!';
}

package main;
sub latency
{
    return 'high';
}

sub fib
{
    my $n = shift;
    return 1 if $n < 2;
    return $n * fib($n - 1);
}

{
  my $count = 0;

  sub unicounter
  {
    ++$count;
  }
}

sub make_counter
{
    my $count = shift;
    return sub
    {
        ++$count;
    }
}

die 'greetings, Carp::REPL';

