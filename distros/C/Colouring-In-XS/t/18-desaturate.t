use Test::More;

use Colouring::In::XS qw/desaturate/;

subtest 'basics - black' => sub {
        convert_colour(
                colour => 'rgb(0, 120, 120)',
		expected => [30, 89, 89],
		amount => 50
        );
	convert_colour(
                colour => 'rgb(0, 120, 120)',
		expected => ['59|60', '59|60', '59|60'],
		amount => 100
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = desaturate($args{colour}, $args{amount});

	my @c = $colour->colour;	
	for (my $i = 0; $i < @c; $i++) {
		like($c[$i], qr/$args{expected}[$i]/, 'expected colour!');
	}
}

done_testing();

1;
