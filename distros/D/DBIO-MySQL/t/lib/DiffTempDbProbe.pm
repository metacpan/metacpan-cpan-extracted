package DiffTempDbProbe;

# Asks up front whether the account of a live test may create and drop the
# temporary database a diff deploys its target model into (karr k105). The
# live diff tests already probe their own scratch database (dbio_k*), but the
# diff needs a second one, named after DBIO::MySQL::Deploy's temp_db_prefix
# (_dbio_tmp_*). An account granted the one but not the other is a missing
# GRANT, not a driver bug: the test skips and names the GRANT, instead of
# failing every diff with "Access denied".
#
# The probe goes the diff's own way -- DBIO::MySQL::Deploy's _create_temp_db
# and _drop_temp_db -- so it asks for exactly the name and statements a diff
# will use.

use strict;
use warnings;

use base 'Exporter';
our @EXPORT_OK = qw(temp_db_skip_reason);

use DBIO::MySQL::Deploy;

# undef when the account may create and drop the temporary database, else the
# reason to skip.
sub temp_db_skip_reason {
  my ($dbh) = @_;
  my $deploy = DBIO::MySQL::Deploy->new;
  (my $pattern = $deploy->temp_db_prefix . '%') =~ s/_/\\_/g;
  my $grant  = "GRANT ALL ON `$pattern`.*";

  my $name;
  unless (eval { $name = $deploy->_create_temp_db($dbh); 1 }) {
    (my $error = "$@") =~ s/\s+\z//;
    return "this account may not create and drop the temporary database a diff deploys into"
      . " -- it needs $grant: $error";
  }
  unless (eval { local $dbh->{Warn} = 0; $deploy->_drop_temp_db($dbh, $name); 1 }) {
    (my $error = "$@") =~ s/\s+\z//;
    return "this account may create but not drop the temporary database a diff deploys into"
      . " -- it needs $grant; database `$name` is left on the server, drop it by hand: $error";
  }
  return undef;
}

1;
