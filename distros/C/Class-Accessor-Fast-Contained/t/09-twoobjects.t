#!perl
use strict;
use Test::More tests => 3;

my $class = 'Class::Accessor::Fast::Contained';
require_ok($class);

my $silly = "Silly::$class";
{
    no strict 'refs';
    @{"${silly}::ISA"} = ($class);
    *{"${silly}::car"} = sub { shift->_car_accessor(@_); };
    *{"${silly}::mar"} = sub { return "Overloaded"; };
    $silly->mk_accessors(qw( foo bar yar car mar ));
    $silly->mk_ro_accessors(qw(static unchanged));
    $silly->mk_wo_accessors(qw(sekret double_sekret));
}
    
my $testa = $silly->new({
    static       => "variable",
    unchanged    => "dynamic",
});
    
my $testb = $silly->new({
    static       => "variable",
    unchanged    => "dynamic",
});

$testa->foo('pot');
$testb->foo('kettle');

is($testa->foo, 'pot',    "foo accessor wasn't overwritten");
is($testb->foo, 'kettle', "separate foo accessor also worked");
