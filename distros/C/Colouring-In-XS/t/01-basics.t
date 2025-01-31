use Test::More;

use Colouring::In::XS;

subtest 'basics' => sub {
        basic_tests(
                start => '#ffffff',
                toCSS => '#fff',
                toHSL => 'hsl(0,0%,100%)',
                toHSV => 'hsv(0,0%,100%)',
                toHEX => '#fff',
                toHEXfull => '#ffffff',
                toRGB => 'rgb(255,255,255)',
                toRGBA => 'rgba(255,255,255,1)',
       		toTerm => 'r255g255b255',
       		toOnTerm => 'on_r255g255b255'
	);
        basic_tests(
                start => '#000000',
                toCSS => '#000',
                toHSL => 'hsl(0,0%,0%)',
                toHSV => 'hsv(0,0%,0%)',
                toHEX => '#000',
                toHEXfull => '#000000',
                toRGB => 'rgb(0,0,0)',
                toRGBA => 'rgba(0,0,0,1)',
		toTerm => 'r0g0b0',
		toOnTerm => 'on_r0g0b0'
	);
        basic_tests(
                start => [ '255', '0', '0' ],
                toCSS => '#f00',
                toHSL => 'hsl(0,100%,50%)',
                toHSV => 'hsv(0,100%,100%)',
                toHEX => '#f00',
                toHEXfull => '#ff0000',
                toRGB => 'rgb(255,0,0)',
                toRGBA => 'rgba(255,0,0,1)',
		toTerm => 'r255g0b0',
		toOnTerm => 'on_r255g0b0'
	);
	basic_tests(
                start => [ '255', '0', '0' ],
                toCSS => '#f00',
                toHSL => 'hsl(0,100%,50%)',
                toHSV => 'hsv(0,100%,100%)',
                toHEX => '#f00',
                toHEXfull => '#ff0000',
                toRGB => 'rgb(255,0,0)',
                toRGBA => 'rgba(255,0,0,1)',
		toTerm => 'r255g0b0',
		toOnTerm => 'on_r255g0b0'
	);   
        basic_tests(
                start => [ '255', '0', '0' ],
                toCSS => '#f00',
                toHSL => 'hsl(0,100%,50%)',
                toHSV => 'hsv(0,100%,100%)',
                toHEX => '#f00',
                toHEXfull => '#ff0000',
                toRGB => 'rgb(255,0,0)',
                toRGBA => 'rgba(255,0,0,1)',
		toTerm => 'r255g0b0',
		toOnTerm => 'on_r255g0b0'
	);
};       

sub basic_tests {
        my %args = @_;
        my $color = Colouring::In::XS->new($args{start});

        is($color->toCSS, $args{toCSS}, "$args{toCSS}");
    
        is($color->toHEX, $args{toHEX}, "$args{toHEX}");
        is($color->toHEX(1), $args{toHEXfull}, "$args{toHEXfull}");
  
        is($color->toHSL, $args{toHSL}, "$args{toHSL}");
        
	is($color->toHSV, $args{toHSV}, "$args{toHSV}");
        
	is($color->toRGB, $args{toRGB}, "$args{toRGB}");
	
	is($color->toRGBA(1), $args{toRGBA}, "$args{toRGBA}");

        is($color->toTerm, $args{toTerm}, "$args{toTerm}");
        is($color->toOnTerm, $args{toOnTerm}, "$args{toTerm}");

}

done_testing();

1;
