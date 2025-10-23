package Cron::Toolkit::Tree::Pattern;
use strict;
use warnings;
use Carp qw(croak);
use Cron::Toolkit::Tree::EnglishVisitor;
use Cron::Toolkit::Tree::MatchVisitor;

sub new {
    my ($class, %args) = @_;
    my $self = bless {
        type => $args{type} // croak "type required",
        children => [],
    }, $class;
    return $self;
}

sub add_child {
    my ($self, $child) = @_;
    push @{$self->{children}}, $child;
}

sub get_children {
    my ($self) = @_;
    return @{$self->{children}};
}

sub traverse {
    my ($self, $visitor) = @_;
    my $type = $self->{type};
    # Direct for range (raw in visit)
    if ($type eq 'range') {
        return $visitor->visit($self, ());
    }
    # Recurse for list/step (flags/extract)
    my @child_results = map { $_->traverse($visitor) } @{$self->{children}};
    return $visitor->visit($self, @child_results);
}

#sub traverse {
#    my ($self, $visitor) = @_;
#    my $type = $self->{type};
#    return $visitor->visit($self, ()) if $type eq 'single' || $type eq 'last' || $type eq 'nth' || $type eq 'nearest_weekday' || $type eq 'lastW';  # Leaves/specials, no children
#    my @child_results = map { $_->traverse($visitor) } @{$self->{children}};
#    return $visitor->visit($self, @child_results);
#}

sub is_match {
    my ($self, $value, $tm) = @_;
    my $visitor = Cron::Toolkit::Tree::MatchVisitor->new(value => $value, tm => $tm);
    return $self->traverse($visitor);
}

sub to_english {
    my ($self, $field_type) = @_;
    my $visitor = Cron::Toolkit::Tree::EnglishVisitor->new(field_type => $field_type);
    return $self->traverse($visitor);
}

sub dump_tree {
    my ($node, $indent, $prefix) = @_;
    $indent //= 0; $prefix //= '';
    my $line = $prefix . "├── " . ucfirst($node->{type});
    $line .= " ($node->{value})" if $node->{value};
    print "$line\n";

    return unless $node->{children} && @{$node->{children}};
    my $last = $node->{children}[-1];
    for my $i (0 .. $#{ $node->{children} }) {
        my $child = $node->{children}[$i];
        my $new_prefix = $prefix . ($child eq $last ? '    ' : '│   ');
        dump_tree($child, $indent + 2, $new_prefix . '├── ');
    }
}

1;
