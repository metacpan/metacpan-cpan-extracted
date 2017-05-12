
=head1 NAME

Cz::Sort - Czech sort

=cut

#
# Here starts the Cz::Sort namespace
#
package Cz::Sort;
no locale;
use integer;
use strict;
use Exporter;
use vars qw( @ISA @EXPORT $VERSION $DEBUG );
@ISA = qw( Exporter );

#
# We implicitly export czcmp, czsort, cscmp and cssort functions.
# Since these are the only ones that can be used by ordinary users,
# it should not cause big harm.
#
@EXPORT = qw( czsort czcmp cssort cscmp );

$VERSION = '0.68';
$DEBUG = 0;
sub DEBUG	{ $DEBUG; }

#
# The table with sorting definitions.
#
my @def_table = (
	'aA áÁ âÂ ãÃ äÄ ±¡',
	'bB',
	'cC æÆ çÇ',		'èÈ',
	'dD ïÏ ðÐ',
	'eE éÉ ìÌ ëË êÊ',
	'fF',	
	'gG',
	'hH',
	'<ch><Ch><CH>',
	'iI íÍ îÎ',
	'jJ',
	'kK',
	'lL åÅ µ¥ ³£',
	'mM',
	'nN ñÑ òÒ',
	'oO óÓ ôÔ öÖ õÕ',
	'pP',
	'qQ',
	'rR àÀ',		'øØ',
	'sS ¶¦ ºª',		'¹©',
	'ß',
	'tT »« þÞ',
	'uU úÚ ùÙ üÜ ûÛ',
	'vV',
	'wW',
	'xX',
	'yY ýÝ',
	'zZ ¿¯ ¼¬',		'¾®',
	'0',		'1',		'2',		'3',
	'4',		'5',		'6',		'7',
	'8',	'9',
	' .,;?!:"`\'',
	' -­|/\\()[]<>{}',
	' @&§%$',
	' _^=+×*÷#¢~',
	' ÿ·°¨½¸²',
	' ¤',
	);

#
# Conversion table will hold four arrays, one for each pass. They will
# be created on the fly if they are needed. We also need to hold
# information (regexp) about groups of letters that need to be considered
# as one character (ch).
#
my @table = ( );
my @regexp = ( '.', '.', '.', '.' );
my @multiple = ( {}, {}, {}, {} );

#
# Make_table will build sorting table for given level.
#
sub make_table
	{
	my $level = shift;
	@{$table[$level]} = ( undef ) x 256;
	@{$table[$level]}[ord ' ', ord "\t"] = (0, 0);
	my $i = 1;
	my $irow = 0;
	while (defined $def_table[$irow])
		{
		my $def_row = $def_table[$irow];
		next if $level <= 2 and $def_row =~ /^ /;
		while ($def_row =~ /<([cC].*?)>|(.)/sg)
			{
			my $match = $+;
			if ($match eq ' ')
				{
				if ($level == 1)
					{ $i++; }
				}
			else
				{
				if (length $match == 1)
					{ $table[$level][ord $match] = $i; }
				else
					{
					$multiple[$level]{$match} = $i;
					$regexp[$level] = $match . "|" . $regexp[$level];
					}
				if ($level >= 2)
					{ $i++; }
				}
			}
		$i++ if $level < 2;
		}
	continue
		{ $irow++; }
	}

#
# Create the tables now.
#
for (0 .. 3)
	{ make_table($_); }

