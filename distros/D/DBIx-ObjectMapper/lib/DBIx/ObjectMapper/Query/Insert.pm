package DBIx::ObjectMapper::Query::Insert;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Query::Base);

sub new {
    my $class = shift;
    my $engine = shift;
    my $callback = shift;
    my $self = $class->SUPER::new($engine, $callback);
    $self->{primary_keys} = shift || [];
    $self->builder( $self->engine->query->insert );
    return $self;
}

{
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $meth ( qw( into values add_values ) ) {
        *{"$pkg\::$meth"} = sub {
            my $self = shift;
            $self->builder->$meth(@_);
            return $self;
        };
    }
};

sub execute {
    my $self = shift;
    my $primary_key
        = @{ $self->{primary_keys} } ? $self->{primary_keys} : shift || undef;
    return $self->engine->insert( $self->builder, $self->callback,
        $primary_key );
}

1;

