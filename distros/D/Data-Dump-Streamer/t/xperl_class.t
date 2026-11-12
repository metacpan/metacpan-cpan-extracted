use 5.012;
use strict;
use warnings;
use utf8;
use Test::More;
use Scalar::Util         qw(refaddr isweak weaken);
use Data::Dump::Streamer qw(Dump :undump);

BEGIN {
    plan skip_all => 'XPerl class snapshot helpers are unavailable'
        unless builtin->can('class_object_to_hash')
        && builtin->can('class_object_from_hash')
        && builtin->can('is_class_object');
}

our $constructed= 0;
eval q{
    use feature 'class';
    no warnings 'experimental::class';
    class DDSClassNode {
        field $value :param;
        field @list;
        field %map;
        ADJUST { ++$main::constructed }
        method value { $value }
        method thaw { $value .= " thawed"; $self }
        method refs { \$value, \@list, \%map }
        method link($peer) { push @list, $peer; $map{peer} = $peer }
        method clear { @list = (); %map = () }
    }
    class DDSClassEmpty { method thaw { $self } }
    class DDSClassWıde {
        field $näme :param;
        method name { $näme }
    }
    class DDSClassParent {
        field $value :param(parent);
        method parent { $value }
    }
    role DDSClassRole {
        field $role :param;
        method role { $role }
    }
    class DDSClassChild :isa(DDSClassParent) :implements(DDSClassRole) {
        field $value :param(child);
        method child { $value }
    }
    1;
} or die $@;

sub roundtrip {
    my ($dumper, $input)= @_;
    my $text= $dumper->Names('value')->Data($input)->Out;
    my $value;
    my $copy= eval $text . '$value';
    is($@, '', 'class output evaluates') or diag $text;
    return ($copy, $text);
}

for my $payload (qw(scalar hash array)) {
    for my $indent (0, 2) {
        my $left=
              $payload eq 'scalar' ? DDSClassNode->new(value => 'left')
            : $payload eq 'hash'   ? bless({}, 'DDSClassNode')
            :                        bless([], 'DDSClassNode');
        $left->CONSTRUCT(value => 'left') unless $payload eq 'scalar';
        my $right= DDSClassNode->new(value => 'right');
        $left->link($right);
        $right->link($left);
        $left->{peer}= $right if $payload eq 'hash';
        push @$left, $right if $payload eq 'array';
        my ($scalar, $array, $hash)= $left->refs;
        my $holder= $left;
        my $input= [ $left, $left, $right, $scalar, $array, $hash, \$holder ];
        my $before= $constructed;
        my $d= Dump()->Indent($indent);
        my ($copy, $text)= roundtrip($d, $input);
        is($constructed, $before, 'reconstruction bypasses constructors');
        like(
            $text,
            qr/builtin::class_object_from_hash/,
            'output restores class storage'
        );
        is(ref($copy->[0]), 'DDSClassNode', 'class is preserved');
        ok(
            builtin::is_class_object($copy->[0]),
            'copy has native class storage'
        );
        is($copy->[0]->value, 'left', 'scalar field survives');
        is(
            refaddr($copy->[0]),
            refaddr($copy->[1]),
            'whole-object sharing survives'
        );
        my ($s, $a, $h)= $copy->[0]->refs;
        is(refaddr($s), refaddr($copy->[3]), 'scalar field alias survives');
        is(refaddr($a), refaddr($copy->[4]), 'array field alias survives');
        is(refaddr($h), refaddr($copy->[5]), 'hash field alias survives');
        is(
            refaddr($a->[0]),
            refaddr($copy->[2]),
            'array field shares another object'
        );
        is(
            refaddr($h->{peer}),
            refaddr($copy->[2]),
            'hash field shares another object'
        );
        my (undef, $back)= $copy->[2]->refs;
        is(
            refaddr($back->[0]),
            refaddr($copy->[0]),
            'cycle through fields survives'
        );
        is(
            refaddr(${ $copy->[6] }),
            refaddr($copy->[0]),
            'reference to object holder survives'
        );
        is(
            refaddr($copy->[0]{peer}),
            refaddr($copy->[2]),
            'hash payload shares field object'
        ) if $payload eq 'hash';
        is(
            refaddr($copy->[0][0]),
            refaddr($copy->[2]),
            'array payload shares field object'
        ) if $payload eq 'array';
        ${ $copy->[3] }= 'changed';
        is($copy->[0]->value, 'changed',
            'external scalar alias updates the field');
        is($left->value, 'left', 'source is unchanged');
        is($d->Out,      $text,  'repeated Out reconstructs the same graph');
        $_->clear for $left, $right, $copy->[0], $copy->[2];
    }
}

