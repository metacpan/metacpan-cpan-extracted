use Contextual::Return;
use Test::More 'no_plan';

sub foo {
    my ($expected) = @_;
       if (VOID)   { is $expected, 'void'    => 'VOID test';        }
    elsif (LIST)   { is $expected, 'list'    => 'LIST test';        }
    elsif (SCALAR) { is $expected, 'scalar'  => 'SCALAR test';      }
    else           { ok 0                    => 'bizarre behaviour' }
}

my @foo = foo(  'list'  );
my $foo = foo( 'scalar' );
          foo(  'void'  );

sub bar {
    my ($expected) = @_;
       if (VOID)    { is $expected,   'void'    => 'VOID test';          }
    elsif (NONVOID) { isnt $expected, 'void'    => "NONVOID(\U$expected\E) test"; }
    else           { ok 0                    => 'bizarre behaviour' }
}

my @bar = bar(  'list'  );
my $bar = bar( 'scalar' );
          bar(  'void'  );
