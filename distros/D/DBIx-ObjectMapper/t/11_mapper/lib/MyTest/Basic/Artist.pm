package MyTest::Basic::Artist;
use strict;
use warnings;

sub new {
    my $class = shift;
    my $attr = shift;
    bless \%$attr, $class;
}

sub id {
    my $self = shift;
    $self->{id} = shift if @_;
    return $self->{id};
}

sub firstname {
    my $self = shift;
    $self->{firstname} = shift if @_;
    return $self->{firstname};
}

sub lastname {
    my $self = shift;
    $self->{lastname} = shift if @_;
    return $self->{lastname};
}

sub fullname {
    my $self = shift;
    return $self->firstname . ' ' . $self->lastname;
}

1;
