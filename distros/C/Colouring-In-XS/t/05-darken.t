use Test::More;

use Colouring::In::XS qw/darken/;

subtest 'basics - black' => sub {
        convert_colour(
                start => '#ffffff',
                dark => '100%',
		expected => [0, 0, 0],
        );
        convert_colour(
                start => '#ffffff',
                dark => '90%',
		expected => [25, 25, 25],
        );
	convert_colour(
                start => '#ffffff',
                dark => '70%',
		expected => [76, 76, 76],
        );
	convert_colour(
                start => '#ffffff',
                dark => '60%',
		expected => [102, 102, 102],
        );
	convert_colour(
                start => '#ffffff',
                dark => '50%',
		expected => [127, 127, 127],
        );
	convert_colour(
                start => '#ffffff',
                dark => '40%',
		expected => [153, 153, 153],
        );
   	convert_colour(
                start => '#ffffff',
                dark => '30%',
		expected => [178, 178, 178],
        );
     	convert_colour(
                start => '#ffffff',
                dark => '20%',
		expected => [204, 204, 204],
        );
 	convert_colour(
                start => '#ffffff',
                dark => '10%',
		expected => [229, 229, 229],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = darken($args{start}, $args{dark});
		is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
