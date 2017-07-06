use warnings;
use strict;

use Test::More;

plan tests => 11;

use Alias::Any;

my @foo = (1,2,3);
my @bar;
alias @bar = @foo;

is_deeply \@foo, \@bar => 'Same values';
is \@foo, \@bar        => 'Same address';

@bar = (3,6,9);
is_deeply \@foo, \@bar => 'Same assignment';

$bar[1] = 'new';
is_deeply \@foo, \@bar => 'Still same values';
is $foo[1], 'new'      => 'Same lvalue';

my @qux = ('a'..'c');
alias my @baz = @qux;
is_deeply \@baz, \@qux => 'Same values on defn';

$baz[2] = 'z';
is_deeply \@baz, \@qux => 'Still same values on defn';
is $baz[2], 'z'        => 'Same lvalue on defn';

my $aref = [1,2,3];
alias my @etc = @$aref;
is_deeply \@etc, $aref => 'Same values on anon';
is \@etc, $aref        => 'Same addr on anon';

$etc[0] = 0;
is $aref->[0], 0 => 'Same lvalue on anon';

done_testing();

