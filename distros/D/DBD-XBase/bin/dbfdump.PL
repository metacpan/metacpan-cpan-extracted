
use Config;
my $filename = $0;

$filename =~ s/\.PL$//;
open OUT,">$filename" or die "Can't create $filename: $!";
chmod(0755, $filename);
print "Extracting $filename (with #! and variable substitution)\n";

print OUT <<"EOHEADER";
$Config{'startperl'} -w

EOHEADER

print OUT <<'EOBODY';

use XBase;
use Getopt::Long;
use strict;
$^W = 1;

my $stdin = 0;

if (defined $ARGV[$#ARGV] and $ARGV[$#ARGV] eq '-') {
	$stdin = 1; pop @ARGV;
}

my %options;
Getopt::Long::GetOptions( \%options,
	'help', 'version', 'info', 'rs=s', 'fs=s', 'undef=s', 'fields=s',
	'nomemo', 'memofile=s', 'memosep=s', 'table',
	'SQL',
	) or exit;

if (defined $options{'version'}) {
	print "This is dbfdump version $XBase::VERSION.\n";
	exit;
}

if ($stdin) {
	push @ARGV, '-';
	$options{'nomemo'} = 1;
}

if (@ARGV == 0 or defined $options{'help'}) {
	die <<'EOF';
Usage: dbfdump [ options ] files
    where the options specify
	--rs		output record separator (default newline)
	--fs		output field separator (default colon)
	--fields	comma separated list of fields to print (default all)
	--undef		what to print for NULL values (default empty string)
	--memofile	specifies unstandard name of attached memo file
	--memosep	separator for dBase III dbt's (default \x1a\x1a)
	--table		output in nice table format (needs Data::ShowTable)
    all having as parameter a string; and also
	--nomemo	do not try to read the memo (dbt/fpt) file 
	--info		only print info about the file and fields
	--version	print version of the XBase library
EOF
}

my %addopts = ();
if (defined $options{'nomemo'} or defined $options{'info'}) {
	$addopts{'ignorememo'} = 1;
}

$addopts{'memosep'} = $options{'memosep'};
$addopts{'memofile'} = $options{'memofile'};

if (defined $options{'info'}) {
	$addopts{'ignorebadheader'} = 1;
}

my $file;
for $file (@ARGV) {
	my $table = new XBase 'name' => $file, %addopts;

	if (not defined $table) {
		print STDERR XBase->errstr;
		next;
	}
	if (defined $options{'info'}) {
		if (not defined $options{'SQL'}) {
			print $table->header_info;
		} else {
			my $name = $file;
			$name =~ s!^.*/|\.dbf$!!ig;
			print "create table $name (\n";
			my @names = $table->field_names;
			my %conv = qw!
				C varchar
				N numeric
				F numeric
				L boolean
				M blob
				D date
				T time
				!;
			my @types = map { $conv{$_} } $table->field_types;
			my @lengths = $table->field_lengths;
			my @decimals = $table->field_decimals;
			for (my $i = 0; $i < @names; $i++) {
				print "\t$names[$i] $types[$i]";
				if ($types[$i] eq 'blob') {
					$lengths[$i] = $decimals[$i] = undef;
				}
				if ($lengths[$i] or $decimals[$i]) {
					print "($lengths[$i]";
					print ", $decimals[$i]" if $decimals[$i];
					print ")";
				}
				if (defined $names[$i+1]) {
					print ',';
				}
				print "\n";
			}
			print ")\n";
		}
	} else {
		$table->dump_records(%options) or print STDERR $table->errstr;
	}
	$table->close;
}

1;

__END__

=head1 NAME

dbfdump - Dump the record of the dbf file

=head1 FORMAT

	dbfdump [options] files

where options are

	--rs		output record separator (default newline)
	--fs		output field separator (default colon)
	--fields	comma separated list of fields to print (default all)
	--undef		string to print for NULL values (default empty)
	--memofile	specifies unstandard name of attached memo file
	--memosep	separator for dBase III dbt's (default \x1a\x1a)

	--nomemo	do not try to read the memo (dbt/fpt) file
	--info		print info about the file and fields
		with additional --SQL parameter, outputs the SQL create table
	--version	print version of the XBase library
	--table		output in nice table format (only available when
		Data::ShowTable is installed, overrides rs and fs)

=head1 SYNOPSIS

	dbfdump -fields id,msg table.dbf
	dbfdump -fs=' : ' table
	dbfdump --nomemo file.dbf

	ssh user@host 'cat file.dbf.gz' | gunzip - | dbfdump -

=head1 DESCRIPTION

Dbfdump prints to standard output the content of dbf files listed. By
default, it prints all fields, separated by colons, one record on
a line. The output record and column separators can be changed by
switches on the command line. You can also ask only for some fields to
be printed.

The content of associated memo files (dbf, fpt) is printed for memo
fields, unless you use the C<--nomemo> option.

You can specify reading the standard input by putting dash (-) instead
of file name.

=head1 AVAILABLE FROM

http://www.adelton.com/perl/DBD-XBase/

=head1 AUTHOR

(c) 1998--2011 Jan Pazdziora.

=head1 SEE ALSO

perl(1); XBase(3)

=cut

EOBODY

