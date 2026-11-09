package TestDBIO::Extension::Deploy;
# ABSTRACT: Mock driver Deploy over plain-hash models, for the extension protocol tests

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

# Model: { schemas => { name => 1 }, tables => { 'schema.table' => { columns => { col => { type => ... } } } } }
# Address forms of this mock driver: [schema => $name], [column => $table_key, $column].

sub new {
  my ($class, %args) = @_;
  return bless { %args }, $class;
}

sub _extension_list { $_[0]->{extension_list} || [] }

sub _introspect_current  { $_[0]->{source_model} }
sub _build_target_model  { $_[0]->{target_model} }
sub _dbh                 { $_[0]->{dbh} }
sub _diff_class          { 'TestDBIO::Extension::Deploy::Diff' }

sub _extension_driver_helpers {
  return { quote_ident => sub { qq{"$_[0]"} } };
}

sub _apply_extension_claims {
  my ($self, $model, $addresses) = @_;
  for my $address (@$addresses) {
    my ($kind, @rest) = @$address;
    if ($kind eq 'schema') {
      delete $model->{schemas}{ $rest[0] };
      delete $model->{tables}{$_}
        for grep { /^\Q$rest[0]\E\./ } keys %{ $model->{tables} || {} };
    }
    else {
      die "unknown address kind $kind";
    }
  }
  return;
}

sub _apply_extension_annotations {
  my ($self, $model, $triples) = @_;
  for my $triple (@$triples) {
    my ($address, $attribute, $value) = @$triple;
    my (undef, $table, $column) = @$address;
    my $col = $model->{tables}{$table} && $model->{tables}{$table}{columns}{$column}
      or next;
    $col->{$attribute} = $value;
  }
  return;
}

package TestDBIO::Extension::Deploy::Diff;

use strict;
use warnings;

# A diff class derives from DBIO::Diff::Base (apply classifies it); this mock
# renders its statements itself and holds no operation objects.
use base 'DBIO::Diff::Base';

sub operations { [] }

sub new { my ($class, %args) = @_; bless { %args }, $class }

sub source      { $_[0]{source} }
sub target      { $_[0]{target} }
sub has_changes { scalar @{ $_[0]->statements } }
sub as_sql      { $_[0]->statements }

sub statements {
  my ($self) = @_;
  my ($src, $tgt, $ext) = @{$self}{qw(source target extensions)};
  my @sql;
  for my $table (sort keys %{ $src->{tables} || {} }) {
    push @sql, "DROP TABLE $table" unless $tgt->{tables}{$table};
  }
  for my $table (sort keys %{ $tgt->{tables} || {} }) {
    my $old = $src->{tables}{$table} or next;
    for my $column (sort keys %{ $tgt->{tables}{$table}{columns} }) {
      my $o = $old->{columns}{$column} or next;
      my $n = $tgt->{tables}{$table}{columns}{$column};
      next if $o->{type} eq $n->{type};
      my $answer = $ext && $ext->verdict({
        kind => 'column_type', table => $table, column_name => $column,
        old_info => $o, new_info => $n,
      });
      next if $answer && $answer->{refuse};
      push @sql, "ALTER TABLE $table ALTER COLUMN $column TYPE $n->{type}"
        . ($answer && $answer->{using} ? " USING $answer->{using}" : '');
    }
  }
  return \@sql;
}

1;
