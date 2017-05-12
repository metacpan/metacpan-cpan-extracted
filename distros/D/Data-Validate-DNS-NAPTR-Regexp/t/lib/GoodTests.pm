package GoodTests;

use strict;
use warnings;

# <master-file-format-regexp>\t(1 or more)<return code><\s+>#<comment>

my @good = split(/\n/, <<'EOF');
^t\097est^test^			3 # \d\d\d escapes
^t\097^test^			3 # ...
^t\098ah^test^			3 # ...
^test^\097^			3 # ...
^test^\098a^			3 # ...
^test\^bob^			3 # Literal escape of delimiter
^test^bob^i			3 # Normal
^test(cat)^bob\\1^		3 # Backref
!bird(cat)(dog)!bob\\2\\1!	3 # More backrefs
!bird(cat)(dog)!bob\\1!		3 # ...
^test\\^this^cat\\^dog^i	3 # Escaped delimiters ignored
:test:nonsense:			3 # Different delim
^((){10}){10}/^cat^		3 # More complex regex
^test(cat)^\\\\9^		3 # Escaped escape, not backref
\^test(cat)^bird^		3 # Escaped char, not a \ delimiter
 test(cat) bird\\1 i		3 # Space as delim
\097beh\097meh\097i		3 # Escape sequence translated to proper byte 
£what£hi£i			3 # Weird characters allowed
^what£what£^£what£hi£i^i	3 # Weird characters allowed
^what\"the\"^hi^		3 # Quotes allowed if escaped
^what\\\"the\\\"^hi^		3 # Quotes with literal escapes before
EOF

push @good, '^' . ('x' x 250) . '^34^' . "\t" . '3 # Max length';

push @good, '^' . ('x' x 249) . '\\012' . '^34^' . "\t" . '3 # Max length with escapes';

# Empty
push @good, '' . "\t" . "2 # Empty regex";

my @ret;

for my $g (@good) {
	my ($test, $ret, $comment) = $g =~ /(^.*?)\t+(\d+)\s+#\s+(.*)$/;

	unless (defined $ret) {
		die "Couldn't parse $g\n";
	}

	push @ret, [$test, $ret, $comment];
}

# Undef
push @good, [undef(), 1, 'Undef regex'];

sub tests {
	return @ret;
}
