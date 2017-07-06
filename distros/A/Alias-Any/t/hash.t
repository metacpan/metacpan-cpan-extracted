use warnings;
use strict;

use Test::More;

plan tests => 11;

use Alias::Any;

my %foo = (a=>1,b=>2,c=>3);
my %bar;
alias %bar = %foo;

is_deeply \%foo, \%bar => 'Same values';
is \%foo, \%bar        => 'Same address';

%bar = (d=>4);
is_deeply \%foo, \%bar => 'Same assignment';

$bar{x} = 'new';
is_deeply \%foo, \%bar => 'Still same values';
is $foo{x}, 'new'      => 'Same lvalue';

my %qux = (1=>'a', 2=>'b', 3=>'c');
alias my %baz = %qux;
is_deeply \%baz, \%qux => 'Same values on defn';

$baz{2} = 'z';
is_deeply \%baz, \%qux => 'Still same values on defn';
is $baz{2}, 'z'        => 'Same lvalue on defn';

my $href = { a=>1, z=>26 };
alias my %etc = %$href;
is_deeply \%etc, $href => 'Same values on anon';
is \%etc, $href        => 'Same addr on anon';

$etc{b} = 0;
is $href->{b}, 0 => 'Same lvalue on anon';

done_testing();


