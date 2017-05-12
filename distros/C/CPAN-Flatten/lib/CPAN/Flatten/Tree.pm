package CPAN::Flatten::Tree;
use strict;
use warnings;
use utf8;
use Scalar::Util 'weaken';

sub new {
    my $class = shift;
    my %args = ref $_[0] ? %{$_[0]} : @_;
    my $self = bless {
        _parent => undef,
        _children => [],
        %args,
    }, $class;
    $self;
}

sub add_child {
    my ($self, $node) = @_;
    if ($node->{_parent}) {
        require Carp;
        Carp::confess("node (@{[$node->uid]}) already has a parent");
    }
    push @{ $self->{_children} }, $node;
    $node->{_parent} = $self;
    weaken $node->{_parent};
    $self;
}

sub is_child {
    my ($self, $that) = @_;
    for my $child ($self->children) {
        return 1 if $child->equals($that);
    }
    return;
}

sub is_sister {
    my ($self, $that) = @_;
    return if $self->is_root;
    for my $sister ($self->parent->children) {
        return 1 if $sister->equals($that);
    }
    return;
}

sub children {
    my ($self, $filter) = @_;
    my @children = @{$self->{_children}};
    if ($filter) {
        grep { $filter->($_) } @children;
    } else {
        @children;
    }
}

sub parent {
    shift->{_parent};
}

sub is_root {
    shift->parent ? 0 : 1;
}

sub root {
    my $node = shift;
    while (1) {
        return $node if $node->is_root;
        $node = $node->parent;
    }
}

sub depth {
    my $node = shift;
    my $depth = 0;
    while (1) {
        return $depth if $node->is_root;
        $node = $node->parent;
        $depth++;
    }
}

use constant STOP => -1;

sub walk_down {
    my ($self, $callback, $depth) = @_;
    $depth ||= 0;
    my $ret = $callback->($self, $depth);
    return $ret if defined $ret && $ret eq STOP;
    for my $child ($self->children) {
        $ret = $child->walk_down($callback, $depth + 1);
        return $ret if defined $ret && $ret eq STOP;
    }
    return 1;
}

sub uid {
    my $self = shift;
    my ($uid) = ("$self" =~ /\((.*?)\)$/);
    $uid;
}

sub equals {
    my ($self, $that) = @_;
    $self->uid eq $that->uid;
}

1;
