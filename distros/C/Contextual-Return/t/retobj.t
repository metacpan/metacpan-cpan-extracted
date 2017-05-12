use Contextual::Return;

sub foo {
    return
        PUREBOOL  { $_ = RETOBJ; next handler; }
        BOOL      { 1 }
        DEFAULT   { 42 }
    ;
}

package Other;
use Test::More 'no_plan';

is do{ ::foo() ? 'true' : 'false' }, 'true'         => 'PURE BOOLEAN context';

is $_, 42                                           => 'Pure boolean assigned';

is ref $_, 'Contextual::Return::Value'              => 'RETOBJ is object';

my $x;
undef $_;
is do{ ($x = ::foo()) ? 'true' : 'false' }, 'true'  => 'BOOLEAN context';

ok !defined $_                                      => 'RETOBJ not assigned';
