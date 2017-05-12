package DBIx::MoCo::Schema;
use strict;
use Carp;

sub new {
    my $class = shift;
    my $klass = shift or return;
    my $self = {
        class => $klass,
        primary_keys => undef,
        uniquie_keys => undef,
        retrieve_keys => undef,
        utf8_columns => undef,
        columns => undef,
    };
    bless $self, $class;
}

sub primary_keys {
    my $self = shift;
    unless ($self->{primary_keys}) {
        my $class = $self->{class};
        $self->{primary_keys} = $class->db->primary_keys($class->table);
    }
    $self->{primary_keys};
}

sub unique_keys {
    my $self = shift;
    unless ($self->{unique_keys}) {
        my $class = $self->{class};
        $self->{unique_keys} = $class->db->unique_keys($class->table);
    }
    $self->{unique_keys};
}

sub retrieve_keys {
    my $self = shift;
    $self->{retrieve_keys} = $_[0] if $_[0];
    return $self->{retrieve_keys};
}

sub utf8_columns {
    my $self = shift;
    if (@_) {
        my $cols = (ref $_[0] and ref $_[0] eq 'ARRAY') ? $_[0] : [ @_ ];
        $self->{utf8_columns} = $cols;

        my $class = $self->{class};
        no strict 'refs';
        for my $col (@$cols) {
            my $method = $class . '::' . $col;
            *$method = $class->_column_as_handler($col, 'utf8');
            # warn $method;
        }
    }
    return $self->{utf8_columns};
}

sub columns {
    my $self = shift;
    unless ($self->{columns}) {
        my $class = $self->{class};
        $self->{columns} = $class->db->columns($class->table);
    }
    $self->{columns};
}

sub param {
    my $self = shift;
    return $self->{$_[0]} if not exists $_[1];
    @_ % 2 and croak
        sprintf "%s : You gave me an odd number of parameters to param()";
    my %args = @_;
    $self->{$_} = $args{$_} for keys %args;
}

1;

=head1 NAME

DBIx::MoCo::Schema - Schema class for DBIx::MoCo classes

=head1 SYNOPSIS

  my $schema = DBIx::MoCo::Schema->new('MyMoCoClass'); # make an instance

  my $schema = MyMoCoClass->schema; # MyMoCoClass isa DBIx::MoCo
  $schema->primary_keys; # same as MyMoCoClass->primary_keys
  $schema->uniquie_keys; # same as MyMoCoClass->uniquie_keys
  $schema->columns; # same as MyMoCoClass->columns

  # you can set any parameters using param
  $schema->param(validation => {
    name => ['NOT_BLANK', 'ASCII', ['LENGTH', 2, 5]],
    # for example, FormValidator::Simple style definitions
  });
  $schema->param('validation'); # returns validation definitions

=head1 SEE ALSO

L<DBIx::MoCo>, L<FormValidator::Simple>

=head1 AUTHOR

Junya Kondo, E<lt>jkondo@hatena.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) Hatena Inc. All Rights Reserved.

This library is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=cut
