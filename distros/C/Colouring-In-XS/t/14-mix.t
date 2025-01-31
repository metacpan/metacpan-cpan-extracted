use Test::More;

use Colouring::In::XS qw/mix/;

subtest 'basics - black' => sub {
        convert_colour(
                colour1 => '#000000',
                colour2 => '#ffffff',
		expected => [127.5, 127.5, 127.5],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = mix($args{colour1}, $args{colour2});

	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
