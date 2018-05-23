use 5.010001;
use strict;
use warnings;

package CleanEnv;

# Tiny equivalent of Devel::Hide to disable BSON::PP.  This is probably
# unnecessary but ensures that there isn't a fallback we don't notice.
use lib map {
    my ( $m, $c ) = ( $_, qq{die "Can't locate $_ (hidden)\n"} );
    sub { return unless $_[1] eq $m; open my $fh, "<", \$c; return $fh }
} qw{BSON/PP.pm};

# Keep environment from interfering with tests
$ENV{PERL_BSON_BACKEND} = "";

1;
