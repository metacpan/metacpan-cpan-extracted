use Test::More;

use Colouring::In::XS qw/greyscale/;

subtest 'basics - black' => sub {
	 convert_colour(
                colour => 'rgb(0, 120, 120)',
		expected => [60, 60, 60],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = greyscale($args{colour});
	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
