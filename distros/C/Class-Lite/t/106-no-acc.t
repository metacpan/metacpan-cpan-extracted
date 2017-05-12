use strict;
use warnings;
use Test::More;

my $eval_err    ;
my $have        ;
my $want        ;
my $check       ;

# Construction
eval {
    package Module::Empty;
    use Class::Lite;
};

{
    package Module::Empty::Bear;
    use parent 'Module::Empty';
}

$eval_err       = $@;

$check          = $eval_err ? $eval_err : 'use ok';
ok( ! $eval_err, $check );

$check          = 'new parent';
my $self        = Module::Empty->new;
$have           = ref $self;
$want           = 'Module::Empty';
is( $have, $want, $check );

$check          = 'parent isa Class::Lite';
$have           = $self->isa('Class::Lite');
ok( $have, $check );

$check          = 'parent isa bridge';
$have           = $self->isa('Class::Lite::Module::Empty');
ok( $have, $check );

$check          = 'new child';
my $woot        = Module::Empty::Bear->new;
$have           = ref $woot;
$want           = 'Module::Empty::Bear';
is( $have, $want, $check );

$check          = 'child isa Class::Lite';
$have           = $woot->isa('Class::Lite');
ok( $have, $check );

$check          = 'child isa bridge';
$have           = $woot->isa('Class::Lite::Module::Empty');
ok( $have, $check );

$check          = 'child isa parent';
$have           = $woot->isa('Module::Empty');
ok( $have, $check );



END {
    done_testing();
};
exit 0;

