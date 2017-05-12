use strict;
use warnings;
use Test::More;

#~ use Devel::Comments '###', ({ -file => 'debug.log' });                   #~

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

# Construction
eval {
    BEGIN {
        package Module::Empty;
        use Class::Lite qw| attr1 attr2 attr3 |;
    }
};
$eval_err       = $@;

$check          = $eval_err ? $eval_err : 'use ok';
ok( ! $eval_err, $check );

$check          = 'inherit import()';
{
    package Module::Empty::Bear;
    use Module::Empty qw| foo bar baz |;
}
pass( $check );

$check          = 'new in subclass';
my $self        = Module::Empty::Bear->new;

$check          = 'isa Class::Lite';
$have           = $self->isa('Class::Lite');
ok( $have, $check );

$check          = 'isa superclass';
$have           = $self->isa('Module::Empty');
ok( $have, $check );

$check          = 'isa bridge';
$have           = $self->isa('Class::Lite::Module::Empty::Bear');
ok( $have, $check );

# Access
$check          = 'put_foo';
$self->put_foo('meeple');
$have           = $self->{foo};
$want           = 'meeple';
is( $have, $want, $check );
$check          = 'get_foo';
$have           = $self->get_foo;
is( $have, $want, $check );



END {
    done_testing();
};
exit 0;

