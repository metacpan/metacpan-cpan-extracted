use strict;
use warnings;
use Test::More;
use IO::File;
use Benchmark qw(countit);
use CSS::Minifier::XS;

###############################################################################
# check if CSS::Minifier available, so we can do a benchmark comparison
eval { require CSS::Minifier };
if ($@) {
    plan skip_all => 'CSS::Minifier not available for benchmark comparison';
}
plan tests => 1;

###############################################################################
# get the list of CSS files we're going to run through for testing
my @files = <t/css/*.css>;

###############################################################################
# time test the PurePerl version against the XS version.
compare_benchmark: {
    my $count;
    my $time = 10;

    # build a longer CSS document to process; 64KBytes should be suitable
    my $str = '';
    while (1) {
        foreach my $file (@files) {
            $str .= slurp( $file );
        }
        last if (length($str) > (64*1024));
    }

    # benchmark the original "pure perl" version
    $count = countit( $time, sub { CSS::Minifier::minify(input=>$str) } );
    my $rate_pp = ($count->iters() / $time) * length($str);

    # benchmark the "XS" version
    $count = countit( $time, sub { CSS::Minifier::XS::minify($str) } );
    my $rate_xs = ($count->iters() / $time) * length($str);

    ok( 1, "benchmarking" );
    diag( "" );
    diag( "Benchmark results:" );
    diag( "\tperl\t=> $rate_pp bytes/sec" );
    diag( "\txs\t=> $rate_xs bytes/sec" );
}





###############################################################################
# HELPER METHOD: slurp in contents of file to scalar.
###############################################################################
sub slurp {
    my $filename = shift;
    my $fin = IO::File->new( $filename, '<' ) || die "can't open '$filename'; $!";
    my $str = join('', <$fin>);
    $fin->close();
    chomp( $str );
    return $str;
}
