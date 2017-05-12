use strict;
use 5.00503;
use ExtUtils::MakeMaker;
use Config();
use Getopt::Long();
use Data::Dumper();

my $TESTDB = "test";
my $TESTDRIVER = "";

use vars qw($opt);
$opt = { help	=> \&Usage };
Getopt::Long::GetOptions($opt, "help", "testdb=s", "testhost=s",
                         "testport=s", "testdsn=s", "testdriver=s",
                         "testuser=s", "testpassword=s",
                        );
my $source = {};

foreach my $key (qw/testdsn testdriver testdb testhost testport testuser testpassword/)
{
	Configure($opt, $source, $key);
}

print <<"MSG";
I will use the following settings for compiling and testing:

MSG

delete $opt->{'help'};
my $keylen = 0;
foreach my $key (keys %$opt)
{
	$keylen = length($key) if length($key) > $keylen;
}
my $slen = 0;
foreach my $val (values %$source)
{
	$slen = length($val) if length($val) > $slen;
}
foreach my $key (sort {$a cmp $b} keys %$opt)
{
	printf("  %-" . $keylen . "s (%-" . $slen . "s) = %s\n",
	       $key, $source->{$key}, $opt->{$key});
}

print <<"MSG";

To change these settings, see 'perl Makefile.PL --help'.

MSG

# sleep 5;

eval { require File::Spec };
my $fileName = $@ ?
	"t/dbia.config" : File::Spec->catfile("t", "dbia.config");
die "Failed to determine location of $fileName" unless -f $fileName;
if (open(FILE, ">$fileName"))
{
	print FILE "{ my " . Data::Dumper->Dump([$opt],["opt"]) .
	           "  sub load_all { return (\n".
	           "      driver   => \$opt->{'testdriver'},\n" .
	           "      host     => \$opt->{'testhost'},\n" .
	           "      port     => \$opt->{'testport'},\n" .
	           "      user     => \$opt->{'testuser'},\n" .
	           "      password => \$opt->{'testpassword'},\n" .
	           "      db       => \$opt->{'testdb'},\n" .
	           "      dsn      => \$opt->{'testdsn'},\n" .
	           "      ) }\n".
	           "} 1;\n";
	close(FILE) or die "Failed to create $fileName: $!";
}

# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'		=> 'DBIx::PDlib',
    'VERSION_FROM'	=> 'PDlib.pm', # finds $VERSION
    'PREREQ_PM'		=> {
		'DBI'	=> 0,
		},
    ($] >= 5.005 ?    ## Add these new keywords supported since 5.005
      (ABSTRACT_FROM => 'PDlib.pm', # retrieve abstract from module
       AUTHOR     => 'Josh I. Miller <jmiller@purifieddata.net>') : ()),
);

sub Configure {
	my($opt, $source, $param) = @_;

	if (exists($opt->{$param})) {
		$source->{$param} = "Users choice";
		return;
	}

	if ($param eq "testdriver") {
		$source->{$param} = "default";
		$opt->{$param} = $TESTDRIVER;
	} elsif ($param eq "testdb") {
		$source->{$param} = "default";
		$opt->{$param} = $TESTDB;
	} elsif ($param eq "testuser"  || $param eq "testpassword" ||
		     $param eq "testdsn" || $param eq "testhost" ||
		     $param eq "testport") {
		$source->{$param} = "default";
		$opt->{$param} = "";
	} else {
		die "Unknown configuration parameter: $param";
	}
}

sub Usage
{
	print STDERR <<"USAGE";
Usage: perl $0 [options]

Possible options are:

  --testdsn=<db>         Use the DBI datasource <dsn> for running the test suite

  Or you can connect with these:

  --testdriver=<driver>  Use the DBD driver <driver> for running the test
                         suite; defaults to $TESTDRIVER
  --testdb=<db>          Use the database <db> for running the test suite;
                         defaults to $TESTDB
  --testhost=<host>      Use <host> as a database server for running the
                         test suite; the default is not to specify one
  --testport=<port>      Use <port> as the port number of the database;
                         the default is not to specify one

  --testuser=<user>      Use the username <user> for running the test suite;
                         defaults to no username
  --testpassword=<pwd>   Use the password <pwd> for running the test suite;
                         defaults to no password

  --help                 Print this message and exit

USAGE
	exit 1;
}

__END__
