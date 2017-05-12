package Mock::UserObject;

use strict;
use warnings;

sub roles {
    my $self = shift;
    $self->{roles} = [@_] if @_;
    return $self->{roles} ? @{$self->{roles}} : ();
}
sub id {
    my $self = shift;
    $self->{id} = $_[0] if @_;
    return $self->{id};
}
sub supports {
    my $self = shift;
    $self->{supports} = [@_] if @_;
    return @{$self->{supports}};
}

1;
