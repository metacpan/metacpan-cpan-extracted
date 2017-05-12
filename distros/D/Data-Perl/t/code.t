use Test::More;
use Data::Perl;
use strict;
use Scalar::Util qw/reftype/;
use Test::Fatal qw/dies_ok/;

# constructor
is ref(code(sub{})), 'Data::Perl::Code', 'constructor shortcut works';
is code->execute, undef, 'execute on blank sub returns correct undef';

my $b = code(sub { 2 });
is reftype($b), 'CODE', 'inner struct is coderef of ctr';

is $b->(), 2, 'coderef returns correct value';

is $b->execute, 2, 'execute returns correct value';

# tbd: execute_method

dies_ok {
  $b->execute_method;
} 'execute_method fails for now.';

done_testing();