{
    my $object= DDSClassNode->new(value => 'aliased');
    my ($field)= $object->refs;
    my $d= Dump()->Names(qw(field first again))->Data($field, $object, $object);
    my ($first, $again);
    my $text= $d->Out;

    # Match the requested output name without aliasing a test variable.
    my $copy= eval 'my $field; ' . $text . '[$field, $first, $again]';
    is($@, '', 'field reference preceding the object evaluates') or diag $text;
    my ($installed)= $copy->[1]->refs;
    is(
        refaddr($installed),
        refaddr($copy->[0]),
        'earlier root aliases the installed scalar field'
    );
    is(
        refaddr($copy->[1]),
        refaddr($copy->[2]),
        'later object root preserves sharing'
    );
}

{
    my $child= DDSClassChild->new(
        parent => 'parent',
        child  => 'child',
        role   => 'role'
    );
    my ($copy)= roundtrip(Dump(), $child);
    is($copy->parent, 'parent', 'parent owner bucket survives');
    is($copy->child,  'child',  'shadowed child field survives');
    is($copy->role,   'role',   'role field survives');
    my ($empty)= roundtrip(Dump(), DDSClassEmpty->new);
    ok(
        builtin::is_class_object($empty),
        'fieldless class retains native storage'
    );
}

{
    my $object= DDSClassNode->new(value => "wide \x{100}");
    my $text= Dump()->Names('__DDS_class_fields_1')->Data($object)->Out;
    my $__DDS_class_fields_1;
    my $copy= eval $text . '$__DDS_class_fields_1';
    is($@, '', 'private snapshot name avoids a requested root name')
        or diag $text;
    is($copy->value, "wide \x{100}", 'Unicode field value round-trips');
    ok(utf8::is_utf8($copy->value), 'Unicode field flag survives');
    for my $declare (0, 1) {
        my $terse= Dump()->Terse(1)->Declare($declare)->Data($object)->Out;
        my $terse_copy= eval $terse;
        is($@, '', 'Terse class expression evaluates') or diag $terse;
        is($terse_copy->value, $object->value,
            'Terse returns the reconstructed object');
    }
}

{
    my $object= DDSClassNode->new(value => 'freezer');
    my ($copy, $text)= roundtrip(
        Dump()->Freezer('DDSClassNode', sub { return { replacement => 1 } }),
        $object);
    is_deeply(
        $copy,
        { replacement => 1 },
        'explicit freezer takes precedence over native storage'
    );
    unlike($text, qr/class_object_from_hash/,
        'replaced class does not emit native storage');
}

{
    my $object= DDSClassNode->new(value => 'method');
    my ($copy)= roundtrip(
        Dump()->Freezer('DDSClassNode', sub { return ($_[0], '->thaw') }),
        $object);
    is(
        $copy->value,
        'method thawed',
        'method thaw runs after class storage is attached'
    );
    is($object->value, 'method', 'thaw does not modify the source');
}

{
    my $object= DDSClassNode->new(value => 'weak');
    my ($scalar, $array)= $object->refs;
    $object->link($object);
    weaken($array->[0]);
    my ($copy)= roundtrip(Dump(), $object);
    my (undef, $copy_array)= $copy->refs;
    ok(isweak($copy_array->[0]), 'weak field backedge stays weak');
    is(refaddr($copy_array->[0]),
        refaddr($copy), 'weak field targets the reconstructed object');
    $copy->clear;
    $object->clear;
    Internals::SvREADONLY($$scalar, 1);
    my ($readonly)= roundtrip(Dump(), $object);
    my ($readonly_scalar)= $readonly->refs;
    ok(
        Internals::SvREADONLY($$readonly_scalar),
        'readonly scalar field survives'
    );
    ok(Internals::SvREADONLY($$scalar), 'source readonly field is unchanged');
}

{
    my $object= DDSClassNode->new(value => 'reuse');
    my $fail= 1;
    {

        package DDSClassPrinter;
        sub print { die "class printer failed\n" if ${ $_[0] }; 1 }
    }
    my $d= Dump()->Names('value')->To(bless \$fail, 'DDSClassPrinter');
    eval { my $text= $d->Data($object)->Out };
    like(
        $@,
        qr/class printer failed/,
        'class output callback exceptions propagate'
    );
    $fail= 0;
    $d->To(undef);
    my $text= $d->Out;
    my $value;
    my $copy= eval $text . '$value';
    is($@, '', 'dumper is reusable after a class output exception')
        or diag $text;
    is($copy->value, 'reuse', 'retried output restores fields');
    $d->Data([1]);
    my $ordinary= $d->Out;
    unlike($ordinary, qr/class_object_from_hash/,
        'Data clears previous class snapshots');
}

