#!perl

use DBI;
use Getopt::Std;
use strict;

use constant PROMPT          => 'pgsql.PP> ';
use constant WELCOME_MESSAGE => "Welcome to the DBD::PgPP monitor. Type 'quit' for quit pgsql.PP.\n";
use constant QUIT_MESSAGE    => "Bye\n";


my %option;
getopts '?vh:u:dP:', \%option;
my $database = shift;
show_version() if $option{v};
show_usage()   if $option{'?'} || ! defined $database;
$option{u} ||= $ENV{USER};
$option{P} ||= 5432;

my $password;
system 'stty -echo';
print 'Enter password: ';
chomp($password = <STDIN>);
system 'stty echo';
print "\n";

my $dbh;
eval {
	$dbh = DBI->connect(
		"dbi:PgPP:database=$database;hostname=$option{h};port=$option{P};debug=$option{d}",
		$option{u}, $password, {
			RaiseError => 1, PrintError => 0
	});
};
die $@ if $@;

print WELCOME_MESSAGE;
print PROMPT;
while (my $query = <>) {
	chomp $query;
	last if $query =~ /^(?:q(?:uit)?|exit|logout|logoff)$/i;
	if ($query !~ /^\s*$/) {
		eval {
			my $sth = $dbh->prepare($query);
			my $rc = $sth->execute;
			if ($query =~ /select /i) {
				while (my $row = $sth->fetch) {
					printf "%s\n", join ', ', @$row;
				}
			}
			elsif ($query =~ /insert /i) {
				printf "insert %d records. last index: %d\n",
					$sth->rows, $dbh->{pgpp_insertid};
			}
			else {
				printf "update %d records.\n",
					$sth->rows;
			}
		};
		if ($@) {
			print $dbh->errstr, "\n";
		}
	}
	print PROMPT;
}

print QUIT_MESSAGE;
$dbh->disconnect;
exit;


sub show_usage
{
	die <<__USAGE__;
Usage: pgsql.pl [-?vd] [-h HOSTNAME] [-u USER] DATABASE

  -?   Display this help and exit.
  -h   Connect to host.
  -d   Show Debug information.
  -u   User for login if not current user.
  -v   Output version information and exit.

  Example:
    % pgsql.pl -u root mydatabase
__USAGE__
}

sub show_version
{
	die <<__VERSION__;
$0  Ver $DBI::PgPP::VERSION
__VERSION__
}

__END__
