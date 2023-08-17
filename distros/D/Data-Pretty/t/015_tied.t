#!perl -w

use strict;
use warnings;
use lib './lib';
use vars qw( $DEBUG );
$DEBUG = exists( $ENV{AUTHOR_TESTING} ) ? $ENV{AUTHOR_TESTING} : 0;
# use Test::More qw(plan ok);
use Test::More;
use Data::Pretty qw(dump);
local $Data::Pretty::DEBUG = $DEBUG;

plan tests => 4;

{
    package MyTie;

    sub TIE {
	my $class = shift;
	bless {}, $class;
    }

    use vars qw(*TIEHASH *TIEARRAY *TIESCALAR);
    *TIEHASH = \&TIE;
    *TIEARRAY = \&TIE;
    *TIESCALAR = \&TIE;

    sub FIRSTKEY {
	return "a";
    }

    sub NEXTKEY {
	my($self, $lastkey) = @_;
	return if $lastkey eq "d";
	return ++$lastkey;
    }

    sub FETCHSIZE {
	return 4;
    }

    sub FETCH {
	my($self, $key) = @_;
	return "v$key" if defined $key;
	return "v";
    }
}

my(%hash, @array, $scalar);
tie %hash, "MyTie";
tie @array, "MyTie";
tie $scalar, "MyTie";

is(nl(dump(\%hash)), <<EOT);
{
    # tied MyTie
    a => "va",
    b => "vb",
    c => "vc",
    d => "vd",
}
EOT

is(nl(dump(\@array)), <<EOT);
[
    # tied MyTie
    "v0" .. "v3",
]
EOT

is(nl(dump($scalar)), <<EOT);
"v"
EOT

is(nl(dump($scalar, $scalar, $scalar)), <<EOT, 'list of values dumped');
qw( v v v )
EOT

sub nl { shift(@_) . "\n" }
