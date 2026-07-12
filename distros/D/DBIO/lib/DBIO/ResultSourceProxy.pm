package DBIO::ResultSourceProxy;
# ABSTRACT: Proxy result source methods onto a result class

use strict;
use warnings;

use base 'DBIO::Base';

use DBIO::ResultSource::Table;
use Scalar::Util 'blessed';
use DBIO::Util 'quote_sub';
use namespace::clean;

__PACKAGE__->mk_group_accessors('inherited_ro_instance' => 'source_name');

__PACKAGE__->mk_classdata(table_class => 'DBIO::ResultSource::Table');

__PACKAGE__->mk_classdata('table_alias'); # FIXME: Doesn't actually do
                                          # anything yet!

sub get_inherited_ro_instance {  shift->get_inherited(@_) }


sub set_inherited_ro_instance {
  my $self = shift;

  $self->throw_exception ("Cannot set @{[shift]} on an instance")
    if blessed $self;

  $self->set_inherited(@_);
}



sub add_columns {
  my ($class, @cols) = @_;
  my $source = $class->result_source_instance;
  $source->add_columns(@cols);
  foreach my $c (grep { !ref } @cols) {
    # If this is an augment definition get the real colname.
    $c =~ s/^\+//;

    $class->register_column($c => $source->column_info($c));
  }
}

sub add_column { shift->add_columns(@_) }



sub add_relationship {
  my ($class, $rel, @rest) = @_;
  my $source = $class->result_source_instance;
  $source->add_relationship($rel => @rest);
  $class->register_relationship($rel => $source->relationship_info($rel));
}


# legacy resultset_class accessor, seems to be used by cdbi only
sub iterator_class { shift->result_source_instance->resultset_class(@_) }

for my $method_to_proxy (qw/
  source_info
  result_class
  resultset_class
  resultset_attributes

  columns
  has_column

  remove_column
  remove_columns

  column_info
  columns_info
  column_info_from_storage

  set_primary_key
  primary_columns
  sequence

  add_unique_constraint
  add_unique_constraints

  unique_constraints
  unique_constraint_names
  unique_constraint_columns

  relationships
  relationship_info
  has_relationship
/) {
  quote_sub __PACKAGE__."::$method_to_proxy", sprintf( <<'EOC', $method_to_proxy );
    DBIO::Util::assert_no_internal_indirect_calls() and DBIO::Util::fail_on_internal_call;
    shift->result_source_instance->%s (@_);
EOC

}


sub _init_result_source_instance {
    my $class = shift;

    $class->mk_classdata('result_source_instance')
        unless $class->can('result_source_instance');

    my $table = $class->result_source_instance;
    my $class_has_table_instance = ($table and $table->result_class eq $class);
    return $table if $class_has_table_instance;

    my $table_class = $class->table_class;
    $class->ensure_class_loaded($table_class);

    if( $table ) {
        $table = $table_class->new({
            %$table,
            result_class => $class,
            source_name => undef,
            schema => undef
        });
    }
    else {
        $table = $table_class->new({
            name            => undef,
            result_class    => $class,
            source_name     => undef,
        });
    }

    $class->result_source_instance($table);

    return $table;
}

sub table {
  my ($class, $table) = @_;
  return $class->result_source_instance->name unless $table;

  unless (blessed $table && $table->isa($class->table_class)) {

    my $table_class = $class->table_class;
    $class->ensure_class_loaded($table_class);

    $table = $table_class->new({
        $class->can('result_source_instance')
          ? %{$class->result_source_instance||{}}
          : ()
        ,
        name => $table,
        result_class => $class,
    });
  }

  $class->mk_classdata('result_source_instance')
    unless $class->can('result_source_instance');

  $class->result_source_instance($table);

  return $class->result_source_instance->name;
}


