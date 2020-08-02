package main;

use 5.008;

use strict;
use warnings;

use Test::More 0.88;	# Because of done_testing();

use lib qw{ inc };
use My::Module::Test::App;	# For environment clean-up.

use Astro::App::Satpass2;
use Cwd qw{ abs_path };

my $sp = Astro::App::Satpass2->new();

my $scalar = <<'EOD';
There was a young lady named Bright
Who could travel much faster than light.
    She set out one day
    In a relative way
And returned the previous night.
EOD

my @array = split qr{ (?<= \n ) }smx, $scalar;

my $code;
{
    my $inx = 0;
    $code = sub { return $array[$inx++] };

    sub _reset_code {
	$inx = 0;
    }
}

is $sp->_file_reader( 't/source.dat' )->(), "# This is a comment\n",
    'Reader for t/source.dat';

is $sp->_file_reader( 't/source.dat', { glob => 1 } ), <<'EOD',
# This is a comment
echo $@
EOD
    'Glob of t/source.dat';

SKIP: {

    my $tests = 2;

    open my $fh, '<', 't/source.dat'
	or skip "Unable to open t/source.dat: $!", $tests;

    is $sp->_file_reader( $fh )->(), "# This is a comment\n",
    'Reader for open filehandle';

    seek $fh, 0, 0;

    is $sp->_file_reader( $fh, { glob => 1 } ), <<'EOD',
# This is a comment
echo $@
EOD
	'Glob of open filehandle';

}


SKIP: {

    my $tests = 3;

    load_or_skip( 'LWP::UserAgent', $tests );
    load_or_skip( 'LWP::Protocol', $tests );
    load_or_skip( 'URI', $tests );

    my $url = abs_path( 't/source.dat' );
    $url =~ s/ : /|/smx;

    is $sp->_file_reader( "file://$url" )->(), "# This is a comment\n",
	"Reader for file://$url";

    is $sp->_file_reader( "file://$url", { glob => 1 } ), <<'EOD',
# This is a comment
echo $@
EOD
	"Glob of file://$url";

    eval {
	$sp->_file_reader( "fubar://$url" )->();
	1;
    }
	and fail "Reader for fubar://$url should have thrown an exception"
	or like $@, qr{ \A \QFailed to open fubar:\E }smx,
	    "Reader for fubar://$url generated expected exception";

}

is $sp->_file_reader( \$scalar )->(),
    "There was a young lady named Bright\n",
    'Reader for scalar reference';

is $sp->_file_reader( \$scalar, { glob => 1 } ), $scalar,
    'Glob of scalar reference';

is $sp->_file_reader( \@array )->(),
    "There was a young lady named Bright\n",
    'Reader for array reference';

is $sp->_file_reader( \@array, { glob => 1 } ), $scalar,
    'Glob of array reference';

is $sp->_file_reader( $code )->(),
    "There was a young lady named Bright\n",
    'Reader for code reference';

_reset_code();

is $sp->_file_reader( $code, { glob => 1 } ), $scalar,
    'Glob of code reference';

done_testing;

1;

# ex: set textwidth=72 :
