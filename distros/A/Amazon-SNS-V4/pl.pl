        use Parse::LocalDistribution;

        my $parser = Parse::LocalDistribution->new({ALLOW_DEV_VERSION => 0});
        my $provides = $parser->parse('.');

use Data::Dumper;
print Dumper( $provides );
