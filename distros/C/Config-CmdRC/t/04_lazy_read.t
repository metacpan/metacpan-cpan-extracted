use strict;
use warnings;
use Test::More;

use Config::CmdRC;

is scalar(keys %{RC()}), 0;

my $rc = Config::CmdRC->read('share/.foorc');

is $rc->{bar}, 'baz';
is $rc->{qux}, 123;

my $rc2 = Config::CmdRC->read('share/dir1/.akirc');

is $rc2->{aki}, 1;

done_testing;
