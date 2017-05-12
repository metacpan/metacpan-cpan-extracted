package MyEntry;
use strict;
use warnings;

# sub base # intentionally left out.

sub new {
    my $class = shift;
    my $self = shift || {};
    return bless $self, $class;
}

sub link {
    my $self = shift;
    if (@_) { $self->{link} = shift }
    return $self->{link};
}
sub title {
    my $self = shift;
    if (@_) { $self->{title} = shift }
    return $self->{title};
}
sub author {
    my $self = shift;
    if (@_) { $self->{author} = shift }
    return $self->{author};
}
sub id {
    my $self = shift;
    if (@_) { $self->{id} = shift }
    return $self->{id};
}
sub content {
    my $self = shift;
    if (@_) { $self->{content} = shift }
    return $self->{content};
}
sub issued {
    my $self = shift;
    if (@_) { $self->{issued} = shift }
    return $self->{issued};
}
sub modified {
    my $self = shift;
    if (@_) { $self->{modified} = shift }
    return $self->{modified};
}
sub category {
    my $self = shift;
    if (@_) { $self->{category} = shift }
    return $self->{category};
}
sub summary {
    my $self = shift;
    if (@_) { $self->{summary} = shift }
    return $self->{summary};
}

1;
