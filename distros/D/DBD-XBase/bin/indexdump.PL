
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

#!/usr/bin/perl -w 

use strict;
use XBase::Index;
use Getopt::Long;

my %opts = ();
my $type;
my $startvalue;
my $showtotal;
GetOptions('debug:i' => sub { my $key = shift; my $val = shift;
				$val = 1 if $val eq '0';
				$XBase::Index::DEBUG = $val },
	'type=s' => sub { my $key = shift;
				my $val = shift;
				if ($val eq 'num') { $type = 'N'; }
				elsif ($val eq 'date') { $type = 'D'; }
				elsif ($val eq 'char') { $type = 'C'; }
				elsif ($val eq 'string') { $type = 'C'; }
				else { die "Unknown index type `$val'\n"; }
		},
	'start=s' => \$startvalue,
	'tag=s' => sub { $opts{'tag'} = $_[1]; },
	'n' => sub { $showtotal = 1; },
	);
$opts{'type'} = $type if defined $type;

# AUDIO 4608
# FACILITY 3072
# FILM 9216
# MAIN 7680
# ROOMNAME 1536

my $file = shift;
if (@ARGV and not defined $opts{'tag'}) { $opts{'tag'} = shift; }
my $index = new XBase::Index $file, %opts or die XBase::Index->errstr;
if (not defined $opts{'tag'}) {
	my @tags = $index->tags;
	if (@tags) {
		print map "$_\n", @tags;
		my $numtags = @tags;
		print "Number of tags: $numtags\n" if $showtotal;
		exit;
	}
}

if (defined $startvalue) {
	$index->prepare_select_eq($startvalue) or die $index->errstr;
	}
else {
	$index->prepare_select or die $index->errstr;
	}

my $i = 0;
while (my @data = $index->fetch())
	{
	print "@data\n";
	$i++;
	}

if ($index->errstr) { die $index->errstr; }

print "Total records: $i\n" if $showtotal;

=head1 NAME

indexdump - Show the content of the index file

=head1 FORMAT

        indexdump [options] file [ tag ]

where options are

        --debug		output record separator (default newline)
        --type		specifies the num/date/char type of the index
        --start		defines the value to start dump from
        --n		prints also the total number of records
			in the file

=head1 SYNOPSIS

        indexdump rooms.cdx FACILITY
        indexdump --debug=14 --start=Dub rooms.cdx ROOMNAME

=head1 DESCRIPTION

Indexdump prints to standard output the content of the index file.
The type of the index is one of those supported by the XBase::Index
Perl module (cdx, idx, ntx, ndx, mdx).

The output contains the index key and the value, which is the record
number in the correcponding dbf file.

For mulitag index files (like cdx), you need to specify the tag name
to get the actual data.

=head1 AVAILABLE FROM

http://www.adelton.com/perl/DBD-XBase/

=head1 AUTHOR

(c) 1999--2013 Jan Pazdziora.

=head1 SEE ALSO

perl(1); XBase::Index(3)

=cut

__END__


EOBODY

