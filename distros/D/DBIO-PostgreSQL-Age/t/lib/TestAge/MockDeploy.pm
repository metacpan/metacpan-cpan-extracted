package TestAge::MockDeploy;
# Mock driver deploy over plain-hash models for the extension tests of this
# distribution (core keeps its own in t/lib of dbio; this is the same shape).
#
# Model: { schemas => { name => 1 },
#          tables  => { 'schema.table' => { columns => { col => { type => ... } } } } }
# Address forms: [schema => $name], [column => $table_key, $column].

use strict;
use warnings;

use base 'DBIO::Deploy::Base';

sub new { my ($class, %args) = @_; bless {%args}, $class }

sub _diff_class { 'TestAge::MockDeploy::Diff' }

sub _extension_driver_helpers { { quote_ident => sub { qq{"$_[0]"} } } }

sub _apply_extension_claims {
  my ($self, $model, $addresses) = @_;
  for my $address (@$addresses) {
    my ($kind, @rest) = @$address;
    die "unknown address kind $kind" unless $kind eq 'schema';
    delete $model->{schemas}{ $rest[0] };
    delete $model->{tables}{$_}
      for grep { /^\Q$rest[0]\E\./ } keys %{ $model->{tables} || {} };
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

package TestAge::MockDeploy::Diff;

use strict;
use warnings;

sub new { my ($class, %args) = @_; bless {%args}, $class }
sub source      { $_[0]{source} }
sub target      { $_[0]{target} }
sub has_changes { scalar @{ $_[0]->statements } }
sub as_sql      { $_[0]->statements }

sub statements {
  my ($self) = @_;
  my ($src, $tgt) = @{$self}{qw(source target)};
  my @sql;
  push @sql, "DROP TABLE $_"
    for grep { !$tgt->{tables}{$_} } sort keys %{ $src->{tables} || {} };
  push @sql, "DROP SCHEMA $_"
    for grep { !$tgt->{schemas}{$_} } sort keys %{ $src->{schemas} || {} };
  return \@sql;
}

1;
