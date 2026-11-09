package DBIO::Schema::ModelCompiler;
# ABSTRACT: compile a base-type schema into one engine's native target model

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp qw/croak/;
use DBIO::Schema::Type ();
use namespace::clean;


sub new {
  my ($class, %args) = @_;
  croak "adapter required" unless $args{adapter};
  bless { %args }, $class;
}


sub adapter { $_[0]->{adapter} }


sub compile {
  my ($self, $schema) = @_;
  my $adapter = $self->adapter;
  my %tables;

  for my $moniker ($schema->sources) {
    my $source = $schema->source($moniker);
    my $name   = $source->name;
    next if ref $name;                       # skip virtual views (scalar-ref name)

    my $info   = $source->columns_info;
    my %is_pk  = map { $_ => 1 } $source->primary_columns;

    my @columns;
    for my $col_name ($source->columns) {
      my $canon  = DBIO::Schema::Type::canonical_column($col_name, $info->{$col_name});
      push @columns, {
        column_name    => $col_name,
        native_type    => $adapter->to_native($canon),
        not_null       => $canon->{not_null},
        default        => $canon->{default},
        is_pk          => ($is_pk{$col_name} ? 1 : 0),
        auto_increment => $canon->{auto_increment},
      };
    }

    $tables{$name} = {
      table_name  => $name,
      columns     => \@columns,
      primary_key => [ $source->primary_columns ],
    };
  }

  return { tables => \%tables };
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Schema::ModelCompiler - compile a base-type schema into one engine's native target model

=head1 VERSION

version 0.900004

=head1 SYNOPSIS

    my $compiler = DBIO::Schema::ModelCompiler->new(adapter => $adapter);
    my $model    = $compiler->compile($schema);

=head1 DESCRIPTION

Walks every source of a DBIO schema, normalises each column to its base type
through L<DBIO::Schema::Type/canonical_column>, and asks an adapter (see
L<DBIO::Adapter::Base>) for the engine-native type. The result is a plain
target model for one engine.

=head1 METHODS

=head2 new

    my $compiler = DBIO::Schema::ModelCompiler->new(adapter => $adapter);

Croaks unless C<adapter> is given. All arguments are kept on the object.

=head2 adapter

Returns the adapter passed to L</new>.

=head2 compile

    my $model = $compiler->compile($schema);

Returns C<< { tables => { $table_name => $table, ... } } >>, one entry per
source whose C<name> is a plain string (virtual views with a scalar-ref name
are skipped). Each C<$table> is C<< { table_name, columns => [...],
primary_key => [...] } >>, and each column is C<< { column_name, native_type,
not_null, default, is_pk, auto_increment } >>, with C<native_type> coming from
the adapter's C<to_native>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
