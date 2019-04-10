#
# This extraction code was taken from the libwww modules.
#
use Config;
my $filename = $0;

$filename =~ s/\.PL$//;
open OUT,">$filename" or die "Can't create $filename: $!";
chmod(0755, $filename);
print "Extracting $filename (with #! substitution)\n";

print OUT <<"EOHEADER";
$Config{'startperl'} -w
	eval 'exec perl -S \$0 "\$@"'
		if 0;

EOHEADER

print OUT <<'EOBODY';

use vars qw( $running_under_some_shell );

=head1 NAME

dbfcstocs -- charset conversion of dbf files

=head1 FORMAT

	dbfcstocs [options] src_encoding dst_encoding [file.dbf outfile.dbf...]

=head1 SYNOPSIS

	dbfcstocs il2 1250 table.dbf table1.dbf

Please see the

	dbfcstocs --help

for short usage info.

=head1 DESCRIPTION

This script is a wrapper aound the cstocs utility, please see its man
page first. This program converts charsets in dbf database files. You
can also use the --field-names-charset option which will specify to
which charset to convert the field names. So you can convert file in
Windows-1250 to IOS-8859-2, but have its field names converted to
US-ASCII:

	dbfcstocs --field-names-charset-ascii 1250 il2 table.dbf table1.dbf

After the encoding specifications, pass couples of input dbf file,
output destination file names.

=head1 SEE ALSO

cstocs(1).

=head1 AUTHOR

Jan Pazdziora

=cut

use strict;
use Cz::Cstocs;
use Cz::Cstocs::Getopt;
use XBase;

my ($convert, $options) = Cz::Cstocs::Getopt::process_argv(
	{
	'field-names-charset=s' => 'field-names-charset',
	'memofile=s' => 'memofile',
	'memosep=s' => 'memosep',
	'nomemo' => 'ignorememo',
	'help' => sub {
		print "This is dbfcstocs version $Cz::Cstocs::VERSION.\n";
		print STDERR <<EOF;
Usage: dbftocstocs [options] inputenc outputenc [ in.dbf out.dbf ... ]
  where options can be
    --field-names-charset=charset	Convert field names to this charset.
    --memofile=str	Name of the memo (dbt, fpt) file.
    --nomemo		Do not open the memo file.
    --memosep		See dbfdump(1), you probably don't need this.
  and reasonable options of cstocs (see cstocs --help), most notably
  -i doesn't work in dbfcstocs. After the encoding specifications,
  pairs of input and output dbf file names should follow.
Available encodings are:
  @{[ &Cz::Cstocs::available_enc() ]}
EOF
		exit;
		},
	}
	);

my $names_convert;
if (defined $options->{'field-names-charset'}) {
	$names_convert = new Cz::Cstocs 
		$options->{'inputenc'}, $options->{'field-names-charset'}, 'one-by-one' => 1 or die "Error initializing field names conversion: $Cz::Cstocs::errstr.\n";
	}

### use Data::Dumper; print "Options: ", Dumper $options;

if (not defined $convert) {
	print STDERR $@;
	exit(1);
	}

my $length_of_argv = @ARGV;
if ($length_of_argv == 0) {
	die "Need file names to convert.\n";
	}
elsif ($length_of_argv > 2 and (($length_of_argv % 2) == 1)) {
	die "Need output file name for the last dbf.\n";
	}

while (@ARGV) {
	my $filename = shift @ARGV;
	my $outfilename = shift @ARGV;
	$outfilename = 'out_' . $filename unless defined $outfilename;

	my %other_options = ();
	for (qw!memofile memosep ignorememo!) {
		$other_options{$_} = $options->{$_} if defined $options->{$_};
		}

	my $table = new XBase $filename, %other_options;
	unless (defined $table) {
		print "Error reading $filename: $XBase::errstr";
		next;
		}

	%other_options = ();
	if (defined $names_convert) {
		$other_options{'field_names'} = [ map { &$names_convert($_) } $table->field_names ];
		}

	my $out = $table->create("name" => $outfilename, %other_options)
		or die "Error creating output file: $outfilename: $XBase::errstr";

	my @types = $table->field_types;
	my @convert_fields = ();
	for (my $i = 0; $i < @types; $i++) {
		push @convert_fields, $i if $types[$i] eq 'C' or $types[$i] eq 'M';
		}
	for my $i (0 .. $table->last_record) {
		my @data = $table->get_record($i);
		my $deleted = shift @data;
		for (@data[@convert_fields]) {
		### print STDERR "Converting $_ ";
			$_ = &$convert($_);
		### print STDERR "to $_\n";
			}
		$out->set_record($i, @data);
		$out->delete_record($i) if $deleted;
		}
	$out->close;
	$table->close;
	}

EOBODY
