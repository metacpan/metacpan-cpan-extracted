use strict;
use Test::More;

BEGIN {our $ovcfoo = 90}

use Class::Accessor::Inherited::XS {
    object_ro       => 'ofoo',
    getters         => 'gfoo',
    class_ro        => {'cfoo' => 32},
    varclass_ro     => 'vcfoo',
    inherited_ro    => 'ifoo',
};
use Class::Accessor::Inherited::XS {
    class_ro        => ['cfoo1'],
    varclass_ro     => ['vcfoo1', 'ovcfoo'],
};

sub exception (&) {
    $@ = undef;
    eval { shift->() };
    $@
}

my $o = bless {ofoo => 66, ifoo => 22, gfoo => 91};

sub check {
    my ($method, $value) = @_;

    is $o->$method, $value;
    like exception {$o->$method(67)}, qr/^Can't set/;
    is $o->$method, $value;
}

check('ofoo', 66);
check('gfoo', 91);
check('cfoo', 32);

check('ifoo', 22);
$o->{ifoo} = 17;
check('ifoo', 17);

check('vcfoo', undef);
our $vcfoo = 70;
check('vcfoo', 70);

check('cfoo1', undef);
check('vcfoo1', undef);
check('ovcfoo', 90);

done_testing;
