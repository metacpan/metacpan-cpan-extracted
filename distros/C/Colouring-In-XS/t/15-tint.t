use Test::More;

use Colouring::In::XS qw/tint/;

subtest 'basics - black' => sub {
        convert_colour(
                colour => '#000000',
		expected => [127.5, 127.5, 127.5],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = tint($args{colour});

	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
