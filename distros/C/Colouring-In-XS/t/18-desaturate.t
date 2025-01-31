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
		expected => [60, 60, 60],
		amount => 100
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = desaturate($args{colour}, $args{amount});
	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
