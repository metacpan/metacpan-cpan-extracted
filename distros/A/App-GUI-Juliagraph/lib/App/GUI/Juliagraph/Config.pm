use v5.12;
use warnings;
use File::HomeDir;
use File::Spec;

package App::GUI::Juliagraph::Config;

my $file_name = File::Spec->catfile( File::HomeDir->my_home, '.config', 'juliagraph');

my $dir = '';
my $default = {
    file_base_dir => '~',
    file_base_ending => 'png',
    image_size => 600,
    open_dir => '~',
    save_dir => '~',
    write_dir => '~',
    last_settings => [],
    tips => 1,
    color_set => {
        grey => ['#FFF', '#DDD', '#BBB', '#999', '#777','#555', '#333', '#111' ],
        sunset => ['#FFF', '#F9E595', '#A1680C', '#B63A3E' ],
        basic  => ['#FFF', '#F00', '#0F0', '#00F', '#FF0', '#0FF', '#F0F','#000' ],
        dawn   => [ 'white', '#f9d87b', '#936d1a', '#bf3136', '#8f1416', '#99158b', '#1d1d7c', '#111111', 'black' ],
        day    => [ 'white', '#ffcf3d', '#e25555', '#e65c60', '#4acfab', '#48614a', 'gray20',  '#111111', 'black' ],
        skye   => [ 'white', '#ffcf3d', '#173fab', '#8e8e8e', '#8e8e8e', '#8e8e8e', '#8e8e8e', '#8e8e8e', 'black' ],
        sunset => [ 'white', '#f9d87b', '#936d1a', '#bf3136', '#94148e', '#c3baee', '#1d1d7c', '#111111', 'black' ],
    },
    color => {
        white            => [ 255, 255, 255],
        black            => [   0,   0,   0],
        red              => [ 255,   0,   0],
        green            => [   0, 128,   0],
        blue             => [   0,   0, 255],
        yellow           => [ 255, 255,   0],
        purple           => [ 128,   0, 128],
        pink             => [ 255, 192, 203],
        peach            => [ 250, 125, 125],
        plum             => [ 221, 160, 221],
        mauve            => [ 200, 125, 125],
        brown            => [ 165,  42,  42],
        grey             => [ 225, 225, 225],
        aliceblue        => [ 240, 248, 255],
        bright_blue      => [  98, 156, 249],
        marsala          => [ 149,  82,  81],
        radiandorchid    => [ 181, 101, 167],
        emerald          => [   0, 155, 119],
        tangerinetango   => [ 221,  65,  36],
        honeysucle       => [ 214,  80, 118],
        turquoise        => [  69, 184, 172],
        mimosa           => [ 239, 192,  80],
        blueizis         => [  91,  94, 166],
        chilipepper      => [ 155,  27,  48],
        sanddollar       => [ 223, 207, 190],
        blueturquoise    => [  85, 180, 176],
        tigerlily        => [ 225,  93,  68],
        aquasky          => [ 127, 205, 205],
        truered          => [ 188,  36,  60],
        fuchsiarose      => [ 195,  68, 122],
        ceruleanblue     => [ 152, 180, 212],
        rosequartz       => [ 247, 202, 201],
        peachecho        => [ 247, 120, 107],
        serenity         => [ 145, 168, 208],
        snorkelblue      => [   3,  79, 132],
        limpetshell      => [ 152, 221, 222],
        lilacgrey        => [ 152, 221, 222],
        icedcoffee       => [ 177, 143, 106],
        fiesta           => [ 221,  65,  50],
        buttercup        => [ 221,  65,  50],
        greenflash       => [ 250, 224,  60],
        riverside        => [  76, 106, 146],
        airyblue         => [ 146, 182, 213],
        sharkskin        => [ 131, 132, 135],
        aurorared        => [ 185,  58,  50],
        warmtaupe        => [ 175, 148, 131],
        dustycedar       => [ 173,  93,  93],
        lushmeadow       => [   0, 110,  81],
        spicymustard     => [ 216, 174,  71],
        pottersclay      => [ 158,  70,  36],
        bodacious        => [ 183, 107, 163],
        greenery         => [ 146, 181,  88],
        niagara          => [  87, 140, 169],
        primroseyellow   => [ 246, 209,  85],
        lapisblue        => [   0,  75, 141],
        flame            => [ 242,  85,  44],
        islandparadise   => [ 149, 222, 227],
        paledogwood      => [ 237, 205, 194],
        pinkyarrow       => [ 206,  49, 117],
        kale             => [  90, 114,  71],
        hazelnut         => [ 207, 176, 149],
        grenadine        => [ 220,  76,  70],
        balletslipper    => [ 243, 214, 228],
        butterum         => [ 196, 143, 101],
        navypeony        => [  34,  58,  94],
        neutralgray      => [ 137, 142, 140],
        shadedspruce     => [   0,  89,  96],
        goldenlime       => [ 156, 154,  64],
        marina           => [  79, 132, 196],
        autumnmaple      => [ 210, 105,  30],
        meadowlark       => [ 236, 219,  84],
        cherrytomato     => [ 233,  75,  60],
        littleboyblue    => [ 111, 159, 216],
        chilioil         => [ 148,  71,  67],
        pinklavender     => [ 219, 177, 205],
        bloomingdahlia   => [ 236, 151, 135],
        arcadia          => [   0, 165, 145],
        ultraviolet      => [ 107,  91, 149],
        emperador        => [ 108,  79,  61],
        almostmauve      => [ 234, 222, 219],
        springcrocus     => [ 188, 112, 164],
        sailorblue       => [  46,  74,  98],
        harbormist       => [ 180, 183, 186],
        warmsand         => [ 192, 171, 142],
        coconutmilk      => [ 240, 237, 229],
        redpear          => [ 127,  65,  69],
        valiantpoppy     => [ 189,  61,  58],
        nebulasblue      => [  63, 105, 170],
        ceylonyellow     => [ 213, 174,  65],
        martiniolive     => [ 118, 111,  87],
        russetorange     => [ 228, 122,  46],
        crocuspetal      => [ 190, 158, 201],
        limelight        => [ 241, 234, 127],
        quetzalgreen     => [   0, 110, 109],
        sargassosea      => [  72,  81, 103],
        tofu             => [ 234, 230, 218],
        almondbuff       => [ 209, 184, 148],
        quietgray        => [ 188, 188, 190],
        meerkat          => [ 169, 117,  79],
        fiesta           => [ 221,  65,  50],
        jesterred        => [ 158,  16,  48],
        turmeric         => [ 254, 132,  14],
        livingcoral      => [ 255, 111,  97],
        pinkpeacock      => [ 198,  33, 104],
        pepperstem       => [ 141, 148,  64],
        aspengold        => [ 255, 214,  98],
        princessblue     => [   0,  83, 156],
        toffee           => [ 117,  81,  57],
        mangomojito      => [ 214, 156,  47],
        terrariummoss    => [  97,  98,  71],
        sweetlilac       => [ 232, 181, 206],
        soybean          => [ 210, 194, 157],
        eclipse          => [  52,  49,  72],
        sweetcorn        => [ 240, 234, 214],
        browngranite     => [  97,  85,  80],
        chilipepper      => [ 155,  27,  48],
        bikingred        => [ 119,  33,  46],
        peachpink        => [ 250, 154, 133],
        rockyroad        => [  90,  62,  54],
        fruitdove        => [ 206,  91, 120],
        sugaralmond      => [ 147,  85,  41],
        darkcheddar      => [ 224, 129,  25],
        galaxyblue       => [  42,  75, 124],
        bluestone        => [  87, 114, 132],
        orangetiger      => [ 249, 103,  20],
        eden             => [  38,  78,  54],
        vanillacustard   => [ 243, 224, 190],
        eveningblue      => [  42,  41,  62],
        paloma           => [ 159, 156, 153],
        guacamole        => [ 121, 123,  58],
        flamescarlet     => [ 205,  33,  42],
        saffron          => [ 255, 165,   0],
        biscaygreen      => [  86, 198, 169],
        chive            => [  75,  83,  53],
        fadeddenim       => [ 121, 142, 164],
        orangepeel       => [ 250, 122,  53],
        mosaicblue       => [   0, 117, 143],
        sunlight         => [ 237, 213, 158],
        coralpink        => [ 232, 167, 152],
        grapecompote     => [ 107,  88, 118],
        lark             => [ 184, 155, 114],
        navyblazer       => [  40,  45,  60],
        brilliantwhite   => [ 237, 241, 255],
        ash              => [ 160, 153, 152],
        amberglow        => [ 220, 121,  62],
        samba            => [ 162,  36,  47],
        sandstone        => [ 196, 138, 105],
        classicblue      => [  52,  86, 139],
        greensheen       => [ 217, 206,  82],
        rosetan          => [ 209, 156, 151],
        ultramarinegreen => [   0, 107,  84],
        firedbrick       => [ 106,  46,  42],
        peachnougat      => [ 230, 175, 145],
        magentapurple    => [ 108,  36,  76],
        marigold         => [ 253, 172,  83],
        cerulean         => [ 155, 183, 212],
        rust             => [ 181,  90,  48],
        illuminating     => [ 245, 223,  77],
        frenchblue       => [   0, 114, 181],
        greenash         => [ 160, 218, 169],
        burntcoral       => [ 233, 137, 126],
        mint             => [   0, 161, 112],
        amethystorchid   => [ 146, 106, 166],
        raspberrysorbet  => [ 210,  56, 108],
        inkwell          => [  54,  57,  69],
        ultimategray     => [ 147, 149, 151],
        buttercream      => [ 239, 225, 206],
        desertmist       => [ 224, 181, 137],
        willow           => [ 154, 139,  79],
},};

