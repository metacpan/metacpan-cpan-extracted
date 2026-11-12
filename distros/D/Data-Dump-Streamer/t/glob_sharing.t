use 5.012;
use strict;
use warnings;
use Test::More;
use Scalar::Util         qw(refaddr reftype);
use Symbol               ();
use Data::Dump::Streamer qw(Dump :undump);

{

    package DDSGlobSharingFreeze;

    sub DDS_freeze {
        return Scalar::Util::reftype($_[0]) eq 'HASH'
            ? { %{ $_[0] } }
            : [ @{ $_[0] } ];
    }
}

sub container {
    my ($kind)= @_;
    my $child= [23];
    return $kind eq 'HASH'
        ? { k => 17, left => $child, right => $child }
        : [ 17, $child, $child ];
}

sub check_shared {
    my ($label, $kind, $input, $original, $globs, $extract)= @_;
    my $text= Dump($input)->Names('root')->Out;

    # Clear named slots too, so a bad fixup cannot accidentally read the
    # original container that happened to remain in the package glob.
    for my $glob (@$globs) { *{$glob}= $kind eq 'HASH' ? {} : [] }
    my ($root, $copy, $error, @warnings);
    {
        local $SIG{__WARN__}= sub { push @warnings, @_ };
        $copy= eval $text . '$root';
        $error= $@;
    }
    is($error, '', "$label: output evaluates") or diag $text;
    is_deeply(\@warnings, [], "$label: reconstruction has no warnings")
        or diag $text;
    return if $error;
    my @values= $extract->($copy);
    my $first= $values[0];
    ok(defined($first) && reftype($first) eq $kind,
        "$label: slot is populated");
    return unless defined($first) && reftype($first) eq $kind;
    isnt(refaddr($first), refaddr($original),
        "$label: reconstructed container is independent");
    is_deeply(
        $kind eq 'HASH' ? {%$first}    : [@$first],
        $kind eq 'HASH' ? {%$original} : [@$original],
        "$label: contents survive"
    );

    for my $i (1 .. $#values) {
        is(refaddr($values[$i]),
            refaddr($first), "$label: occurrence $i shares the slot container");
    }
    my ($left, $right)=
        $kind eq 'HASH' ? @$first{qw(left right)} : @$first[ 1, 2 ];
    is(refaddr($left), refaddr($right), "$label: descendant sharing survives");
}

for my $anonymous (0, 1) {
    for my $kind (qw(HASH ARRAY)) {
        for my $reverse (0, 1) {
            for my $extra (0, 1, 2) {
                for my $frozen (0, 1) {
                    local *DDSGlobSharing::source;
                    my $glob=
                        $anonymous
                        ? Symbol::gensym()
                        : \*DDSGlobSharing::source;
                    my $shared= container($kind);
                    bless $shared, 'DDSGlobSharingFreeze' if $frozen;
                    *{$glob}= $shared;
                    my $ordinary= [ $shared, $shared ];
                    $ordinary= [$ordinary] for 1 .. $extra;
                    my $input=
                        $reverse ? [ $ordinary, $glob ] : [ $glob, $ordinary ];
                    check_shared(
                        "$kind anonymous=$anonymous reverse=$reverse extra=$extra frozen=$frozen",
                        $kind, $input, $shared,
                        [$glob],
                        sub {
                            my ($copy)= @_;
                            my $copy_glob= $copy->[ $reverse ? 1 : 0 ];
                            my $elements= $copy->[ $reverse  ? 0 : 1 ];
                            $elements= $elements->[0] for 1 .. $extra;
                            return (*{$copy_glob}{$kind}, @$elements);
                        });
                }
            }
        }
    }
}

