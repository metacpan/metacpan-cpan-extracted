package BadTests;

use strict;
use warnings;

# <master-file-format-regexp>\t(1 or more)<expected error>

my @bad = split(/\n/, <<'EOF');
^test^			/Bad syntax, missing replace\/end delimiter$/
^test^bob		/Bad syntax, missing replace\/end delimiter$/
^test^bob^i^i		/Extra delimiters$/
0test0bob0		/Delimiter \(0\) cannot be a flag, digit or null$/
1test1bob1		/Delimiter \(1\) cannot be a flag, digit or null$/
9test9bob9		/Delimiter \(9\) cannot be a flag, digit or null$/
itestibobi		/Delimiter \(i\) cannot be a flag, digit or null$/
\\test\\bob\\		/Delimiter \(\\\) cannot be a flag, digit or null$/
^test(cat)^bob\\2^	/More backrefs in replacement than captures in match$/
^test^bob^if		/Bad flag: f$/
^test^\\0^		/Bad backref '0'$/
^test\25a^bah^		/Bad escape sequence '\\25'$/
^test^\25b^		/Bad escape sequence '\\25'$/
^test\256b^bah^		/Escape sequence out of range '\\256'/
^test^bah\256a^		/Escape sequence out of range '\\256'/
^test^bah^\		/Trailing backslash/
\000test\000test\000	/Contains null bytes/
^test"hi"^meh^		/Unescaped double quote/
EOF

push @bad, '^' . ('x' x 250) . '^234^' . "\t" . '/Must be less than 256 bytes$/';

push @bad, '^\\012\\012' . ('x' x 250) . '^2^' . "\t" . '/Must be less than 256 bytes$/';

push @bad, "\0test\0test\0" . "\t" . '/Contains null bytes$/';

push @bad, "^test\nwhat^cat^" . "\t" . '/Contains new-lines/';

push @bad, "^testwhat^cat^\n" . "\t" . '/Contains new-lines/';

push @bad, "^testwhat^cat^ " . "\t" . "/Bad flag: \\s/";


my @ret;

for my $b (@bad) {
	my ($test, $expect) = $b =~ /(^.*?)\t+(.*)$/s;

	unless ($test && $expect) {
		die "Couldn't parse $b\n";
	}

	push @ret, [$test, $expect];
}

sub tests {
	return @ret;
}

1;
