use Test::Base;

plan tests => 1 * blocks;

use FindBin;
use File::Spec;

use Data::AMF;

my $amf = Data::AMF->new( version => 3 );

sub serialize {
    $amf->serialize($_[0]->{data});
}

sub load {
    my $file = File::Spec->catfile( $FindBin::Bin, $_[0] );
    open my $fh, "<$file";
    my $data = do { local $/; <$fh> };
    close $fh;

    $data;
}

filters {
    input => [qw/yaml serialize/],
    expected => 'load',
};

run_compare;

__DATA__

=== null object
--- input
data: {}
--- expected: data/amf3/null_object

=== number with double precision
--- input
data: 123.45
--- expected: data/amf3/number
