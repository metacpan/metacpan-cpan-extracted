package dbixcsl_test_dir;

# copied from DBIx::Class::Schema::Loader test suite

use strict;
use warnings;
use File::Path 'rmtree';
use File::Temp 'tempdir';
use Scalar::Util 'weaken';
use namespace::clean;
use DBI ();

use base qw/Exporter/;
our @EXPORT_OK = '$tdir';

die "/t does not exist, this can't be right...\n"
  unless -d 't';

my $tbdir = 't/var';

unless (-d $tbdir) {
  mkdir $tbdir or die "Unable to create $tbdir: $!\n";
}

our $tdir = tempdir(DIR => $tbdir);

# We need to disconnect all active DBI handles before deleting the directory,
# otherwise the SQLite .db files cannot be deleted on Win32 (file in use) since
# END does not run in any sort of order.

no warnings 'redefine';

my $connect = \&DBI::connect;

my @handles;

*DBI::connect = sub {
    my $dbh = $connect->(@_);
    push @handles, $dbh;
    weaken $handles[-1];
    return $dbh;
};

END {
    if (not $ENV{SCHEMA_LOADER_TESTS_NOCLEANUP}) {
        foreach my $dbh (@handles) {
            $dbh->disconnect if $dbh;
        }

        rmtree($tdir, 1, 1);
        rmdir($tbdir); # remove if empty, ignore otherwise
    }
}

1;
