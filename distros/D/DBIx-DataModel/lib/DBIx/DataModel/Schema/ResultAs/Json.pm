#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Json;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Carp;
use JSON::MaybeXS     ();

use parent 'DBIx::DataModel::Schema::ResultAs';

use namespace::clean;

sub new {
  my ($class, %json_options) = @_;
  keys %json_options
    or %json_options = ( pretty          => 1,
                         allow_blessed   => 1,
                         convert_blessed => 1 );
  return bless \%json_options, $class;
}


sub get_result {
  my ($self, $statement) = @_;

  my $json_maker = JSON::MaybeXS->new(%$self);
  my $json       = $json_maker->encode($statement->all);
  return $json;
}


1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Json - result in JSON format

=head1 SYNOPSIS

  $source->select(..., $result_as => 'json');
  # or
  $source->select(..., $result_as => [json => %json_options]);

=head1 DESCRIPTION

Converts all rows to JSON format, using L<JSON::MaybeXS>.
Default options to the JSON converter are

  pretty          => 1,
  allow_blessed   => 1,
  convert_blessed => 1,

but they can be overridden by passing a non-empty hash
as argument to the constructor.


