package MockPgDeploy;

# Test fixture: a driver Deploy over PostgreSQL-shaped plain-hash models, for
# DBIO::Test::ExtensionSet (ADR 0066). It stands in for DBIO::PostgreSQL::Deploy,
# which supplies the protocol hooks in the driver's own work. Model shape and
# address forms are those of the PostgreSQL driver:
#
#   { schemas    => { $name => { name => $name } },
#     extensions => { postgis => { schema_name => 'public' } },
#     tables     => { 'schema.table' => { schema_name, table_name } },
#     columns    => { 'schema.table' => [ { column_name, data_type, type_schema } ] } }
#
#   addresses: [schema => $name], [column => $table_key, $column]
#
# The cascade of a claimed schema takes its tables and their columns.

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}

sub _extension_driver_helpers { return { quote_ident => sub { qq{"$_[0]"} } } }

sub _apply_extension_claims {
  my ($self, $model, $addresses) = @_;
  for my $address (@$addresses) {
    my ($kind, @rest) = @$address;
    die "unknown address kind $kind" unless $kind eq 'schema';
    my $schema = $rest[0];
    delete $model->{schemas}{$schema};
    for my $key (grep { ($model->{tables}{$_}{schema_name} // '') eq $schema }
                 keys %{ $model->{tables} || {} }) {
      delete $model->{tables}{$key};
      delete $model->{columns}{$key};
    }
  }
  return;
}

sub _apply_extension_annotations {
  my ($self, $model, $triples) = @_;
  for my $triple (@$triples) {
    my ($address, $attribute, $value) = @$triple;
    my (undef, $table_key, $column) = @$address;
    my ($col) = grep { $_->{column_name} eq $column }
      @{ $model->{columns}{$table_key} || [] } or next;
    $col->{$attribute} = $value;
  }
  return;
}

sub _diff_class { 'MockPgDeploy::Diff' }

package MockPgDeploy::Diff;

use strict;
use warnings;

sub new { my ($class, %args) = @_; bless { %args }, $class }

sub as_sql {
  my ($self) = @_;
  my ($src, $tgt, $ext) = @{$self}{qw(source target extensions)};
  my @sql;
  for my $key (sort keys %{ $src->{tables} || {} }) {
    push @sql, "DROP TABLE $key" unless $tgt->{tables}{$key};
  }
  for my $key (sort keys %{ $tgt->{tables} || {} }) {
    next unless $src->{tables}{$key};
    my %old = map { $_->{column_name} => $_ } @{ $src->{columns}{$key} || [] };
    for my $new (@{ $tgt->{columns}{$key} || [] }) {
      my $old = $old{ $new->{column_name} } or next;
      next if $old->{data_type} eq $new->{data_type};
      my $answer = $ext && $ext->verdict({
        kind => 'column_type', table => $key, column_name => $new->{column_name},
        old_info => $old, new_info => $new,
      });
      next if $answer && $answer->{refuse};
      push @sql, "ALTER TABLE $key ALTER COLUMN $new->{column_name} TYPE $new->{data_type}"
        . ($answer && $answer->{using} ? " USING $answer->{using}" : '');
    }
  }
  return @sql;
}

1;
