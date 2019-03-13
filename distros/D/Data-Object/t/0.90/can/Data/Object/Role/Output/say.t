use 5.014;

use strict;
use warnings;

use Test::More;

# POD

=name

say

=usage

  my $say = $self->say();

=description

Output stringified object data with newline.

=signature

say() : DoNum

=type

method

=cut

# TESTING

use_ok 'Data::Object::Role::Output';

my $data = 'Data::Object::Role::Output';

can_ok $data, 'say';

ok 1 and done_testing;
