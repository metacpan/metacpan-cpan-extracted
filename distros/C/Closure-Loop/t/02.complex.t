use Test::More tests => 3;

package Iter;
use Closure::Loop;

sub new {
    my $class = shift;
    return bless { }, $class;
}

sub counter {
    my $self = shift;
    my $cb   = pop || die "No callback";
    
    my $i = 0;

    for (;;) {
        $i++;
        eval {
            $self->yield($cb, $i);
        };
        last if $self->is_last;
        die $@ if $@;
    }
}

sub walk_tree {
    my $self = shift;
    my $node = shift;
    my $cb   = pop || die "No callback";
    
    my $walk;
    $walk = sub {
        my $nd = shift;
        $walk->($nd->{left}) if defined $nd->{left};
        $self->yield($cb, $nd);
        $walk->($nd->{right}) if defined $nd->{right};
    };

    eval {
        $walk->($node);
    };

    return if $self->is_last;
    die $@ if $@;
}

package main;

my $inner = Iter->new();
my $outer = Iter->new();

my @ar = ( );

$outer->counter(sub {
    my $i = shift;
    $outer->last if $i >= 5;
    $inner->counter(sub {
        my $j = shift;
        push @ar, [ $i, $j ];
        $outer->next if $j >= $i;
    });
    die "We should never get here";
});

my @ref = ( );

for my $i (1 .. 4) {
    for my $j (1 .. $i) {
        push @ref, [ $i, $j ];
    }
}

is_deeply(\@ar, \@ref, 'nested loops');

sub tree_put {
    my ($node, $val) = @_;
    unless (defined($node)) {
        return {
            left    => undef,
            right   => undef,
            value   => $val
        };
    }
    
    if ($val < $node->{value}) {
        $node->{left} = tree_put($node->{left}, $val);
    } else {
        $node->{right} = tree_put($node->{right}, $val);
    }
    
    return $node;
}

srand(1);

my $tree = undef;
@ref = ( );

for (1 .. 20) {
    my $val = int(rand(100));
    push @ref, $val if $val < 50;
    $tree = tree_put($tree, $val);
}

@ref = sort { $a <=> $b } @ref;

my @res = ( );
$outer->walk_tree($tree, sub {
    my $node = shift;
    $outer->last if $node->{value} >= 50;
    push @res, $node->{value};
});

is_deeply(\@res, \@ref, 'aborted tree walk');

my $err = "Bang!\n";

eval {
    $outer->walk_tree($tree, sub {
        my $node = shift;
        die $err if $node->{value} >= 50;
        push @res, $node->{value};
    });
};

is($@, $err, 'can throw exception');
