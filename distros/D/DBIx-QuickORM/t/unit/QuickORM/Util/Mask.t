use Test2::V0 -target => 'DBIx::QuickORM::Util::Mask';
use ok $CLASS;
use DBIx::QuickORM::Util qw/mask unmask masked/;
use Data::Dumper;

BEGIN {
    package My::Base;
    package My::Package;

    use overload(
        fallback => 1,
        '""'   => sub { "I am a teapot!" },
        '0+'   => sub { 10 },
        'bool' => sub { !!0 },
    );

    push @My::Package::ISA => 'My::Base';

    sub new { my $class = shift; bless({@_}, $class) };

    sub import   { 'import' }
    sub unimport { 'unimport' }
    sub DESTROY  { 'DESTROY' }

    sub one { 1 }
    sub bob { "bob" }
    sub echo { [@_] }
}

my $it = My::Package->new(guts => 'GUTS!');
my $wr = mask($it);

ok(!masked($it), "Original is not masked");
ok(masked($wr), "masked");

for my $meth (qw/one bob echo/) {
    is($wr->$meth(1, 2, 3), $it->$meth(1, 2, 3), "Method '$meth' retuns the same thing on both the original and wrapped");
}

is($wr->{guts}, "GUTS!", "Can get hash key from masked item");

isa_ok($wr, [$CLASS, qw/My::Package My::Base/], "isa passes though");
can_ok($wr, [qw/one bob echo/], "can() delegates");

ok(!$wr->can('fake'), "can() returns false if there is no method");
my $bob = $wr->can('bob');
ref_ok($bob, 'CODE', "Got a coderef");
is($wr->bob, "bob", "coderef works on object");

ok($wr->isa('My::Package'), "Direct isa() test positive");
ok(!$wr->isa('My::Fake'), "Direct isa() test negative");

my $line;
like(
    dies { $line = __LINE__; $CLASS->foo },
    qr/Can't locate object method "foo" via package "$CLASS" at \Q${ \__FILE__ } line $line\E/,
    "Calling for a bad sub on class instead of blessed object has a sane error",
);

like(
    dies { $line = __LINE__; $wr->foo },
    qr/Can't locate object method "foo" via package "$CLASS" at \Q${ \__FILE__ } line $line\E/,
    "Calling for a bad sub on an instance has a sane error",
);

is("$wr", "I am a teapot!", "String overloading is passed on");
is(1 + $wr, 11, "Number overloading is passed on");
is(!!$wr, F(), "Bool overloading is passed on");

{
    local $Data::Dumper::Terse   = 1;
    local $Data::Dumper::Indent  = 0;

    is(
        Dumper($wr),
        q<bless( ['I am a teapot!',sub { "DUMMY" }], 'DBIx::QuickORM::Util::Mask' )>,
        "Does not dump the wrapped object, but gives us something useful"
    );
}

$wr = undef;

$line = __LINE__ + 1;
$wr = mask($it, weaken => 1);

is($wr->[1]->(), $it, "Can get 'it'");
is(unmask($wr), $it, "Can unwrap");
$it = undef;

my $line2;
like(
    dies { $line2 = __LINE__; $wr->bob },
    qr<Weakly wrapped object created at \Q${ \__FILE__ } line $line\E has gone away.*\Q${ \__FILE__ } line $line2\E>s,
    "Got exception when wrapped item went away"
);

done_testing;
