# -*- Mode: Python -*-

use warnings;

use Test::More 'no_plan';
use Acme::Pythonic debug => 0;

# ----------------------------------------------------------------------

sub foo:
    my $i = \
       7
    return $i

is foo, 7

# ----------------------------------------------------------------------

$n = 0
$n = $n + \    # this is a comments but it should not matter
   4 \     # check this one too
                        + 5 # now this ends the sum

is $n, 9

# ----------------------------------------------------------------------

sub mygrep (&@):
    my $code = shift
    my @result         # comment ending in a backslash \
    foreach @_:
        push @result, \
             $_ \      # comment here as well, we support this from 0.20
             if \
             &$code
    return @result

my @array = mygrep { $_ % 2 } 0..5
is_deeply \@array, [1, 3, 5]

# ----------------------------------------------------------------------

my $coderef = sub:   # do not be fooled by this , #, we're not joining
    my $n = \
       shift
    $n *= \
       3

is $coderef->(3), 9

# ----------------------------------------------------------------------

my $fib
$fib = sub:
    my $n = shift
    die if $n < 0
    $n < 2 ? \
       $n : \
       $fib->($n - 1) \
       + $fib->\
       ($n - 2)

is $fib->(5), 5

# ----------------------------------------------------------------------

my $a = [1,
         2,
     3,

   4,
         ]

is_deeply $a, [1,2,3,4]

# ----------------------------------------------------------------------

my %n = (foo =>
   "heh",
                       bar      =>
                "moo")

ok exists $n{bar}

# ----------------------------------------------------------------------

no warnings
$n = 0
if foo => 1,
         bar => 2,
         baz => 3:
    $n = 1

is $n, 1

# ----------------------------------------------------------------------

$n = 0
unless foo => 1,
         bar => 2,
           baz => 3:
    $n = 1

is $n, 0

# ----------------------------------------------------------------------

use warnings
$n = 0
for foo =>
         1,    # a comment
         bar => 2,         # another comment
# ok, check some mixed dummy content now

                  # with several indents and blank lines

         baz => 3:
    $n += 1

is $n, 6

# ----------------------------------------------------------------------

$n = 0
foreach foo =>
         1,    # a comment
         bar => 2,         # another comment
# ok, check some mixed dummy content now

                  # with several indents and blank lines

         baz => 3:
    $n += 1

is $n, 6
