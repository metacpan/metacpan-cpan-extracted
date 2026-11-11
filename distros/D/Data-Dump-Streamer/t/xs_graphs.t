use 5.018;
use strict;
use warnings;
use Test::More;
use Scalar::Util         qw(refaddr isweak);
use Data::Dump::Streamer qw(Dump :undump);

# Canonicalize topology independently of DDS: assign BFS numbers to
# containers and scalar slots, including alias classes and weak flags.
sub topology {
    my ($root)= @_;
    my (%objects, %slots, @queue, @rows);
    $objects{ refaddr($root) }= 0;
    push @queue, $root;
    for (my $i= 0 ; $i < @queue ; $i++) {
        my $value= $queue[$i];
        my @keys= ref($value) eq 'ARRAY' ? (0 .. $#$value) : sort keys %$value;
        my @row= (ref($value));
        for my $key (@keys) {
            my $slot=
                ref($value) eq 'ARRAY' ? \$value->[$key] : \$value->{$key};
            my $address= refaddr($slot);
            $slots{$address}= scalar keys %slots unless exists $slots{$address};
            my @entry= ($key, $slots{$address}, isweak($$slot) ? 1 : 0);
            if (ref($$slot)) {
                my $target= refaddr($$slot);
                if (!exists $objects{$target}) {
                    $objects{$target}= scalar @queue;
                    push @queue, $$slot;
                }
                push @entry, 'ref', $objects{$target};
            }
            else { push @entry, 'scalar', $$slot }
            push @row, \@entry;
        }
        push @rows, \@row;
    }
    return \@rows;
}

srand 73179;
for my $case (1 .. 50) {
    my @nodes= map { $_ % 2 ? {} : [] } 0 .. 19;
    for my $node (@nodes) {
        for my $i (0 .. 4) {
            my $value= rand() < .8 ? $nodes[ int rand @nodes ] : "text$i";
            if (ref($node) eq 'ARRAY') {
                push @$node, $value;
                Scalar::Util::weaken($node->[-1]) if ref($value) && rand() < .2;
            }
            else {
                $node->{"key$i"}= $value;
                Scalar::Util::weaken($node->{"key$i"})
                    if ref($value) && rand() < .2;
            }
        }
        alias_av(@$node, 4, $node->[1]) if ref($node) eq 'ARRAY' && rand() < .5;
    }
    my $value;
    my $text= Dump(\@nodes)->Names('value')->Out;
    my $copy= eval $text . '$value';
    is($@, '', "mixed cyclic graph $case evaluates") or diag $text;
    is_deeply(topology($copy), topology(\@nodes),
        "mixed graph $case retains topology")
        if !$@;

    # All nodes remain rooted while their edges are removed.
    for my $set (\@nodes, $copy || []) {
        for my $node (@$set) {
            if   (ref($node) eq 'ARRAY') { @$node= () }
            else                         { %$node= () }
        }
    }
}

done_testing;
