use 5.018;
use strict;
use warnings;
use Test::More;
use B                    ();
use Scalar::Util         qw(refaddr weaken isweak);
use Data::Dump::Streamer qw(Dump :undump);

sub magic_flags {
    return B::svref_2object($_[0])->FLAGS &
        (B::SVs_GMG() | B::SVs_SMG() | B::SVs_RMG());
}

for my $readonly (0, 1) {
    for my $kind (qw(scalar array hash reference_slot)) {
        my $scalar= 42;
        my $rv= [3];
        my $target=
              $kind eq 'scalar' ? \$scalar
            : $kind eq 'array'  ? [ 1, 2 ]
            : $kind eq 'hash'   ? { x => 1 }
            :                     \$rv;
        if ($readonly) {
            if    ($kind eq 'array') { Internals::SvREADONLY(@$target, 1) }
            elsif ($kind eq 'hash')  { Internals::SvREADONLY(%$target, 1) }
            else                     { Internals::SvREADONLY($$target, 1) }
        }
        my $input= [ $target, $target ];
        my $label= "$kind readonly=$readonly";
        my $flags= magic_flags($target);
        my $ro_flag= B::svref_2object($target)->FLAGS & B::SVf_READONLY();
        my $count= B::svref_2object($target)->REFCNT;
        my $d= Dump()->Names('value')->Data($input);
        is(magic_flags($target), $flags, "$label: analysis adds no magic");
        is(B::svref_2object($target)->REFCNT,
            $count, "$label: analysis retains no catalogue referent");
        my $text= $d->Out;
        is(magic_flags($target), $flags, "$label: output adds no magic");
        is(B::svref_2object($target)->REFCNT,
            $count, "$label: output retains no catalogue referent");
        is(B::svref_2object($target)->FLAGS & B::SVf_READONLY(),
            $ro_flag, "$label: input read-only flag is unchanged");
        my $value;
        my $copy= eval $text . '$value';
        is($@, '', "$label: output evaluates");
        is(refaddr($copy->[0]), refaddr($copy->[1]),
            "$label: sharing survives");
        undef $d;
        is(magic_flags($target), $flags, "$label: destruction leaves no magic");
    }
}

{
    my $target= [1];
    my $weak= $target;
    weaken($weak);
    my $input= [ $target, $target ];
    my $flags= magic_flags($target);
    my $text= Dump($input)->Out;
    is(magic_flags($target), $flags, 'existing backref magic is preserved');
    ok(isweak($weak), 'existing weak reference remains weak');
    is(refaddr($weak), refaddr($target),
        'existing weak reference still targets its input');
    undef $input;
    undef $target;
    ok(!defined($weak),
        'catalogue does not keep the caller weak referent alive');
}

{

    package DDSCataloguePrinter;
    sub print { $_[0]{text} .= $_[1] }

    package main;
    my $input= [ [1], [2] ];
    push @$input, $input->[0], $input->[1];
    my $d= Dump()->Names('value')->Data($input);
    @$input= ();
    my $printer= bless {}, 'DDSCataloguePrinter';
    $d->To($printer)->Out;
    is(
        $printer->{text},
        "\$value = [];\n",
        'callback output does not visit removed catalogue addresses'
    );
    my $view= $d->_xs_catalogue;
    ok(ref($view) eq 'HASH', 'catalogue diagnostics use stored metadata only');
}

done_testing;
