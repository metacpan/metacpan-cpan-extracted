use ExtUtils::MakeMaker;
use Data::Dumper;
use strict;

# Let's ask some questions

my $virtuals = {};
my $dumped;

if (-e '.cache') {
	print "Oh, I can see that you have run me before, should I reuse these?(y or n)\n";
	my $answer  = getLine();
	if($answer eq 'y') {
		open(FILEHANDLE, "<.cache");
		my @file = <FILEHANDLE>;
		$dumped = join ('', @file);
		goto JUMPOINT;
	}
}

my %driver_methods = (
		'mysql' => \&createMySQL,
		'Pg' => \&createPostgreSQL,
);

print "What is the name of the Virtual User?\n";
my $virtual  = getLine();
while ($virtual) {
	print "What is the dbi driver? (AKA mysql)\n";
	my $driver  = getLine();
	if($driver_methods{$driver}) {
		$driver_methods{$driver}->($virtual, $driver);
	} else {
		print "Unsupported driver, send mail to brian\@tangent.org about supporting it. \n";
		print "For now we will let you just enter the connect string by hand. \n";
		createDefault($driver);
	}
	$virtual = undef;
	print "What is the name of the Virtual User?\n";
	print "(Enter nothing if you are finished adding users.)\n";
	$virtual  = getLine();
}

#Now, lets build up our data structure
my $data = Data::Dumper->new([$virtuals]);
$data->Purity(1);
$data->Indent(3);
$data->Varname('virtual');
$dumped = $data->Dump();
JUMPOINT:
makeFile();
makeTest();
makeCache();

#Now, lets grab the version
open (FILEHANDLE, "VERSION");
my $version = <FILEHANDLE>;
close (FILEHANDLE);
# See lib/ExtUtils/MakeMaker.pm for details of how to influence
# the contents of the Makefile that is written.
WriteMakefile(
    'NAME'	=> 'DBIx::Password',
    'VERSION' => $version, # finds $VERSION
);

sub getLine {
	my $data = <STDIN>;
	chomp($data);
	return $data;
}

sub makeFile {
	open(FILEHANDLE, "Password.pm-orig"); 
	my @file = <FILEHANDLE>;
	close (FILEHANDLE);
	open(FILEHANDLE, ">Password.pm"); 
	for (@file) {
		chomp($_);
		if(/#PASSWORD_INSERT/) {
			print FILEHANDLE ("my $dumped\n");
		} else {
			print FILEHANDLE ("$_\n");
		}
	}
	close (FILEHANDLE);
}

sub makeTest {
	open(FILEHANDLE, "test.pl-orig"); 
	my @file = <FILEHANDLE>;
	close (FILEHANDLE);
	open(FILEHANDLE, ">test.pl"); 
	for (@file) {
		chomp($_);
		if(/#PASSWORD_INSERT/) {
			print FILEHANDLE ("my $dumped\n");
		} else {
			print FILEHANDLE ("$_\n");
		}
	}
	close (FILEHANDLE);
}

sub makeCache {
	open(FILEHANDLE, ">.cache"); 
	print FILEHANDLE $dumped;
	close (FILEHANDLE);
}

sub createMySQL {
	my %attributes;
	my $driver = 'mysql';
	print "What is the name of the database?\n";
	my $database  = getLine();
	print "What is the name of the machine that the database is on?\n";
	my $hostname  = getLine();
	my $connect = "DBI:$driver:database=$database;host=$hostname";
	print "Is the database on any special port(you should probably just hit return)?\n";
	my $port  = getLine();
	$connect .= ";port=$port" if $port;
	print "What is the username?\n";
	my $username  = getLine();
	print "What is the password?\n";
	my $password  = getLine();
	print "What attributes would you like to add?\n";
	print "(Enter nothing to skip or finish)\n";
	my $attr  = getLine();
	while($attr) {
		print "What is the value of the attribute?\n";
		my $value  = getLine();
		$attributes{$attr} = $value;
		print "What attributes would you like to add?\n";
		print "(Enter nothing to skip or finish)\n";
		$attr  = getLine();
	}
	$virtuals->{$virtual} = {
			connect => $connect,
			driver => $driver,
			database => $database,
			host => $hostname,
			port => $port,
			username => $username,
			password => $password,
			attributes => \%attributes
			};
}
sub createPostgreSQL {
	my $driver = 'Pg';
	print "What is the name of the database?\n";
	my $database  = getLine();
	print "What is the name of the machine that the database is on?\n";
	my $hostname  = getLine();
	my $connect = "DBI:$driver:dbname=$database;host=$hostname";
	print "Is the database on any special port(you should probably just hit return)?\n";
	my $port  = getLine();
	$connect .= ";port=$port" if $port; 
	print "What is the username?\n";
	my $username  = getLine();
	print "What is the password?\n";
	my $password  = getLine();
	$virtuals->{$virtual} = {
			connect => $connect,
			driver => $driver,
			database => $database,
			host => $hostname,
			port => $port,
			username => $username,
			password => $password,
			};
}

sub createDefault{
	my ($driver) = @_;
	print "What is the connect string?\n";
	my $connect  = getLine();
	print "What is the username?\n";
	my $username  = getLine();
	print "What is the password?\n";
	my $password  = getLine();
	$virtuals->{$virtual} = {
			connect => $connect,
			driver => $driver,
			username => $username,
			password => $password,
			};
}
