
# Chart::Color::Store :  expandable store of color sets

use v5.12;

package Chart::Color::Scheme;

use use Chart::Color::Named;

my %keys = ( background   => '',
             misc         => '',
             text         => '',
             x_label      => '',
             x_label2     => '',
             y_label      => '',
             y_label2     => '',
             x_grid_lines => '',
             y_grid_lines => '',
             dataset      => []);

my %scheme = ( 
    'default' => {
        background    => 'white',
        misc          => 'black',
        text          => 'black',
        x_label       => 'black',
        x_label2      => 'black',
        y_label       => 'black',
        y_label2      => 'black',
        x_grid_lines  => 'black',
        y_grid_lines  => 'black',
        dataset       => [ qw (red green blue purple peach orange mauve olive pink light_purple light_blue
            plum yellow turquoise light_green brown HotPink PaleGreen1 DarkBlue BlueViolet orange2 
            chocolate1 LightGreen pink light_purple light_blue plum yellow turquoise light_green brown pink
            PaleGreen2 MediumPurple PeachPuff1 orange3 chocolate2 olive pink light_purple light_blue plum 
            yellow turquoise light_green brown DarkOrange PaleGreen3 SlateBlue BlueViolet PeachPuff2 orange4
            chocolate3 LightGreen pink light_purple light_blue plum yellow turquoise light_green brown snow1
            honeydew3 SkyBlue1 cyan3 DarkOliveGreen1 IndianRed3 orange1 LightPink3 MediumPurple1 snow3
            LavenderBlush1 SkyBlue3 DarkSlateGray1 DarkOliveGreen3 sienna1 orange3 PaleVioletRed1 MediumPurple3
            seashell1 LavenderBlush3 LightSkyBlue1 DarkSlateGray3 khaki1 sienna3 DarkOrange1 PaleVioletRed3
            thistle1 seashell3 MistyRose1 LightSkyBlue3 aquamarine1 khaki3 burlywood1 DarkOrange3 maroon1
            thistle3 AntiqueWhite1 MistyRose3 SlateGray1 aquamarine3 LightGoldenrod1 burlywood3 coral1 maroon3
            AntiqueWhite3 azure1 SlateGray3 DarkSeaGreen1 LightGoldenrod3 wheat1 coral3 VioletRed1 bisque1
            azure3 LightSteelBlue1 DarkSeaGreen3 LightYellow1 wheat3 tomato1 VioletRed3 bisque3 SlateBlue1
            LightSteelBlue3 SeaGreen1 LightYellow3 tan1 tomato3 magenta1 PeachPuff1 SlateBlue3 LightBlue1
            SeaGreen3 yellow1 tan3 OrangeRed1 magenta3 PeachPuff3 RoyalBlue1 LightBlue3 PaleGreen1 yellow3
            chocolate1 OrangeRed3 orchid1 NavajoWhite1 RoyalBlue3 LightCyan1 PaleGreen3 gold1 chocolate3
            red1 orchid3 NavajoWhite3 blue1 LightCyan3 SpringGreen1 gold3 firebrick1 red3 plum1 LemonChiffon1
            blue3 PaleTurquoise1 SpringGreen3 goldenrod1 firebrick3 DeepPink1 plum3 LemonChiffon3 DodgerBlue1
            PaleTurquoise3 green1 goldenrod3 brown1 DeepPink3 MediumOrchid1 cornsilk1 DodgerBlue3 CadetBlue1
            green3 DarkGoldenrod1 brown3 HotPink1 MediumOrchid3 cornsilk3 SteelBlue1 CadetBlue3 chartreuse1
            DarkGoldenrod3 salmon1 HotPink3 DarkOrchid1 ivory1 SteelBlue3 turquoise1 chartreuse3 RosyBrown1
            salmon3 pink1 DarkOrchid3 ivory3 DeepSkyBlue1 turquoise3 OliveDrab1 RosyBrown3 LightSalmon1 pink3
            purple1 honeydew1 DeepSkyBlue3 cyan1 OliveDrab3 IndianRed1 LightSalmon3 LightPink1 purple3 honeydew2
            DeepSkyBlue4 cyan2 OliveDrab4 IndianRed2 LightSalmon4 LightPink2 purple4 snow2 honeydew4 SkyBlue2
            cyan4 DarkOliveGreen2 IndianRed4 orange2 LightPink4 MediumPurple2 snow4 LavenderBlush2 SkyBlue4
            DarkSlateGray2 DarkOliveGreen4 sienna2 orange4 PaleVioletRed2 MediumPurple4 seashell2 LavenderBlush4
            LightSkyBlue2 DarkSlateGray4 khaki2 sienna4 DarkOrange2 PaleVioletRed4 thistle2 seashell4 MistyRose2
            LightSkyBlue4 aquamarine2 khaki4 burlywood2 DarkOrange4 maroon2 thistle4 AntiqueWhite2 MistyRose4
            SlateGray2 aquamarine4 LightGoldenrod2 burlywood4 coral2 maroon4 AntiqueWhite4 azure2 SlateGray4
            DarkSeaGreen2 LightGoldenrod4 wheat2 coral4 VioletRed2 bisque2 azure4 LightSteelBlue2 DarkSeaGreen4
            LightYellow2 wheat4 tomato2 VioletRed4 bisque4 SlateBlue2 LightSteelBlue4 SeaGreen2 LightYellow4 tan2
            tomato4 magenta2 PeachPuff2 SlateBlue4 LightBlue2 SeaGreen4 yellow2 tan4 OrangeRed2 magenta4 PeachPuff4
            RoyalBlue2 LightBlue4 PaleGreen2 yellow4 chocolate2 OrangeRed4 orchid2 NavajoWhite2 RoyalBlue4
            LightCyan2 PaleGreen4 gold2 chocolate4 red2 orchid4 NavajoWhite4 blue2 LightCyan4 SpringGreen2 gold4
            firebrick2 red4 plum2 LemonChiffon2 blue4 PaleTurquoise2 SpringGreen4 goldenrod2 firebrick4 DeepPink2
            plum4 LemonChiffon4 DodgerBlue2 PaleTurquoise4 green2 goldenrod4 brown2 DeepPink4 MediumOrchid2
            cornsilk2 DodgerBlue4 CadetBlue2 green4 DarkGoldenrod2 brown4 HotPink2 MediumOrchid4 cornsilk4
            SteelBlue2 CadetBlue4 chartreuse2 DarkGoldenrod4 salmon2 HotPink4 DarkOrchid2 ivory2 SteelBlue4
            turquoise2 chartreuse4 RosyBrown2 salmon4 pink2 DarkOrchid4 ivory4 DeepSkyBlue2 turquoise4 OliveDrab2
            RosyBrown4 LightSalmon2 pink4 purple2)] },
);




sub all_names  { keys %set }
sub name_taken { exists  %set{$_[0]} }

sub add {
    my $name = shift;
    my $my_scheme  = shift;
    return "Color scheme name missing" unless defined $name and $name;
    return "Color scheme already exists" if exists $scheme{$name};
    return "Color scheme has to be a Hash" if ref $val ne 'HASH';
    for my $k (keys %$val){
        return "$k is not a valid key of an color set" unless exists $scheme{'default'}{$k}
    }
    for my $k (keys %{$scheme{'default'}}){
        $my_set->{$k} = $scheme{'default'}{$k} unless exists $my_scheme->{$k};
    }

## check all color, whole data set
#    return "Need a Color value (ArrayRef to 3 Int < 256)" if ref $val ne 'ARRAY' or @$val != 3;
    my $ret = Color->new(@$val);
    return $ret unless ref $ret;
    $scheme{$name} = $my_set;
}

sub get { $scheme{$_[0]} if exists $scheme{$_[0]} }


1;


