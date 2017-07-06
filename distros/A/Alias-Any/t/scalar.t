use warnings;
use strict;

use Test::More;

plan tests => 10;

use Alias::Any;

my $bar = 'bar';
my $foo = 'foo';
alias $foo = $bar;

is $foo, $bar => 'Same value';
is \$foo, \$bar => 'Same address';

$bar = 'new';
is $foo, 'new' => 'Same lvalue';

$foo = 'newer';
is $bar, 'newer' => 'Same reverse lvalue';

my $qux = 'qux';
alias my $baz = $qux;

is $baz, $qux, => 'Same value on defn';
is \$baz, \$qux, => 'Same address on defn';

$qux = 'new';
is $baz, 'new' => 'Same lvalue on defn';

$baz = 'newer';
is $qux, 'newer' => 'Same reverse lvalue on defn';


alias my $anon = 'anon';

is $anon, 'anon'  => 'Literal alias';
ok !defined eval{ $anon = 2 }  =>  'Constant alias';


done_testing();

