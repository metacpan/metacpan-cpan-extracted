=head1 NAME

DBD::iPod - Connect to an iPod via DBI

=head1 SYNOPSIS

 use DBI;
 my $dbh = DBI->connect('dbi:iPod:');

 #or explicitly give mount path, /mnt/ipod is the default
 #my $dbh = DBI->connect('dbi:iPod:/mnt/ipod');

 #not mounted at /mnt/ipod ?  do this:
 #my $dbh = DBI->connect('dbi:iPod:/mnt/ipod2');

 my $sth = $dbh->prepare("SELECT * FROM iPod");
 $sth->execute();

 my(%artist,$c,$count);

 print STDERR "\nGenerating stats from iPod, this may take a few minutes...\n";

 while(my $row = $sth->fetchrow_hashref){
   $artist{ $row->{artist} }++;
   $c += $row->{time};
   $count++;
 }

 my($h,$m,$s,$u) = (0,0,0,0);

 $c /= 1000; #milliseconds to seconds
 $cs = $c;
 $cm = int($c / 60);
 $cs %= 60;
 $ch = int($cm / 60);
 $cm %= 60;
 $cu = $c % 1;

 $cs += $cu;
 $cs = sprintf("%.3f",$cs);
 $cs = '0'.$cs if $cs < 10;
 my $hmsu = sprintf('%02d:%02d:%s',$ch,$cm,$cs);

 print "\n\n".
 "=======================================\n".
 "         This iPod contains:\n".
 "  Artists:         ".scalar(keys(%artist))."\n".
 "  Tracks:          ".$count."\n".
 "  Total Play Time: ".$hmsu."\n".
 "=======================================\n\n";

=head1 DESCRIPTION

Connect to the iPod using Mac::iPod::GNUpod and present the iTunes
database as a DBD datasource.  You query the iPod's iTunesDB database
using a subset of SQL.  iTunesDB is currently I<read only>, and thus
only supports the SQL SELECT statement.

We expect the iPod to be mounted at C</mnt/ipod>.  If you've mounted
elsewhere (or have multiple iPodia mounted), use an alternate system
path.  L</SYNOPSIS>.

=head2 THE iPod TABLE

There isn't really a table in the iPod.  But we can make it look that
way thanks to the wonderful GNUpod project.  It might look like this:

    Column    |     Type
 -------------+--------------
   bitrate    | kb/s
   time       | milliseonds
   stoptime   | milliseconds
   songs      | ?
   fdesc      | text
   srate      | Hertz
   rating     | integer
   cdnum      | ?
   cds        | ?
   starttime  | milliseconds
   playcount  | integer
   id         | GUID
   prerating  | ?
   volume     | integer
   songnum    | integer
   path       | filepath
   genre      | genre
   filesize   | bytes
   artist     | text
   album      | album name
   comment    | comment
   title      | track name
   uniq       | GUID

=head2 PARTIAL SQL SELECT SUPPORT

Not all SELECT functionality is implemented.  Actually, almost none of
it is implemented.  Here are some examples of what you I<can> do:

 SELECT * FROM iPod;
 SELECT artist,title FROM iPod;
 SELECT * FROM iPod LIMIT 10,20;
 SELECT * FROM iPod WHERE artist LIKE 'something%';
 SELECT * FROM iPod WHERE artist LIKE 'something else%'
   OR (bitrate = 1024 AND playcount >= 1);

If you need more SQL functionality, please send me a patch.  I'd really
like to get DISTINCT(), COUNT(), and GROUP BY working.

=head1 AUTHOR

Allen Day E<lt>allenday@ucla.eduE<gt>

=head1 SEE ALSO

L<Mac::iPod::GNUpod>, L<DBI>.

GNUpod - http://www.gnu.org/software/gnupod/

iPodLinux - http://www.ipodlinux.org/index.php/Main_Page

=head1 BUGS / TODO

* Add playlist support.  Should be implemented in Mac::iPod::GNUpod, it
is in the original GNUpod project.

* Add more SELECT clause and function support.  Especially "GROUP BY",
"DISTINCT()", and "COUNT()".

* Add INSERT and UPDATE support.

* Some fields are missing, e.g. BPM (beats/minute) that are present in
the iTunesDB.  I've also read at iPodLinux, but not personally observed yet,
that track ratings may be borked given what I understand about GNUpod.

=head1 COPYRIGHT AND LICENSE

GPL

=head1 APPENDIX

The rest of the documentation details each of the object methods.
Internal methods are usually preceded with a '_'.  Methods are
in alphabetical order for the most part.

=cut

package DBD::iPod;
use strict;
use base qw();
our $VERSION = '0.01';
our $REVISION = '0.01';

use vars qw($err $errstr $state $drh);

use DBI;
use DBD::iPod::dr;
use DBD::iPod::db;
use DBD::iPod::st;
use DBD::iPod::parser;

# ----------------------------------------------------------------------
# Standard DBI globals: $DBI::err, $DBI::errstr, etc
# ----------------------------------------------------------------------
$err     = 0;
$errstr  = "";
$state   = "";
$drh     = undef;

=head2 driver()

 Usage   :
 Function: Creates a new driver handle, which will be a singleton.
 Example :
 Returns : 
 Args    :

=cut

sub driver {
  unless ($drh) {
    my ($class, $attr) = @_;
    my %stuff = (
                 'Name'              => 'iPod',
                 'Version'           => $VERSION,
                 'DriverRevision'    => $REVISION,
                 'Err'               => \$err,
                 'Errstr'            => \$errstr,
                 'State'             => \$state,
                 'Attribution'       => 'DBD::iPod - Allen Day <allenday@ucla.edu>',
                 'AutoCommit'        => 1, # to avoid errors
                );

    $class = join "::", $class, "dr";

    $drh = DBI::_new_drh($class, \%stuff);
  }

  return $drh;
}

sub DESTROY { 1 }

1;

__END__
