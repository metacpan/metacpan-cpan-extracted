use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

search

=usage

  # given qr((test))

  $re->search('this is a test');
  $re->search('this does not match', 'gi');

=description

The search method performs a regular expression match against the given string
This method will always return a L<Data::Object::Search> object which
can be used to introspect the result of the operation.

=signature

search(Str $arg1) : SearchObject

=type

method

=cut

# TESTING

use_ok 'Data::Object::Regexp';

my $data = Data::Object::Regexp->new(qr/test/);

my $retv = $data->search('test case');

isa_ok $retv, 'Data::Object::Search';

is_deeply $retv, [''.qr(test).'', 'test case', 1, [ '0' ], [ '4' ], {}, 'test case'];

ok 1 and done_testing;
