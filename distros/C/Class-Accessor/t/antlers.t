#!perl
use strict;
use Test::More tests => 14;

package No::Silly::Hands;
use Class::Accessor;
::ok !defined &has, "I can haz has?";

package Silly::Hands;
use Class::Accessor "antlers";
::ok defined &has, "I iz in ur module";

has "foo";
has rwrw => ( is => "rw", isa => "Int" );
has roro => ( is => "ro", isa => "Str" );
has wowo => ( is => "wo", isa => "Str" );

package main;
for my $f (qw/foo roro wowo rwrw/) {
    ok +Silly::Hands->can($f), "'$f' method exists";
}

my $test = Silly::Hands->new({
    foo => "bar",
    roro => "boat",
    rwrw => "huh",
    wowo => "whoa",
});

is($test->foo, "bar", "initial foo");
$test->foo("stuff");
is($test->foo, "stuff", "new foo");
is($test->{foo}, "stuff", "new foo in hash");

is($test->roro, 'boat', 'ro accessor');
eval { $test->roro('stuff'); };
like(scalar $@,
    qr/cannot alter the value of 'roro' on objects of class 'Silly::Hands'/,
    'ro accessor write protection');

$test->wowo(1001001);
is( $test->{wowo}, 1001001, 'wo accessor');
eval { () = $test->wowo; };
like(scalar $@,
    qr/cannot access the value of 'wowo' on objects of class 'Silly::Hands'/,
    'wo accessor read protection' );

package Silly::Hands;
{
    my $eeek;
    local $SIG{__WARN__} = sub { $eeek = shift };
    has DESTROY => (is => "rw");
    ::like($eeek,
        qr/a data accessor named DESTROY/i,
        'mk DESTROY accessor warning');
};
