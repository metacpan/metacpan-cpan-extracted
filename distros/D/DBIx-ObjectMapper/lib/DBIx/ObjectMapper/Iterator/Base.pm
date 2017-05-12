package DBIx::ObjectMapper::Iterator::Base;
use strict;
use warnings;

use overload
    '@{}' => sub { [ $_[0]->all ] },
#    '0+'  => sub { $_[0]->size },
    fallback => 1,
    ;

sub new {
    my ( $class, $query, $callback ) = @_;
    return bless {
        cursor => 0,
        query => $query,
        callback => $callback && ref($callback) eq 'CODE' ? $callback : undef,
    }, $class;
}

sub cursor {
    my $self = shift;
    $self->{cursor} = shift if @_;
    return $self->{cursor};
}

sub size {}

sub next {}

sub reset {
    my $self = shift;
    $self->{cursor} = 0;
    return $self;
}

sub all {}

sub first {
    my $self = shift;
    $self->reset if $self->cursor > 0;
    my $d = $self->next;
    $self->reset;
    return $d;
}

sub callback {
    my $self = shift;
    if( $self->{callback} ) {
        return $self->{callback}->($_[0], $self->{query});
    }
    else {
        return $_[0];
    }
}

sub DESTROY {
    my $self = shift;
    warn "DESTROY $self" if $ENV{MAPPER_DEBUG};
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Iterator::Base - A base class of iterator for returning query results.

=head1 METHODS

=head2 new

=head2 next

=head2 size

=head2 all

=head2 cursor

=head2 reset

=head2 first

=head2 callback

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

