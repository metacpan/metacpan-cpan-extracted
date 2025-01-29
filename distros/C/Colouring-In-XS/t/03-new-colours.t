use Test::More;

use Colouring::In::XS;

subtest 'basics - black' => sub {
        new_colour_test(
                start => '#000000',
                expected => '#000',
        );
        
        new_colour_test(
                start => '#000',
                expected => '#000',
        );
        new_colour_test(
                expected => '#000',
                start => 'hsl(10,0%,0%)',
        );  
        
        new_colour_test(
                expected => '#000',
                start => 'rgb(0,0,0)',
        );   
        
	new_colour_test(
                expected => '#000',
                start => 'rgba(0,0,0,1)',
        );

        new_colour_test(
                expected => '#000',
                start => 'hsla(0, 0%, 0%, 1)',
        );
};

sub new_colour_test {
        my %args = @_;
        my $colour = Colouring::In::XS->new($args{start});

        is($colour->toCSS, $args{expected}, '*\o/* success');
}

done_testing();

1;
