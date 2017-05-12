use strict;
use warnings;
use Test::More;

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

# Construction
{
    package Module::Empty;
    use Class::Lite qw| attr1 attr2 attr3 |;
    sub get_attr3 { return 'FAIL' };
}

eval {
    package Module::Empty::Bear;
    use Class::Lite qw| attr1 attr2 attr3 |;
    use parent 'Module::Empty';
};

$eval_err       = $@;

$check          = $eval_err ? $eval_err : 'use ok';
ok( ! $eval_err, $check );

$check          = 'new';
my $self        = Module::Empty::Bear->new;
$have           = ref $self;
$want           = 'Module::Empty::Bear';
is( $have, $want, $check );

$check          = 'isa Class::Lite';
$have           = $self->isa('Class::Lite');
ok( $have, $check );

$check          = 'isa bridge';
$have           = $self->isa('Class::Lite::Module::Empty::Bear');
ok( $have, $check );

$check          = 'isa parent';
$have           = $self->isa('Module::Empty');
ok( $have, $check );

# Access
$check          = 'put_attr1';
$self->put_attr1('foo');
$have           = $self->{attr1};
$want           = 'foo';
is( $have, $want, $check );
$check          = 'get_attr1';
$have           = $self->get_attr1;
is( $have, $want, $check );

$check          = 'put_attr2';
$self->put_attr2(42.5);
$have           = $self->{attr2};
$want           = 42.5;
cmp_ok( $have, '==', $want, $check );
$check          = 'get_attr2';
$have           = $self->get_attr2;
cmp_ok( $have, '==', $want, $check );

$check          = 'put_attr3';
my $bazref      = [];
$self->put_attr3($bazref);
$have           = $self->{attr3};
$want           = $bazref;
is( $have, $want, $check );
$check          = 'get_attr3';
$have           = $self->get_attr3;
is( $have, $want, $check );



END {
    done_testing();
};
exit 0;

