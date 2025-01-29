use Test::More;

use Colouring::In::XS qw/fade/;

subtest 'basics - white' => sub {
        convert_colour(
                start => '#ffffff',
                fade => '100%',
		expected => 'rgba(255,255,255,1)',
	);
        convert_colour(
                start => '#ffffff',
                fade => '99%',
				expected => 'rgba(255,255,255,0.99)',
		);
		convert_colour(
                start => '#ffffff',
                fade => '90%',
				expected => 'rgba(255,255,255,0.9)',
		);
		convert_colour(
                start => '#ffffff',
                fade => '80%',
				expected => 'rgba(255,255,255,0.8)',
        );
		convert_colour(
                start => '#ffffff',
                fade => '70%',
				expected => 'rgba(255,255,255,0.7)',
        );
		convert_colour(
                start => '#ffffff',
                fade => '60%',
				expected => 'rgba(255,255,255,0.6)',
        );
		convert_colour(
                start => '#ffffff',
                fade => '50%',
				expected => 'rgba(255,255,255,0.5)',
        );
		convert_colour(
                start => '#ffffff',
                fade => '40%',
				expected => 'rgba(255,255,255,0.4)',
        );
   		convert_colour(
                start => '#ffffff',
                fade => '30%',
				expected => 'rgba(255,255,255,0.3)',
        );
     	convert_colour(
                start => '#ffffff',
                fade => '20%',
				expected => 'rgba(255,255,255,0.2)',
        );
 		convert_colour(
                start => '#ffffff',
                fade => '10%',
				expected => 'rgba(255,255,255,0.1)',
        );
		convert_colour(
                start => '#ffffff',
                fade => '0%',
				expected => 'rgba(255,255,255,0)',
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = fade($args{start}, $args{fade});
	is($colour->toRGBA, $args{expected}, $args{expected});
}

done_testing();

1;
