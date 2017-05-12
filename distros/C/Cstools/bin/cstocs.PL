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

cstocs -- charset encoding convertor for the Czech and Slovak languages.

=head1 FORMAT

	cstocs [options] src_encoding dst_encoding [files ...]

=head1 SYNOPSIS

	cstocs il2 ascii < file | less
	cstocs -i utf8 il2 file1 file2 file3
	cstocs --help

=head1 DESCRIPTION

Cstocs is a simple conversion utility to change charset encoding of
a text. It reads either specified files or (if none specified) the
standard input, assumes that the input is encoded in C<src_encoding>
and ties to reencode it into C<dst_encoding>. The result is written to
the standard output.

Run C<cstocs> without parameters to get short help and list of
available encodings.

Characters that are not defined in C<src_encoding> are passed to the
output unchanged.

If source text contains character, that is defined in C<src_encoding>
but not in C<dst_encoding>, it can be handled several ways. For
example, character "e with caron" (symbol ecaron), and "d with caron"
(symbol dcaron)  are included in the iso-8859-2 encoding, but not in
the iso-8859-1. If you will do reencoding of 8859-2 text to 8859-1,
you may want to do one of the following actions:

=over 3

=item 1.

Keep it the same, option C<--nofillstring>.

=item 2.

Do not produce any output instead of "ecaron" symbol, option C<--null>.

=item 3.

Substitute some string (possibly a space) instead of both ecaron and
dcaron, options C<--fillstring>.

=item 4.

Substitute a letter "d" instead of dcaron, and "e" instead of ecaron.
It is even possible to substitute string instead of symbol, so you can
replace the "AE" Latin character with string "AE" (letter "A", and
letter "E").  Or you can replace a "plusminus sign" with a string
"+/-".  These substitutions are described in the F<accent> file.

=back

=head1 OPTIONS

=over 4

=item -i, -i.ext, --inplace.ext

Files specified will be converted in-place, using Perl C<-i> facility.
Optionaly, an extension for backup copies may be specified after dot.
This parameter B<has> to be the first one, if specified.

=item --dir directory

Encoding files are taken from F<directory> instead of the default,
which is F<Cz/Cstocs/enc> in the Perl lib tree. The location of encoding
files can also be changed using the I<CSTOCSDIR> environment variable,
but the --dir option has the highest priority.

=item --fillstring string

If source text contains character, that is defined in the
C<src_encoding> but not in the C<dst_encoding> nor in the F<accent>
file (or F<accent> file is not used), it is replaced by C<string>.
The default is single space.

=item --nofillstring

Disable changes of characters that would otherwise have fillstring
applied. This is different from C<--null> because that cancels that
character out.

=item --null

Completely equivalent to --fillstring "".

=item --nochange or --noaccent

Do not use the F<accent> file at all.

=item --onebyone

Use only those rules from the F<accent> file, which rewrite one
character to one character. If this option is specified, character
"ecaron" will be rewritten to "e", but "AE" character will not be
rewritten to "AE" string.

=item --onebymore

Use all rules from accent file. This is the default option.

=back

=head1 SEE ALSO

Cz::Cstocs(3).

=head1 AUTHOR

Jan "Yenya" Kasprzak has done the original Un*x implementation.

Jan Pazdziora, adelton@fi.muni.cz, created the Perl module version.

=cut

BEGIN {
	if ($ARGV[0] =~ /^--?i(npl)?.*?(\..+?$)?$/) {
		my $ext = '';
		$ext = $2 if defined $2;
		shift @ARGV;
		### print STDERR "Running: $^X -i$ext -- $0 @ARGV\n";
		exec $^X, "-i$ext", '--', $0, @ARGV;
		die "Exec of perl $^X for inplace substitution failed.\n";
	}
}

use Cz::Cstocs;
use Cz::Cstocs::Getopt;

my $convert = Cz::Cstocs::Getopt::process_argv;

if (not defined $convert) {
	print STDERR $@;
	exit(1);
}

while (<>) {
	print &$convert($_);
}

EOBODY
