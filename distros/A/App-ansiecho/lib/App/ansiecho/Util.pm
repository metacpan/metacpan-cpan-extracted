package App::ansiecho;
use v5.14;
use warnings;

use charnames ':full';

sub make_options {
    map {
	# "foo_bar" -> "foo_bar|foo-bar|foobar"
	s{^(?=\w+_)(\w+)\K}{
	    "|" . $1 =~ tr[_][-]r . "|" . $1 =~ tr[_][]dr
	}er;
    }
    grep {
	s/#.*//;
	s/\s+//g;
	/\S/;
    }
    map { split /\n+/ }
    @_;
}

sub safe_backslash {
    $_[0] =~ s{
	( \\ x\{[0-9a-f]+\}
	| \\ x[0-9a-f]{2}
	| \\ N\{[\ \w]+\}
	| \\ N\{U\+[0-9a-f]+\}
	| \\ c.
	| \\ o\{\d+\}
	| \\ \d\d\d
	| \\ .
        )
    }{ eval qq["$1"] or die "$1 : string error.\n"}xiger;
}

1;
