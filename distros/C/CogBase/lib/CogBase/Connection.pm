package CogBase::Connection;
use strict;
use warnings;
use CogBase::Base -base;
use CogBase::Factory;
use CogBase::Index;

field 'db_location';
field factory => -init =>
    'CogBase::Factory->New(connection => $self)';
field index => -init =>
    'CogBase::Index->New(connection => $self)';

sub connection {
    my ($class, $location) = @_;
    my $connection_class =
        $location =~ m!^https?://!
        ? 'CogBase::Connection::HTTP'
        : -d $location
          ? 'CogBase::Connection::FileSystem'
          : die "'$location' is an invalid CogBase location";
    unless ($connection_class->can('New')) {
        eval "require $connection_class; 1"
          or die $@;
    }
    return $connection_class->New(db_location => $location);
}

sub node {
    my ($self, $type) = @_;
    return $self->factory->new_node($type);
}

sub fetch {
    my ($self, @nodes) = @_;
    my @result;
    for my $node (@nodes) {
        $node = CogBase::Node->New(Id => $node)
          unless ref $node;
        $self->fetch_node($node);
        push @result, $node;
    }
    return @result;
}

sub store {
    my ($self, @nodes) = @_;
    for my $node (@nodes) {
        $self->store_node($node);
    }
    return;
}

sub disconnect {
    my $self = shift;
    bless $self, ref($self) . '::disconnected';
}

sub fetchSchemaNode {
    my ($self, $type) = @_;
    my ($id) = $self->query("!Schema")
      or return;
    my $node = CogBase::Node->New(
        Id => $id,
        Type => 'Schema',
    );
    $self->fetch($node);
    return $node;
}

1;
