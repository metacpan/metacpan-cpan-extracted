package DBIx::ObjectMapper::Query::Update;
use strict;
use warnings;
use base qw(DBIx::ObjectMapper::Query::Base);

sub new {
    my $class = shift;
    my $self = $class->SUPER::new(@_);
    $self->builder( $self->engine->query->update );
    return $self;
}

{
    no strict 'refs';
    my $pkg = __PACKAGE__;
    for my $meth ( qw( table set where add_table add_set add_where ) ) {
        *{"$pkg\::$meth"} = sub {
            my $self = shift;
            $self->builder->$meth(@_);
            return $self;
        };
    }
};

sub execute {
    my $self = shift;
    return $self->engine->update( $self->builder, $self->callback, @_ );
}

1;

