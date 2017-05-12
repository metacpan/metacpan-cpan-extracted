=head1 NAME

DBIx::SQLEngine::Record::PKey - A reference to a specific record in a table

=head1 SYNOPSIS

  my $record_class = $sqldb->record_class( $table_name );

  my $keyobj = $record_class->pkey( $record_id );

  print $key->table();
  print $key->value();

  my $record = $key->record();


=head1 DESCRIPTION

B<This package is INCOMPLETE!>

=cut

package DBIx::SQLEngine::Record::PKey;

use strict;
use Carp;

########################################################################

########################################################################

sub new  {

}

########################################################################

sub table {

}

sub value {

}

########################################################################

sub keep_ref {

}

########################################################################

sub record {

}

########################################################################

########################################################################

=head1 SEE ALSO

For more about the Record classes, see L<DBIx::SQLEngine::Record::Class>.

See L<DBIx::SQLEngine> for the overall interface and developer documentation.

See L<DBIx::SQLEngine::Docs::ReadMe> for general information about
this distribution, including installation and license information.

=cut

########################################################################

1;

