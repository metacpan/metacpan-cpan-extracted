#!perl

use DBI;
use Getopt::Std;
use strict;

use constant PROMPT          => 'mysql.PP> ';
use constant WELCOME_MESSAGE => "Welcome to the MySQL.PP monitor. Type 'quit' for quit mysq.PP.\n";
use constant QUIT_MESSAGE    => "Bye\n";


my %option;
getopts '?vh:u:P:', \%option;
my $database = shift;
show_version() if $option{v};
show_usage()   if $option{'?'} || ! defined $database;
$option{h} ||= 'localhost';
$option{u} ||= $ENV{USER};
$option{P} ||= 3306;

my $password;
system 'stty -echo';
print 'Enter password: ';
chomp($password = <STDIN>);
system 'stty echo';
print "\n";

my $dbh = eval {
	DBI->connect(
		"dbi:mysqlPP:database=$database;hostname=$option{h};port=$option{P}",
		$option{u}, $password, {
			RaiseError => 1, PrintError => 0
	});
};
die $DBI::errstr if $@;

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
					$sth->rows, $dbh->{mysqlpp_insertid};
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
Usage: mysq.pl [-?v] -h HOSTNAME [-u USER] DATABASE

  -?   Display this help and exit.
  -h   Connect to host.
  -u   User for login if not current user.
  -v   Output version information and exit.

  Example:
    % mysql.pl -h mysql.example.jp -u root mydatabase
__USAGE__
}

sub show_version
{
	die <<__VERSION__;
$0  Ver $DBI::mysqlPP::VERSION
__VERSION__
}

__END__
