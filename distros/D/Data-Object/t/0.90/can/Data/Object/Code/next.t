use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

next

=usage

  $code->next;

=description

The next method is an alias to the call method. The naming is especially useful
(i.e. helps with readability) when used with closure-based iterators. This
method returns a L<Data::Object::Code> object. This method is an alias to the
call method.

=signature

next(Any $arg1) : Any

=type

method

=cut

# TESTING

use_ok 'Data::Object::Code';

my $data = Data::Object::Code->new(sub { [@_] });

is_deeply $data->next(1), [1];

ok 1 and done_testing;
