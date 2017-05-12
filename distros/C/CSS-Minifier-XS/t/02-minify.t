use strict;
use warnings;
use IO::File;
use Test::More;
use CSS::Minifier::XS qw(minify);

###############################################################################
# figure out how many CSS files we're going to run through for testing
my @files = <t/css/*.css>;
plan tests => scalar @files;

###############################################################################
# test each of the CSS files in turn
foreach my $file (@files) {
    (my $min_file = $file) =~ s/\.css$/\.min/;
    my $str = slurp( $file );
    my $min = slurp( $min_file );
    my $res = minify( $str );
    is( $res, $min, $file );
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