#
# Compare two scalar, according to the tables.
#
sub czcmp
	{
	my ($a, $b) = (shift, shift);
	print STDERR "czcmp: $a/$b\n" if DEBUG;
	my ($a1, $b1) = ($a, $b);
	my $level = 0;
	while (1)
		{
		my ($ac, $bc, $a_no, $b_no, $ax, $bx) = ('', '', 0, 0,
			undef, undef);
		if ($level == 0)
			{
			while (not defined $ax and not $a_no)
				{
				$a =~ /$regexp[$level]/sg or $a_no = 1;
				$ac = $&;
				$ax = ( length $ac == 1 ?
					$table[$level][ord $ac]
					: ${$multiple[$level]}{$ac} )
						if defined $ac;
				}
			while (not defined $bx and not $b_no)
				{
				$b =~ /$regexp[$level]/sg or $b_no = 1;
				$bc = $&;
				$bx = ( length $bc == 1 ?
					$table[$level][ord $bc]
					: ${$multiple[$level]}{$bc} )
						if defined $bc;
				}
			}
		else
			{
			while (not defined $ax and not $a_no)
				{
				$a1 =~ /$regexp[$level]/sg or $a_no = 1;
				$ac = $&;
				$ax = ( length $ac == 1 ?
					$table[$level][ord $ac]
					: ${$multiple[$level]}{$ac} )
						if defined $ac;
				}
			while (not defined $bx and not $b_no)
				{
				$b1 =~ /$regexp[$level]/sg or $b_no = 1;
				$bc = $&;
				$bx = ( length $bc == 1 ?
					$table[$level][ord $bc]
					: ${$multiple[$level]}{$bc} )
						if defined $bc;
				}
			}

		print STDERR "level $level: ac: $ac -> $ax; bc: $bc -> $bx ($a_no, $b_no)\n" if DEBUG;

		return -1 if $a_no and not $b_no;
		return 1 if not $a_no and $b_no;
		if ($a_no and $b_no)
			{
			if ($level == 0)
				{ $level = 1; next; }
			last;
			}

		return -1 if ($ax < $bx);
		return 1 if ($ax > $bx);

		if ($ax == 0 and $bx == 0)
			{
			if ($level == 0)
				{ $level = 1; next; }
			$level = 0; next;
			}
		}
	for $level (2 .. 3)
		{
		while (1)
			{
			my ($ac, $bc, $a_no, $b_no, $ax, $bx)
				= ('', '', 0, 0, undef, undef);
			while (not defined $ax and not $a_no)
				{
				$a =~ /$regexp[$level]/sg or $a_no = 1;
				$ac = $&;
				$ax = ( length $ac == 1 ?
					$table[$level][ord $ac]
					: ${$multiple[$level]}{$ac} )
						if defined $ac;
				}
			while (not defined $bx and not $b_no)
				{
				$b =~ /$regexp[$level]/sg or $b_no = 1;
				$bc = $&;
				$bx = ( length $bc == 1 ?
					$table[$level][ord $bc]
					: ${$multiple[$level]}{$bc} )
						if defined $bc;
				}
			
			print STDERR "level $level: ac: $ac -> $ax; bc: $bc -> $bx ($a_no, $b_no)\n" if DEBUG;
			return -1 if $a_no and not $b_no;
			return 1 if not $a_no and $b_no;
			if ($a_no and $b_no)
				{ last; }
			return -1 if ($ax < $bx);
			return 1 if ($ax > $bx);
			}
		}
	return 0;
	}

1;

#
# Cssort does the real thing.
#
sub czsort
	{ sort { my $result = czcmp($a, $b); } @_; }

*cscmp = *czcmp;
*cssort = *czsort;

1;

__END__

=head1 SYNOPSIS

	use Cz::Sort;
	my $result = czcmp("_x j&á", "_&p");
	my @sorted = czsort qw(plachta plaòka Plánièka plánièka plánì);
	print "@sorted\n";

=head1 DESCRIPTION

Implements czech sorting conventions, indepentent on current locales
in effect, which are often bad. Does the four-pass sort. The idea and
the base of the conversion table comes from Petr Olsak's program B<csr>
and the code is as compliant with CSN 97 6030 as possible.

The basic function provided by this module, is I<czcmp>. If compares
two scalars and returns the (-1, 0, 1) result. The function can be
called directly, like

	my $result = czcmp("_x j&á", "_&p");

But for convenience and also because of compatibility with older
versions, there is a function I<czsort>. It works on list of strings
and returns that list, hmm, sorted. The function is defined simply
like

	sub czsort
		{ sort { czcmp($a, $b); } @_; }

standard use of user's function in I<sort>. Hashes would be simply
sorted

	@sorted = sort { czcmp($hash{$a}, $hash{$b}) }
						keys %hash;


Both I<czcmp> and I<czsort> are exported into caller's namespace
by default, as well as I<cscmp> and I<cssort> that are just aliases.

This module comes with encoding table prepared for ISO-8859-2
(Latin-2) encoding. If your data come in different one, you might
want to check the module B<Cstocs> which can be used for reencoding
of the list's data prior to calling I<czsort>, or reencode this
module to fit your needs. 

=head1 VERSION

0.68

=head1 SEE ALSO

perl(1), Cz::Cstocs(3).

=head1 AUTHOR

(c) 1997--2000 Jan Pazdziora <adelton@fi.muni.cz>,
http://www.fi.muni.cz/~adelton/

at Faculty of Informatics, Masaryk University, Brno

=cut