# Equal-depth paths can arise in different deferred globs. Choosing the
# shortest path must not make the earlier-emitted glob construct a value
# under the other glob's name before that other slot has been assigned.
for my $anonymous (0, 1) {
    for my $kind (qw(HASH ARRAY)) {
        for my $reverse (0, 1) {
            local (*DDSGlobSharing::left, *DDSGlobSharing::right);
            my $left= $anonymous  ? Symbol::gensym() : \*DDSGlobSharing::left;
            my $right= $anonymous ? Symbol::gensym() : \*DDSGlobSharing::right;
            my $shared= container($kind);
            *{$left}= $kind eq 'HASH' ? { v => $shared } : [$shared];
            *{$right}= $shared;
            my $input= $reverse ? [ [$right], $left ] : [ $left, [$right] ];
            check_shared(
                "deferred tie $kind anonymous=$anonymous reverse=$reverse",
                $kind, $input, $shared,
                [ $left, $right ],
                sub {
                    my ($copy)= @_;
                    my $copy_left= *{ $copy->[ $reverse  ? 1 : 0 ] }{$kind};
                    my $copy_right= *{ $copy->[ $reverse ? 0 : 1 ][0] }{$kind};
                    return ($copy_right,
                        $kind eq 'HASH' ? $copy_left->{v} : $copy_left->[0]);
                });
        }
    }
}

for my $anonymous (0, 1) {
    for my $kind (qw(SCALAR CODE)) {
        for my $extra (0, 1, 2) {
            local *DDSGlobSharing::other;
            my $glob= $anonymous ? Symbol::gensym() : \*DDSGlobSharing::other;
            my $number= 42;
            my $shared= $kind eq 'SCALAR' ? \$number : sub { 42 };
            *{$glob}= $shared;
            my $ordinary= [ $shared, $shared ];
            $ordinary= [$ordinary] for 1 .. $extra;
            my $text= Dump([ $glob, $ordinary ])->Names('root')->Out;
            undef *{$glob};
            my ($root, $copy, $error, @warnings);
            {
                local $SIG{__WARN__}= sub { push @warnings, @_ };
                $copy= eval $text . '$root';
                $error= $@;
            }
            my $label= "$kind anonymous=$anonymous extra=$extra";
            is($error, '', "$label: output evaluates") or diag $text;
            is_deeply(\@warnings, [], "$label: reconstruction has no warnings");
            next if $error;
            my $slot= *{ $copy->[0] }{$kind};
            my $elements= $copy->[1];
            $elements= $elements->[0] for 1 .. $extra;
            is(
                refaddr($slot),
                refaddr($elements->[0]),
                "$label: slot and element share the value"
            );
            is(
                refaddr($slot),
                refaddr($elements->[1]),
                "$label: repeated element shares the value"
            );
            is($kind eq 'SCALAR' ? $$slot : $slot->(),
                42, "$label: reconstructed value works");
        }
    }
}

# The same scheduling must also preserve cycles through a shared slot.
for my $anonymous (0, 1) {
    for my $kind (qw(HASH ARRAY)) {
        local *DDSGlobSharing::cycle;
        my $glob= $anonymous ? Symbol::gensym() : \*DDSGlobSharing::cycle;
        my $shared= $kind eq 'HASH' ? {}        : [];
        if   ($kind eq 'HASH') { $shared->{self}= $shared }
        else                   { push @$shared, $shared }
        *{$glob}= $shared;
        my $text= Dump([ $glob, [ $shared, $shared ] ])->Names('root')->Out;
        *{$glob}= $kind eq 'HASH' ? {} : [];
        my ($root, $copy, $error, @warnings);
        {
            local $SIG{__WARN__}= sub { push @warnings, @_ };
            $copy= eval $text . '$root';
            $error= $@;
        }
        my $label= "cycle $kind anonymous=$anonymous";
        is($error, '', "$label: output evaluates") or diag $text;
        is_deeply(\@warnings, [], "$label: reconstruction has no warnings");
        if (!$error) {
            my $slot= *{ $copy->[0] }{$kind};
            is(
                refaddr($slot),
                refaddr($copy->[1][0]),
                "$label: slot and element share a container"
            );
            is(
                refaddr($slot),
                refaddr($copy->[1][1]),
                "$label: repeated element shares the container"
            );
            is(refaddr($kind eq 'HASH' ? $slot->{self} : $slot->[0]),
                refaddr($slot), "$label: self-cycle survives");
            if   ($kind eq 'HASH') { %$slot= () }
            else                   { @$slot= () }
        }
        if   ($kind eq 'HASH') { %$shared= () }
        else                   { @$shared= () }
    }
}

done_testing;