sub new {
    my ($pkg) = @_;
    my $data = -r $file_name
             ? load( $pkg, $file_name )
             : $default;
    bless { path => $file_name, data => $data };
}

sub load {
    my ($self, $file) = @_;
    my $data = {};
    open my $FH, '<', $file or return "could not read $file: $!";
    my $category = '';
    while (<$FH>) {
        chomp;
        next unless $_ or substr( $_, 0, 1) eq '#';
        if    (/^\s*(\w+):\s*$/)          { $category = $1; $data->{$category} = []; }
        elsif (/^\s+-\s+(.+)\s*$/)        { push @{$data->{$category}}, $1;          }
        elsif (/^\s+\+\s+(\w+)\s*=\s*\[\s*(\d+)\s*,\s*(\d+)\s*,\s*(\d+)\s*\]/)
                                          { $data->{$category} = {} if ref $data->{$category} ne 'HASH';
                                            $data->{$category}{$1} = [$2, $3, $4];   }
        elsif (/^\s+\+\s+(\w+)\s*=\s*\[\s*(.+)\s*\]/)
                                          { $data->{$category} = {} if ref $data->{$category} ne 'HASH';
                                            $data->{$category}{$1} = [map {tr/ //d; $_} split /,/, $2] }
        elsif (/\s*(\w+)\s*=\s*(.+)\s*$/) { $data->{$1} = $2; $category =  '';}
    }
    close $FH;
    $data;
}

sub save {
    my ($self) = @_;
    my $data = $self->{'data'};
    my $file = $self->{'path'};
    open my $FH, '>', $file or return "could not write $file: $!";
    $" = ',';
    for my $key (sort keys %$data){
        my $val = $data->{ $key };
        if (ref $val eq 'ARRAY'){
            say $FH "$key:";
            say $FH "  - $_" for @$val;
        } elsif (ref $val eq 'HASH'){
            say $FH "$key:";
            say $FH "  + $_ = [ @{$val->{$_}} ]" for sort keys %$val;
        } elsif (not ref $val){
            say $FH "$key = $val";
        }
    }
    close $FH;
}


sub get_value {
    my ($self, $key) = @_;
    $self->{'data'}{$key} if exists $self->{'data'}{$key};
}

sub set_value {
    my ($self, $key, $value) = @_;
    $self->{'data'}{$key} = $value;
}

sub add_setting_file {
    my ($self, $file) = @_;
    $file = App::GUI::Juliagraph::Settings::shrink_path( $file );
    for my $f (@{$self->{'data'}{'last_settings'}}) { return if $f eq $file }
    push @{$self->{'data'}{'last_settings'}}, $file;
    shift @{$self->{'data'}{'last_settings'}} if @{$self->{'data'}{'last_settings'}} > 15;
}

sub add_color {
    my ($self, $name, $color) = @_;
    return 'not a color' unless ref $color eq 'ARRAY' and @$color == 3
        and int $color->[0] == $color->[0] and $color->[0] < 256 and $color->[0] >= 0
        and int $color->[1] == $color->[1] and $color->[1] < 256 and $color->[1] >= 0
        and int $color->[2] == $color->[2] and $color->[2] < 256 and $color->[2] >= 0;
    return 'color name alread taken' if exists $self->{'data'}{'color'}{ $name };
    $self->{'data'}{'color'}{ $name } = $color;
}

sub delete_color {
    my ($self, $name) = @_;
    delete $self->{'data'}{'color'}{ $name }
}


1;
