package DBIx::ObjectMapper::Session::Array;
use strict;
use warnings;
use Scalar::Util qw(refaddr weaken);
use base qw(Tie::Array);

sub new {
    my ( $class, $name, $mapper, @val ) = @_;
    my $array = [];
    tie @$array, $class, $name, $mapper, \@val;
    return $array;
}

sub TIEARRAY {
    my $class = shift;
    my $name = shift;
    my $mapper = shift;
    my $val = shift;

    return bless {
        value      => $val,
        name       => $name,
        mapperaddr => refaddr($mapper->instance),
        mapper     => ref($mapper),
    }, $class;
}

sub name { $_[0]->{name} }

sub mapper {
    my $self = shift;
    return $self->{mapper}->get( $self->{mapperaddr} );
}

sub _remove {
    my $self = shift;

    if( my $mapper = $self->mapper ) {
        $mapper->remove_multi_val( $self->name, $_ )
            for grep { defined $_ } @_;
    }

    return @_;
}

sub _add {
    my $self = shift;

    if( my $mapper = $self->mapper ) {
        $mapper->add_multi_val( $self->name, $_ )
            for grep { defined $_ } @_;
    }

    return @_;
}

sub FETCHSIZE { scalar @{$_[0]->{value}} }

sub FETCH {
    my ($self, $index) = @_;
    return $self->{value}->[$index];
}

#sub STORESIZE {}

sub STORE {
    my ( $self, $index, $value ) = @_;
    $self->{value}->[$index] = $value;
    $self->_add($value);
    return $self->FETCHSIZE;
}

sub SHIFT {
    my $self = shift;
    my $val = shift(@{$self->{value}});
    $self->_remove($val);
    return $val;
}

sub POP {
    my $self = shift;
    my $val = pop(@{$self->{value}});
    $self->_remove($val);
    return $val;
}

sub SPLICE {
    my $self = shift;
    my $sz  = $self->FETCHSIZE;
    my $off = @_ ? shift : 0;
    $off   += $sz if $off < 0;
    my $len = @_ ? shift : $sz-$off;
    my @add = @_;
    my @remove = splice( @{ $self->{value} }, $off, $len, @add );
    $self->_add(@add) if @add;
    $self->_remove(@remove) if @remove;
    return @remove;
}

sub CLEAR {
    my $self = shift;
    $self->_remove(@{$self->{value}});
    $self->{value} = [];
    return;
}

sub DESTROY {
    my $self = shift;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

1;

=head1 NAME

DBIx::ObjectMapper::Session::Array

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.
