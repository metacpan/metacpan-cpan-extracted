package DBIx::ObjectMapper::Mapper::Attribute::Property;
use strict;
use warnings;
use Carp::Clan qw/^DBIx::ObjectMapper/;
use Params::Validate qw(:all);
use Scalar::Util qw(weaken);
my @TYPES = qw(column relation);

sub new {
    my $class = shift;

    my %prop = validate(
        @_,
        {
            isa        => +{
                type => OBJECT,
                callbacks => {
                    check_duck_type => sub {
                        $_[0]->can('name') && $_[0]->can('validation');
                    }
                }
            },
            lazy       => +{ type => BOOLEAN, default => 0 },
            validation => +{ type => BOOLEAN, default => 0 },
            getter => +{ type => SCALAR },
            setter => +{ type => SCALAR },
        }
    );

    bless \%prop, $class;
}

sub lazy   { $_[0]->{lazy} }
sub getter { $_[0]->{getter} }
sub setter { $_[0]->{setter} }

## proxy

sub type {
    my $self = shift;

    if( $self->{isa}->isa('DBIx::ObjectMapper::Metadata::Table::Column') ) {
        return 'column';
    }
    elsif( $self->{isa}->isa('DBIx::ObjectMapper::Relation') ) {
        return 'relation';
    }

    return 0;
}

sub validation {
    my $self = shift;
    return $self->{isa}->validation if $self->{validation};
    return;
}

sub name {
    my $self = shift;
    return $self->{isa}->name;
}

sub get {
    my $self = shift;
    if( $self->type eq 'relation' ) {
        return $self->{isa}->get(@_);
    }

    return;
}

sub table {
    my $self = shift;

    if( $self->type eq 'relation' ) {
        return $self->{isa}->table;
    }

    return;
}

sub mapper {
    my $self = shift;
    if( $self->type eq 'relation' ) {
        return $self->{isa}->mapper;
    }
    return;
}

sub relation_condition {
    my $self = shift;

    if( $self->type eq 'relation' ) {
        return $self->{isa}->relation_condition(@_);
    }

    return;
}

sub is_multi {
    my $self = shift;

    if( $self->type eq 'relation' ) {
        return $self->{isa}->is_multi;
    }

    return;
}

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Mapper::Attribute::Property

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

