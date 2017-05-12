use 5.008000;
use ExtUtils::MakeMaker;
use Getopt::Long();
use Data::Dumper;

use vars qw($opt);
$opt = {};

Getopt::Long::GetOptions(
    $opt,
    "help" => sub {Usage()},
    "dsn=s",
    "user=s",
    "password:s",
    "table=s",
    ) || die Usage();


my ($dsn, $user, $password, $table) = ('', '', 'UNDEF', '');

$dsn = $ENV{DBI_DSN} if (exists($ENV{DBI_DSN}));
$user = $ENV{DBI_USER} if (exists($ENV{DBI_USER}));
$password = $ENV{DBI_PASS} if (exists($ENV{DBI_PASS}));
$table = $ENV{DBI_TABLE} if (exists($ENV{DBI_TABLE}));

$dsn = $opt->{dsn} if (exists($opt->{dsn}));
$user = $opt->{user} if (exists($opt->{user}));
$password = $opt->{password} if (exists($opt->{password}));
$table = $opt->{table} if (exists($opt->{table}));

$table ||= 'drop_me_dbixl4p';

open OUT, ">dbixl4p.config";
print OUT "$dsn\n";
print OUT "$user\n";
print OUT "$password\n";
print OUT "$table\n";
close OUT;

warn "\nPlease NOTE\nYou need to set and export the DBI_* environment variables or supply suitable\nvalues on the command line (see Perl Makefile.PL --help) to run a complete test\n\n";

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    NAME              => 'DBIx::LogAny',
    VERSION_FROM      => 'lib/DBIx/LogAny.pm', # finds $VERSION
    LICENSE           => 'perl',
    PREREQ_PM         => {
        Log::Any => 0.14,
        Log::Any::Adapter => 0.10,
        DBI => 1.50,
        File::Spec => 0,
        Data::Dumper => 0,
        Test::More => 0.62,
        Module::Loaded => 0},
    META_MERGE => {
        resources => {
            bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=DBIx-LogAny',
            repository => 'https://github.com/mjegh/DBIx-LogAny.git',
            Mailinglist => 'http://dbi.perl.org/support',
            homepage => 'http://search.cpan.org/dist/DBIx-LogAny',
        }
    },
    ($] >= 5.005 ?     ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM  => 'lib/DBIx/LogAny.pm', # retrieve abstract from module
       AUTHOR         => 'Martin J. Evans <mjevans@cpan.org>') : ()),
);


sub Usage {
  print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --dsn=<db>         The DBI DSN to pass to DBI->connect
  --user=<user>      Use the username <user> for running the test suite;
                     defaults to no username
  --password=<pwd>   Use the password <pwd> for running the test suite;
                     defaults to no password
  --table=<table>    A table to be used as a test table in the DB
                     defaults to dbixl4p
USAGE
  exit 1;
}