{

    package DDSClassArrayProxy;
    sub thaw { $_[0] }

    package main;
    my $object= DDSClassNode->new(value => 'field thaw');
    my (undef, $array)= $object->refs;
    bless $array, 'DDSClassArrayProxy';
    @$array= (1);
    my $d= Dump()->Freezer(
        'DDSClassArrayProxy',
        sub {
            return (bless([1], 'DDSClassArrayProxy'), 'thaw');
        });
    my ($copy)= roundtrip($d, [ $object, $array ]);
    my (undef, $installed)= $copy->[0]->refs;
    is(
        refaddr($installed),
        refaddr($copy->[1]),
        'field waits for its prerequisite thaw and reference fixup'
    );
    is_deeply([@$installed], [1], 'thawed array field content survives');
}

{
    my $object= DDSClassNode->new(value => 'scope');
    for my $declare (0, 1) {
        my $text= Dump()->Declare($declare)->Names('value')->Data($object)->Out;
        my $prefix= q{my $__DDS_class_fields_1 = 'keep';};
        $prefix .= q{my $value;} unless $declare;
        my $copy= eval $prefix . $text . q{[$__DDS_class_fields_1, $value]};
        is($@, '',
            'snapshot helpers are scoped independently of surrounding eval lexicals'
        ) or diag $text;
        is($copy->[0], 'keep',
            'snapshot helper does not mask caller code after the dump');
        is($copy->[1]->value, 'scope',
            'declared root remains accessible after helper scope');
    }
}

{
    my $object= DDSClassWıde->new(näme => "wide \x{100}");
    my ($copy)= roundtrip(Dump(), $object);
    is(ref($copy),  ref($object),  'Unicode class name survives');
    is($copy->name, $object->name, 'Unicode field name and value survive');
}

{
    my $object= DDSClassNode->new(value => undef);
    my ($scalar)= $object->refs;
    $$scalar= $object;
    my ($copy)= roundtrip(Dump()->Declare(1), [ $object, $scalar ]);
    my ($field)= $copy->[0]->refs;
    is(
        refaddr($field),
        refaddr($copy->[1]),
        'reference-valued scalar field retains its alias'
    );
    is(
        refaddr($$field),
        refaddr($copy->[0]),
        'scalar field cycle retains object identity'
    );
    $$field= undef;
    $$scalar= undef;
}

for my $payload (qw(hash array)) {
    my $object= DDSClassNode->new(value => 'slot thaw');
    my ($field)= $object->refs;
    my $other=
        bless($payload eq 'hash' ? { k => undef } : [undef], 'DDSClassEmpty');
    $other->CONSTRUCT;
    if ($payload eq 'hash') { alias_hv(%$other, 'k', $$field) }
    else                    { alias_av(@$other, 0, $$field) }
    my $d= Dump()->Freezer(
        'DDSClassEmpty',
        sub {
            my $proxy= bless($payload eq 'hash' ? { k => undef } : [undef],
                'DDSClassEmpty');
            $proxy->CONSTRUCT;
            if ($payload eq 'hash') { alias_hv(%$proxy, 'k', $$field) }
            else                    { alias_av(@$proxy, 0, $$field) }
            return ($proxy, 'thaw');
        });
    my ($copy)= roundtrip($d, [ $object, $other ]);
    my ($installed)= $copy->[0]->refs;
    my $slot= $payload eq 'hash' ? \$copy->[1]{k} : \$copy->[1][0];
    is($$installed, 'slot thaw',
        "class hydration waits for $payload alias after another class thaw");
    is(refaddr($installed), refaddr($slot),
        'field shares the thawed class payload slot');
}

{
    my $text=
        Dump()->Names('value')->Data(DDSClassNode->new(value => 'direct'))->Out;
    my $value;
    my $copy= eval $text;
    is($@, '', 'simple class dump evaluates directly') or diag $text;
    is($copy->value, 'direct',
        'simple eval returns the reconstructed class object');
}

for my $aggregate (qw(hash array)) {
    for my $declare (0, 1) {
        my $object=
            bless($aggregate eq 'hash' ? { k => 1 } : [1], 'DDSClassNode');
        $object->CONSTRUCT(value => 'aggregate');
        my $text=
            Dump()->Declare($declare)->Names('*payload')->Data($object)->Out;
        my $sigil= $aggregate eq 'hash' ? '%' : '@';
        my $prefix= $declare            ? ''  : "my ${sigil}payload;";
        my $copy= eval $prefix . $text . "\\${sigil}payload";
        is($@, '', 'named aggregate class payload evaluates') or diag $text;
        is($copy->value, 'aggregate',
            'named aggregate receives its native storage');
        is($aggregate eq 'hash' ? $copy->{k} : $copy->[0],
            1, 'named aggregate preserves its payload');
    }
}

done_testing();
