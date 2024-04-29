#----------------------------------------------------------------------
package DBIx::DataModel::Schema::ResultAs::Sth;
#----------------------------------------------------------------------
use warnings;
use strict;
use DBIx::DataModel::Carp;

use parent 'DBIx::DataModel::Schema::ResultAs';

sub get_result {
  my ($self, $statement) = @_;

  $statement->execute;
  not $statement->arg(-post_bless)
    or croak "-post_bless incompatible with -result_as=>'sth'";
  return $statement->sth;
}

1;

__END__

=head1 NAME

DBIx::DataModel::Schema::ResultAs::Sth - DBI statement handle

=head1 DESCRIPTION

Returns the underlying L<DBI> statement handle, in an executed state.

Then it is up to the caller to retrieve data rows using the DBI API.
If needed, these rows can be later blessed into appropriate objects
through L<bless_from_DB()|/"bless_from_DB">.


