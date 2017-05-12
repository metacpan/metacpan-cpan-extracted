use Test::More tests => 8;

# dependencies
use_ok("Carp");
use_ok("IO::File");
use_ok("DBI");
use_ok("DBD::Mock");

use Class::AccessorMaker { bla => '' }, 'no_new';

ok(UNIVERSAL::can("main", "bla"), "Class::AccessorMaker works - OK");

# can we use CGI::Persist?
use_ok("DBD::Log");

# can we do everything;

my $dbi = DBI->connect("DBI:Mock:database=test", "user", "pass");
my $fh  = IO::File->new( ">&STDOUT" );

$dbi = DBD::Log->new( dbi => $dbi,
		      logFH => $fh,
                      dbiLogging => 1,
                    );


is(ref($dbi), "DBD::Log");
is(ref($dbi->dbi), "DBI::db");
