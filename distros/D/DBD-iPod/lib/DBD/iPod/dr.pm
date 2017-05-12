=head1 NAME

DBD::iPod::dr - Database driver for the iPod

=head1 SYNOPSIS

Don't use this class directly, See L<DBD::iPod>.

=head1 DESCRIPTION

This is the actual driver implementation that sets
up the connection to the iPod.  You don't need to use
it directly.

=head1 AUTHOR

Author E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

L<DBD::_::dr>, L<Mac::iPod::GNUpod>.

=head1 COPYRIGHT AND LICENSE

GPL

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut

package DBD::iPod::dr;
use strict;
use base qw(DBD::_::dr);
our $VERSION = '0.01';
our $REVISION = '0.01';

use vars qw($imp_data_size);

use DBI;
use Mac::iPod::GNUpod;

$imp_data_size = 0;

=head2 connect()

 Usage   : DBI->connect('dbi:iPod:');
           DBI->connect('dbi:iPod:/mnt/ipod'); #same as above
           DBI->connect('dbi:iPod:/mnt/ipod2'); alternate mountpoint
 Function: connect to the iPod and read the iTunesDB in it.
 Returns : a DBI::db object
 Args    : DSN to be used for connection, See L<DBI>.

=cut

sub connect {
  my ($drh, $dbname, $user, $pass, $attr) = @_;
  my ($dbh, $ipod);

  my(undef,undef,$path) = split ':', $dbname;
  $path ||= '/mnt/ipod';
  $user ||= '';
  $pass ||= '';

  $dbh = DBI::_new_dbh($drh, {
                              'Name'          => $dbname,
                              'USER'          => $user,
                              'CURRENT_USER'  => $user,
                              'Password'      => $pass,
                             });

  # Create a Mac::iPod::GNUpod instance, and store it.  We can reuse
  # this for multiple queries.
  $ipod = Mac::iPod::GNUpod->new(mountpoint => $path);
  $ipod->read_itunes();

  $dbh->STORE('driver_ipod' => $ipod);

  return $dbh;
}

=head2 disconnect_all()

L<DBI>.

This method does not flush buffered writes to the iPod,
synchronize the iTunesDB, or anything else.  It is a DBI
method only.

=cut

sub disconnect_all { 1 }

=head2 data_sources()

L<DBI>.  Returns "iPod".

=cut

sub data_sources { return "iPod" }

1;

__END__
