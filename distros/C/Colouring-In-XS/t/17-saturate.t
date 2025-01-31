use Test::More;

use Colouring::In::XS qw/saturate/;

subtest 'basics - black' => sub {
        convert_colour(
                colour => 'rgb(100, 100, 100)',
		expected => [150, 49, 49],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = saturate($args{colour}, 50);
	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
