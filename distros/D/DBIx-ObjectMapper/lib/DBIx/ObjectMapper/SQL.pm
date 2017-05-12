package DBIx::ObjectMapper::SQL;
use strict;
use warnings;
use DBIx::ObjectMapper::SQL::Select;
use DBIx::ObjectMapper::SQL::Insert;
use DBIx::ObjectMapper::SQL::Update;
use DBIx::ObjectMapper::SQL::Delete;
use DBIx::ObjectMapper::SQL::Set;

sub new {
    my $class = shift;
    my $driver = shift;
    bless { driver => $driver }, $class;
}

sub select {
    my $self = shift;
    my %param = @_;
    $param{driver} = $self->{driver} if ref $self;
    return DBIx::ObjectMapper::SQL::Select->new(%param);
}

sub insert {
    my $self = shift;
    return DBIx::ObjectMapper::SQL::Insert->new(@_);
}

sub update {
    my $self = shift;
    return DBIx::ObjectMapper::SQL::Update->new(@_);
}

sub delete {
    my $self = shift;
    return DBIx::ObjectMapper::SQL::Delete->new(@_);
}

sub union {
    my $self = shift;
    $self->_aggregate('union', @_);
}

sub intersect {
    my $self = shift;
    $self->_aggregate('intersect', @_);
}

sub except {
    my $self = shift;
    $self->_aggregate('except', @_);
}

sub _aggregate {
    my $self = shift;
    my $meth = shift;
    my $driver = ref($self) ? $self->{driver} : undef;
    return DBIx::ObjectMapper::SQL::Set->new(
        word   => $meth,
        driver => $driver,
        @_,
    );
}

1;
__END__

