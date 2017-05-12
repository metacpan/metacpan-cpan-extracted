#use strict;
use Config ();
use DBI::DBD ();
use Getopt::Long();
use ExtUtils::MakeMaker();

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
my $PB_HOME = $ENV{$PRIMEBASEHOME} || '/usr/local/primebase';


die qq{  The PRIMEBASEHOME environment variable must be set
  to the installation location of the PrimeBase SDK or data server, 
  or the PrimeBase SDK or data server must be installed in it's 
  default location '/usr/local/primebase'.
} unless stat("$PB_HOME/lib/libpbapi.a");

################################################################
# Get PrimeBase server info.
use vars qw($opt);
$opt =
  { "help" => \&Usage,
  };
Getopt::Long::GetOptions($opt, "help", "testdb=s", "testhost=s",
			 "testserver=s",
			 "testuser=s", "testpassword=s");

my $source = {};

foreach my $key (qw/testdb testhost testserver testuser testpassword/) {
  Configure($opt, $source, $key);
}

print <<"MSG";
I will use the following settings for testing:

MSG

delete $opt->{'help'};
my $keylen = 0;
foreach my $key (keys %$opt) {
  $keylen = length($key) if length($key) > $keylen;
}
my $slen = 0;
foreach my $val (values %$source) {
  $slen = length($val) if length($val) > $slen;
}
foreach my $key (sort { $a <=> $b} keys %$opt) {
  printf("  %-" . $keylen . "s (%-" . $slen . "s) = %s\n",
	 $key, $source->{$key}, $opt->{$key})
}

print <<"MSG";

To change these settings, see 'perl Makefile.PL --help' and
'perldoc INSTALL'.

MSG

sleep 5;

################################################################
# Generate the default environment settings file.
my($output);

$output=100;
open (output, ">t/PrimeBase.env");


foreach my $key (sort { $a <=> $b} keys %$opt) {
  if ($key eq "testdb") {
    printf output "\$ENV{'DBI_DATABASE'}='%s';\n", $opt->{$key};
  } elsif ($key eq "testuser") {
    printf output "\$ENV{'DBI_USER'}='%s';\n", $opt->{$key};
  } elsif ($key eq "testpassword") {
    printf output "\$ENV{'DBI_PASS'}='%s';\n", $opt->{$key};
  }  elsif ($key eq "testhost") {
    printf output "\$ENV{'DBI_HOST'}='%s';\n", $opt->{$key};
  }  elsif ($key eq "testserver") {
    printf output "\$ENV{'DBI_SERVER'}='%s';\n", $opt->{$key};
  } 
}

print output "\$ENV{'DBI_DSN'}=\"DBI:PrimeBase:\$ENV{'DBI_SERVER'};\$ENV{'DBI_HOST'};\$ENV{'DBI_DATABASE'}\";\n";

close(output);

system( 'cp t/PrimeBase.env benchmarks/PrimeBase.env');


###############################################################


ExtUtils::MakeMaker::WriteMakefile(
    'ABSTRACT' => 'A PrimeBase driver for the Perl5 Database Interface (DBI)',
    'AUTHOR' => 'Barry Leslie <Barry.Leslie@PrimeBase.com>',
    'INC' => "-I\$(DBI_INSTARCH_DIR) -I$PB_HOME/include ",
    'LIBS' => "-L$PB_HOME/lib -lpbapi -lm",
    'NAME'	=> 'DBD::PrimeBase',
    'OBJECT' => '$(O_FILES)',
	'clean' => { 'FILES' => '*.xsi' },
    'VERSION_FROM' => 'PrimeBase.pm', 
);


sub MY::postamble {
    return DBI::DBD::dbd_postamble(@_);
}

############################################################################
#
#   Name:    Usage
#
#   Purpose: Print Usage message and exit with error status.
#
############################################################################

sub Usage {
  print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --testdb=<db>          Use the database <db> for running the test suite;
                         defaults to DBI_TEST
  --testuser=<user>      Use the username <user> for running the test suite;
                         defaults to Administrator
  --testpassword=<pwd>   Use the password <pwd> for running the test suite;
                         defaults to no password
  --testhost=<host>      Use <host> as a database server for running the
                         test suite; defaults to localhost.
  --testserver=<server>  Use <server> as the data server name of the PrimeBase 
                         data server; defaults to PrimeServer.
  --help                 Print this message and exit

All options may be configured on the command line. 

USAGE
  exit 1;
}

############################################################################
#
#   Name:    Configure
#
#   Purpose: Automatic configuration
#
#   Inputs:  $param - Name of the parameter being configured
#
#   Returns: Generated value, never undef
#
############################################################################

sub Configure {
  my($opt, $source, $param) = @_;

  if (exists($opt->{$param})) {
    $source->{$param} = "Users choice";
    return;
  }

  if ($param eq "testdb") {
    $source->{$param} = "default";
    $opt->{$param} = "Perl_test";
  } elsif ($param eq "testuser") {
    $source->{$param} = "default";
    $opt->{$param} = "Administrator";
  } elsif ($param eq "testpassword") {
    $source->{$param} = "default";
    $opt->{$param} = "";
  }  elsif ($param eq "testhost") {
    $source->{$param} = "default";
    $opt->{$param} = "localhost";
  }  elsif ($param eq "testserver") {
    $source->{$param} = "default";
    $opt->{$param} = "PrimeServer";
  } else {
    die "Unknown configuration parameter: $param";
  }
}

