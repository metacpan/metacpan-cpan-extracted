use Test::More;

use Colouring::In::XS qw/lighten/;

subtest 'basics - black' => sub {
        convert_colour(
                start => '#000000',
                light => '10%',
		expected => [25, 25, 25],
        );
	convert_colour(
                start => '#000000',
                light => '30%',
		expected => [76, 76, 76],
        );
	convert_colour(
                start => '#000000',
                light => '50%',
		expected => [127, 127, 127],
        );
   	convert_colour(
                start => '#000000',
                light => '70%',
		expected => [178, 178, 178],
        );
 	convert_colour(
                start => '#000000',
                light => '90%',
		expected => [229, 229, 229],
        );
     	convert_colour(
                start => '#000000',
                light => '100%',
		expected => [255, 255, 255],
        );
     	convert_colour(
                start => '#000000',
                light => '200%',
		expected => [255, 255, 255],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = lighten($args{start}, $args{light});
	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