sub indices {
  my $class = shift;
  my %args = @_ == 1 && ref $_[0] eq 'HASH' ? %{ $_[0] } : @_;

  my $source = $class->result_source_instance;
  my $list = $source->{_cake_indexes} ||= [];
  for my $name (sort keys %args) {
    my $fields = $args{$name};
    $fields = [ $fields ] unless ref $fields eq 'ARRAY';
    push @$list, { name => $name, fields => $fields };
  }

  $class->_install_index_hooks($source);
  return;
}

# Idempotent installer for the two deploy paths that pick up the
# _cake_indexes source slot: the SQL::Translator hook (legacy drivers)
# and the native PostgreSQL pg_indexes class method. Shared with
# DBIO::Cake's idx() so both DSLs end up with the same hook layout.
sub _install_index_hooks {
  my ($class, $source) = @_;

  unless ($source->{_cake_hook_installed}) {
    $source->{_cake_hook_installed} = 1;
    my $orig_hook = $class->can('sqlt_deploy_hook');
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::sqlt_deploy_hook"} = sub {
      my ($self_or_class, $sqlt_table) = @_;
      $orig_hook->($self_or_class, $sqlt_table) if $orig_hook;
      my $src = $self_or_class->isa('DBIO::ResultSource')
        ? $self_or_class
        : $self_or_class->result_source_instance;
      my $idxs = $src->{_cake_indexes} || [];
      for my $idx (@$idxs) {
        $sqlt_table->add_index(
          name   => $idx->{name},
          fields => $idx->{fields},
          (exists $idx->{type}    ? (type    => $idx->{type})    : ()),
          (exists $idx->{options} ? (options => $idx->{options}) : ()),
        );
      }
    };
  }

  unless ($source->{_cake_pg_indexes_installed}) {
    $source->{_cake_pg_indexes_installed} = 1;
    my $orig_pg_indexes = $class->can('pg_indexes');
    no strict 'refs';
    no warnings 'redefine';
    *{"${class}::pg_indexes"} = sub {
      my $invocant = shift;
      my $src = (ref $invocant && $invocant->isa('DBIO::ResultSource'))
        ? $invocant
        : (ref $invocant ? ref($invocant) : $invocant)->result_source_instance;
      my %result = $orig_pg_indexes ? %{ $orig_pg_indexes->($invocant, @_) || {} } : ();
      my $idxs = $src->{_cake_indexes} || [];
      for my $idx (@$idxs) {
        my %entry = (
          columns => $idx->{fields},
          (($idx->{type} // '') =~ /^unique$/i ? (unique => 1) : ()),
        );
        if (my $pg = $idx->{pg}) {
          $entry{where}      = $pg->{where}      if exists $pg->{where};
          $entry{using}      = $pg->{using}      if exists $pg->{using};
          $entry{with}       = $pg->{with}       if exists $pg->{with};
          $entry{expression} = $pg->{expression} if exists $pg->{expression};
        }
        $result{$idx->{name}} = \%entry;
      }
      return \%result;
    };
  }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ResultSourceProxy - Proxy result source methods onto a result class

=head1 VERSION

version 0.900001

=head1 METHODS

=head2 set_inherited_ro_instance

=head2 add_columns

=head2 add_relationship

=head2 table

  __PACKAGE__->table('tbl_name');

Gets or sets the table name. Initialises the result-source instance on
first call.

=head2 indices

  __PACKAGE__->indices(
    name_idx       => 'name',
    name_city_idx => ['name', 'city'],
  );

Declares one or more secondary indexes on the table. Field lists may be a
single column name or an arrayref of column names. A hashref argument is
also accepted:

  __PACKAGE__->indices({ name_idx => 'name' });

The indexes are picked up by both the SQL::Translator deploy path (via
C<sqlt_deploy_hook>) and the native PostgreSQL deploy path (via
C<pg_indexes>). Equivalent to the L<DBICx::Indexing> component on
DBIx::Class. The richer L<DBIO::Cake/idx> DSL shares the same underlying
hook installer.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
