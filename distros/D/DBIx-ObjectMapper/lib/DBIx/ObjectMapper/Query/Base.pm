package DBIx::ObjectMapper::Query::Base;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;

sub new {
    my $class = shift;
    my $engine = shift || confess 'usage: ' . $class . '->new($engine)';
    my $callback = shift || undef;
    bless { engine => $engine, callback => $callback }, $class;
}

sub engine   { $_[0]->{engine} }
sub callback { $_[0]->{callback} }

sub builder {
    my $self = shift;
    $self->{builder} = shift if @_;
    return $self->{builder};
}

sub execute { die "Abstract Method" }

sub as_sql {
    my $self = shift;
    return $self->builder->as_sql(@_);
}

sub DESTROY {
    my $self = shift;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

1;
