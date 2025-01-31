use Test::More;

use Colouring::In::XS qw/shade/;

subtest 'basics - black' => sub {
        convert_colour(
                colour => '#ffffff',
		expected => [127.5, 127.5, 127.5],
        );
};   

sub convert_colour {
        my %args = @_;
        
        my $colour = shade($args{colour});

	is_deeply([$colour->colour], $args{expected}, "expected colour!"); 
}

done_testing();

1;
