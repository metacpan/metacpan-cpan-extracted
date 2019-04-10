
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

cssort -- Czech sort

=head1 FORMAT

cssort [ C<-c>B<list> | C<-f>B<list> [C<-d>B<regexp>]] [files ...]

=head1 SYNOPSIS

	cssort -c10-15,50-,25-45 < file 
	cssort -f3,5-6 < file 
	cssort -f3,5-6 -s: < file 

=head1 DESCRIPTION

Cssort is a utility that sorts input lines according to rules used in
the Czech language. You can run it without any options, then it just
uses whole lines for sorting. With the options, it's possible to
specify parts of the lines to be used for comparison.

=over 4

=item B<list>

A comma-separated list of integer field numbers or field ranges. The
are indexed from 1 and if a range is open (eg. C<5->), it means all
remaining fields from the starting number.

=item B<-c>

Stands for columns and the list that follows specifies byte ranges on
the line. You will probably use this option to sort data with fixed
width fields.

=item B<-f>

Fields that will be used for sort.

=item B<-d>

Delimiter that separates fields in the B<-f> option. It is a Perl
regular expression, the default is C<[ \t]+>, which means any number
of spaces or tabs in a row.

=back

The program assumes ISO-8859-2 encoding. Some way to specify another
input encoding will come in the next versions. If you need to sort
files with different encodings, you might want to check the B<cstocs>
conversion utility.

=head1 SEE ALSO

Cz::Sort(3), cstocs(1).

=head1 AUTHOR

Jan Pazdziora

=cut

use strict;
use Getopt::Std;
use Cz::Sort;

my %opts = (
	'd' => '[ \t]+',
	);

getopt('dfce', \%opts);

if (defined $opts{'h'})
	{
	print STDERR <<"EOF";
This is cssort version $Cz::Sort::VERSION.
Usage info: cssort [ -clist | -flist [-dregexp]] [files ...]
	-c	Columns
	-f	Field numbers
	-d	Delimiter, field separator
Lists are comma separated lists of field (column) numbers or ranges.
Example:	cssort -c10-15,50-,25-45	cssort -f3,5-6 -s:
EOF
	exit(1);
	}

my $switch = 'c';
my $option = $opts{$switch};
if (not defined $option)
	{
	$switch = 'f';
	$option = $opts{$switch};
	}
if (not defined $option)
	{
	$switch = undef;
	}

my $conversion;
if (defined $opts{'e'})
	{
	require Cz::Cstocs;
	$conversion = new Cz::Cstocs $opts{'e'}, 'il2';
	}

if (defined $switch)
	{
	my (@starts, @lengths, @array);
	for (split /,/, $option)
		{
		if (/^\d+$/)
			{ push @starts, $_ - 1; push @lengths, 1; }
		elsif (/^(\d+)-(\d+)$/)
			{ push @starts, $1 - 1; push @lengths, ($2 - $1 + 1); }
		elsif (/^(\d+)-$/)
			{ push @starts, $1 - 1; push @lengths, undef; }
		else
			{ die "Cssort: wrong option '$_' for switch -$switch\n"; }
		}

	if ($switch eq 'c')
		{
		while (<>)
			{
			chomp;
			my $line = [ $_ ];
			my $i;
			for ($i = 0; $i < @starts; $i++)
				{
				if ($starts[$i] >= length $_)
					{ push @$line, undef; }
				elsif (defined $lengths[$i])
					{ push @$line, substr $_, $starts[$i], $lengths[$i]; }
				else
					{ push @$line, substr $_, $starts[$i]; }
				}
			push @array, $line;
			}
		}
	else
		{
		my $regexp = $opts{'d'};
		while (<>)
			{
			chomp;
			my @items = split /$regexp/so;
			my $line = [ $_ ];
			my $i;
			for ($i = 0; $i < @starts; $i++)
				{
				push @$line, @items[$starts[$i] .. (defined $lengths[$i] ? $starts[$i] + $lengths[$i] - 1 : $#items )];
				}
			push @array, $line;
			}
		}

	print map { $_->[0] . "\n" }
		sort
			{
			my $len = ( @$a >= @$b ? @$a : @$b);
			my $i;
			for ($i = 1; $i < $len; $i++)
				{
				if (not defined $a->[$i])
					{
					return 0 if not defined $b->[$i];
					return -1;
					}
				if (not defined $b->[$i])
					{
					return 1;
					}
				my $result = czcmp($a->[$i], $b->[$i]);
				return $result if $result != 0;
				}
			return 0;
			} @array;
	}
else
	{ print czsort <>; }


EOBODY
