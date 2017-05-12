package t::testNode;


use strict;
sub new {
    my ($class,%args) = @_;
    my $self = {};
    bless $self, $class;
    $self->{id} = $args{id};
		
    return $self;
}

sub id {
    my ($self,$id) = @_;
    $self->{id} = $id if defined($id);
    return $self->{id};
}


1;
