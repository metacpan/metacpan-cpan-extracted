use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

compose

=usage

  # given sub { [@_] }

  $code = $code->compose($code, 1,2,3);
  $code->(4,5,6); # [[1,2,3,4,5,6]]

  # this can be confusing, here's what's really happening:
  my $listing = sub {[@_]}; # produces an arrayref of args
  $listing->($listing->(@args)); # produces a listing within a listing
  [[@args]] # the result

=description

The compose method creates a code reference which executes the first argument
(another code reference) using the result from executing the code as it's
argument, and returns a code reference which executes the created code reference
passing it the remaining arguments when executed. This method returns a
L<Data::Object::Code> object.

=signature

compose(CodeRef $arg1, Any $arg2) : CodeObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { [@_] });

$data = $data->compose($data,1,2,3);

is_deeply $data->(4,5,6), [[1,2,3,4,5,6]];

ok 1 and done_testing;
