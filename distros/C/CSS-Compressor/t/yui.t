
our @files;

use FindBin;

BEGIN { @files = grep +( !m! \b dataurl-base64-linebreakindata.css \E\b !x ), glob "$FindBin::Bin/yui/*.css" }

use Test::Differences;
use Test::More
    tests => 1 + @files;

BEGIN {
    use_ok( 'CSS::Compressor' => qw( css_compress ) );
}

diag "yui test files: @files\n";

for my $file ( @files ) {
    die "$!: $file.min"
        unless open my $fh => '<' => $file;
    my $source = do { local $/; <$fh> };
    close $fh;

    die "$!: $file.min"
        unless open $fh => '<' => $file.'.min';
    my $target = do { local $/; <$fh> };
    close $fh;

    my $result = css_compress( $source );

    # make diffs readable
    s!([{;])!$1\n!smg,
    s!([}])!\n$1!smg
        for $result, $target;

    my ( $name ) = $file =~ m!([^/]+)\z!;

    eq_or_diff $result => $target => "css_compress($name) == $name.min";
}
