use Test::More;

use Colouring::In;

subtest 'basics - white' => sub {
       convert_colour(
                start => '#ffffff',
                expected => [255, 255, 255],
        );

        convert_colour(
                expected => [255, 255, 255],
                start => '#fff',
        );    

        convert_colour(
                expected => [255, 255, 255],
                start => 'hsl(0,0%,100%)',
        );  
        
        convert_colour(
                expected => [255, 255, 255],
                start => 'rgb(255,255,255)',
        );   
        
        convert_colour(
                expected => [255, 255, 255, 1],
                start => 'rgba(255,255,255,1)',
        );

        convert_colour(
                expected => [255, 255, 255, 1],
                start => 'hsla(0,0%,100%, 1)',
        );
};       

subtest 'basics - black' => sub {
        convert_colour(
                start => '#000000',
                expected => [0, 0, 0],
        );
        
        convert_colour(
                start => '#000',
                expected => [0, 0, 0],
        );

        convert_colour(
                expected => [0, 0, 0],
                start => 'hsl(0,0%,0%)',
        );  
        
        convert_colour(
                expected => [0, 0, 0],
                start => 'rgb(0,0,0)',
        );   
        
        convert_colour(
                expected => [0,0,0,1],
                start => 'rgba(0,0,0,1)',
        );

        convert_colour(
                expected => [0, 0, 0, 1],
                start => 'hsla(0, 0%, 0%, 1)',
        );
};   

subtest 'basics - red' => sub {
        convert_colour(
                start => '#ff0000',
                expected => [255, 0, 0],
        );
        
        convert_colour(
                start => '#f00',
                expected => [255, 0, 0],
        );

        convert_colour(
                expected => [255, 0, 0],
                start => 'hsl(0,100%,50%)',
        );  
        
        convert_colour(
                expected => [255, 0, 0],
                start => 'rgb(255,0,0)',
        );   
 
        convert_colour(
                expected => [255, 0, 0, 1],
                start => 'hsla(0, 100%, 50%, 1)',
        );
       
        convert_colour(
                expected => [255,0,0,1],
                start => 'rgba(255,0,0,1)',
        );
};

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
                start => 'hsl(0,0%,0%)',
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

sub convert_colour {
        my %args = @_;
        
        my @rgb = Colouring::In::TOOL->{convertColour}->($args{start});
        is_deeply(\@rgb, $args{expected}, "expected colour!"); 
}

sub new_colour_test {
        my %args = @_;

        my $colour = Colouring::In->new($args{start});
        is($colour->toCSS, $args{expected}, '*\o/* success');
}

done_testing();

1;
