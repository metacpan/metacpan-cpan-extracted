use strict;
use warnings;
use Test::More;
use Module::Empty;              # Truly empty module ships with Class::Lite

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

# Construction
{
    package Module::Empty;
    use Class::Lite qw| attr1 attr2 attr3 |;
}
{
    package Tot;
    use Class::Lite qw| attr3 attr4 attr5 |;
    use Module::Empty;
}

$check          = 'new Tot';
my $self        = Tot->new;
$have           = ref $self;
$want           = 'Tot';
is( $have, $want, $check );

$check          = 'isa Class::Lite';
$have           = $self->isa('Class::Lite');
ok( $have, $check );

$check          = 'isa parent';
$have           = $self->isa('Module::Empty');
ok( $have, $check );

$check          = 'isa bridge';
$have           = $self->isa('Class::Lite::Module::Empty');
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

$check          = 'put_attr4';
$self->put_attr4('mork');
$have           = $self->{attr4};
$want           = 'mork';
is( $have, $want, $check );
$check          = 'get_attr4';
$have           = $self->get_attr4;
is( $have, $want, $check );

$check          = 'put_attr5';
$self->put_attr5('mindy');
$have           = $self->{attr5};
$want           = 'mindy';
is( $have, $want, $check );
$check          = 'get_attr5';
$have           = $self->get_attr5;
is( $have, $want, $check );



END {
    done_testing();
};
exit 0;

