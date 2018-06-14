use warnings;
use strict;

use Test::More;
plan tests => 6;

use Alias::Any;

my $original = 1;

alias my $var = $original;

is  $var,  $original => 'Values the same';
is \$var, \$original => 'Alias aliased';

alias my $const = 7;
ok !eval { $const = 2 } => 'An alias to a constant';


no Alias::Any;

{
    no warnings 'redefine';
    sub alias {};
}


alias my $unvar = $original;

is    $unvar,  $original => 'Values still the same';
isnt \$unvar, \$original => 'Alias did not alias';

alias my $inconst = 7;
ok eval { $inconst = 2 } => 'Not an alias to a constant';


done_testing();

