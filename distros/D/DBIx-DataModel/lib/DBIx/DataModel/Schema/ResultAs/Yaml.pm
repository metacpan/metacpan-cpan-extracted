#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Yaml;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Carp;
use YAML::XS          qw[Dump];

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;


sub get_result {
  my ($self, $statement) = @_;

  return Dump $statement->all;
}


1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Yaml - result in YAML format

=head1 SYNOPSIS

  $source->select(..., $result_as => 'yaml');

=head1 DESCRIPTION

Converts all rows to YAML format, using L<YAML::XS>.
