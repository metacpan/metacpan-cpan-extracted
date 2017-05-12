BEGIN { } 
use strict;
use warnings;
use ExtUtils::MakeMaker;
use Data::Dumper;

my $conf_file = 'mysql.pldat';

my $table = 'TEMP_DATA_CONSUMER_TEST_TABLE';
my $db = 'dev';
my $usr = 'test';
my $pwd = 'test';
unless (-e $conf_file) {

	print <<EOFTEXT;
To test properly I will need access to a MySQL database 
with create and drop table privileges. To do this I will
need to ask some more questions to complete configuration.

What you answer will be stored in the file '$conf_file' 
and will not be removed unless you do a make clean, thus
you wont have to go through this process again even if you
rerun this script. If you wish to change your answer 
delete the file (or run make clean) and rerun Makefile.PL.

If you wish to set things up now the db, username, and 
password will by default be '$db', '$usr', '$pwd', 
and the table I will create and drop for testing 
will be '$table'.

EOFTEXT

	my $do_mysql_config = prompt "Run MySQL tests? [yes/no]",'no';
	my @connect;
	if ($do_mysql_config=~/^y/i) {
		$db  = prompt "Please enter database name:",$db;
		$usr = prompt "Please enter user name to connect to $db with:",$usr;
		$pwd = prompt "Please enter password to use for $usr:",$pwd;
		$table = prompt "Table to use for testing:",$table;
		push @connect,$db,$usr,$pwd;
	}
	open my $fh,">",$conf_file or die "Cant open '$conf_file' for writing: $!";
			print $fh Data::Dumper->Dump([$table, \@connect],[qw(*table *connect_args)]);
	close $fh;
}

WriteMakefile(
    NAME                => 'Data::Consumer',
    AUTHOR              => 'Yves Orton <YVES@cpan.org>',
    VERSION_FROM        => 'lib/Data/Consumer.pm',
    ABSTRACT_FROM       => 'lib/Data/Consumer.pm',
    PL_FILES            => {},
    PREREQ_PM => {
        'Test::More' => 0,
	'Data::Dumper' => 0,
	'DBI' => 0,
	'File::Spec' => 3.2701,
	'File::Path' => 2.04,
	'Fcntl' => 0,
	'POSIX' => 0,
    },
    dist                => { COMPRESS => 'gzip -9f', SUFFIX => 'gz', },
    clean               => { FILES => "Data-Consumer-* *~ $conf_file" },
);
