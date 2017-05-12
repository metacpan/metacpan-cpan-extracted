use strict;
use Test::More;
use Class::Accessor::Inherited::XS inherited => [qw/a b/];

sub new { return bless {}, shift }
sub foo { 42 }

my $o = __PACKAGE__->new;
$o->{a} = 6;
$o->{b} = 12;

my @res = (6,12,12,12,6,12,6);
for (qw/a b b b a b a/) {
    is($o->$_, shift @res);
}

@res = (12,6,42,12,6,42,6);
for (qw/b a foo b a foo a/) {
    is($o->$_, shift @res);
}

@res = (42,12,42,6,12,42);
for (qw/foo b foo a b foo/) {
    is($o->$_, shift @res);
}

my $a_ref = $o->can('a');

@res = (6,12,6,12);
for ('a', 'b', $a_ref, 'b') {
    is($o->$_, shift @res);
}

__PACKAGE__->a(37);

@res = (undef,37,37,6);
for ('Jopa', __PACKAGE__, undef, $o) {
    is($_->$a_ref, shift @res);
}

@res = (6,42,6,12);
for ($a_ref, \&foo, $a_ref, 'b') {
    is($o->$_, shift @res);
}

@res = (37,37,6);
my $a_val = 'a';
for (__PACKAGE__, __PACKAGE__, \12, $o) {
    eval{ is($_->$a_val, shift @res) };
}

for (qw/a a a/) {
    is($o->$_(7), 7);
}

is(Class::Accessor::Inherited::XS::_unstolen_count, Class::Accessor::Inherited::XS::OPTIMIZED_OPMETHOD ? 7 : 3);

done_testing;
