package DBIx::ObjectMapper::Metadata;
use strict;
use warnings;
use DBIx::ObjectMapper::Metadata::Table;
use DBIx::ObjectMapper::Utils;

my $DEFAULT_QUERY_CLASS = 'DBIx::ObjectMapper::Query';

sub new {
    my $class = shift;
    my %attr = @_;

    bless {
        tables       => +{},
        engine       => $attr{engine} || undef,
        query_class  => $attr{query_class} || $DEFAULT_QUERY_CLASS,
        query_object => undef,
    }, $class;
}

sub engine {
    my $self = shift;
    if( @_ ) {
        my $engine = shift;
        $self->{engine} = $engine;
        $_->engine($engine) for values %{$self->table};
    }

    return $self->{engine};
}

sub table {
    my $self = shift;

    if( @_ == 1 ) {
        my $table_name = shift;
        return $self->{tables}{$table_name};
    }
    elsif ( @_  == 2 || @_ == 3 ) {
        my $table_name = shift;
        my $col        = shift || [];
        my $attr       = shift || +{};
        $attr->{engine} ||= $self->engine if $self->engine;
        $self->{tables}{$table_name} =
            DBIx::ObjectMapper::Metadata::Table->new(
                $table_name, $col, $attr
            );
    }
    else {
        return $self->{tables};
    }
}

*t = \&table;

sub autoload_all_tables {
    my $self   = shift;
    my $engine = $self->engine;
    my @tables = $engine->get_tables;
    $self->table( $_ => [], { engine => $engine, autoload => 1 } )
        for @tables;
    return @tables;
}

sub load_from_declaration {
    my $self = shift;
    my @declaration = @_;
    my @tables;
    for my $d ( @declaration ) {
        DBIx::ObjectMapper::Utils::load_class($d);
        push @tables, $self->table( @$_ ) for $d->get_declaration;
    }
    return @tables;
}

sub query_object {
    my $self = shift;
    return $self->{query_object} ||= $self->{query_class}->new($self->engine);
}

sub select { $_[0]->query_object->select }
sub insert { $_[0]->query_object->insert }
sub delete { $_[0]->query_object->delete }
sub update { $_[0]->query_object->update }

1;

__END__

=head1 NAME

DBIx::ObjectMapper::Metadata

=head1 AUTHOR

Eisuke Oishi

=head1 COPYRIGHT

Copyright 2010 Eisuke Oishi

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under the same terms as Perl itself.

