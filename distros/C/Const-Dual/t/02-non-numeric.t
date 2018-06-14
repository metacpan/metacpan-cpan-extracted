#!perl -T
use 5.006;
use strict;
use warnings;
use Test::More tests => 22;

use Const::Dual ();

sub not_a_number($) {
    my $value = shift;
    my $warn = "";
    local $SIG{__WARN__} = sub { $warn .= $_[0] };
    $value = int $value;
    return $value == 0 && $warn =~ /Argument "[^"]+" isn't numeric in int/;
}

use_ok('Const::Dual', A1 => "string1", A2 => "string2");
ok(eval { A1() }, "constant A1 exists");
ok(eval { A2() }, "constant A2 exists");
ok(eval { not_a_number A1() }, "constant A1 num value");
ok(eval { not_a_number A2() }, "constant A2 num value");
is(eval { A1() }, "string1", "constant A1 value");
is(eval { A2() }, "string2", "constant A2 value");

my %hash;
use_ok('Const::Dual', \%hash, A3 => "string3", A4 => "string4");
ok(eval { A3() }, "constant A3 exists");
ok(eval { A4() }, "constant A4 exists");
ok(eval { not_a_number A3() }, "constant A3 num value");
ok(eval { not_a_number A4() }, "constant A4 num value");
is(eval { A3() }, "string3", "constant A3 str value");
is(eval { A4() }, "string4", "constant A4 str value");
is_deeply(\%hash, { "A3" => "string3", "A4" => "string4" }, "storehash");
ok(eval { not_a_number $hash{"A3"} }, "constant A3 num value");
ok(eval { not_a_number $hash{"A4"} }, "constant A4 num value");

use_ok('Const::Dual', A5 => { a => 5 }, A6 => [ a => 6 ]);
ok(eval { A5() }, "constant A5 exists");
ok(eval { A6() }, "constant A6 exists");
is_deeply(eval { A5() }, { a => 5 }, "constant A5 value");
is_deeply(eval { A6() }, [ a => 6 ], "constant A6 value");

