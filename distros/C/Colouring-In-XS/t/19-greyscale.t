use Test::More;

use Colouring::In::XS qw/greyscale/;

subtest 'basics - black' => sub {
	convert_colour(
                colour => 'rgb(0, 120, 120)',
		expected => ['59|60', '59|60', '59|60'],
        );
	ok(1);
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = greyscale($args{colour});

	my @c = $colour->colour;	
	for (my $i = 0; $i < @c; $i++) {
		like($c[$i], qr/$args{expected}[$i]/, 'expected colour!');
	}
}

done_testing();

1;
