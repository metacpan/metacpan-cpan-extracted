
#    read only color holding object 
#    with methods for relation, mixing and transitions

use v5.12;

package App::GUI::Harmonograph::Color;

use Carp;
use App::GUI::Harmonograph::Color::Constant ':all';
use App::GUI::Harmonograph::Color::Value ':all';

my $new_help = 'constructor of Chart::Color object needs either:'.
        ' 1. RGB or HSL hash or ref: ->new(r => 255, g => 0, b => 0), ->new({ h => 0, s => 100, l => 50 })'.
        ' 2. RGB array or ref: ->new( [255, 0, 0 ]) or >new( 255, 0, 0 )'.
        ' 3. hex form "#FF0000" or "#f00" 4. a name: "red" or "SVG:red".';

## constructor #########################################################
        
sub new {
    my ($pkg, @args) = @_;
    @args = ([@args]) if @args == 3;
    @args = ({ $args[0] => $args[1], $args[2] => $args[3], $args[4] => $args[5] }) if @args == 6;
    return carp $new_help unless @args == 1;
    _new_from_scalar($args[0]);
}
sub _new_from_scalar {
    my ($arg) = shift;
    my $name;
    if (not ref $arg){ # resolve 'color_name' or '#RRGGBB' -> ($r, $g, $b)
        my @rgb = _rgb_from_name_or_hex($arg);
        return unless @rgb == 3;
        $name = $arg if index( $arg, ':') > -1;
        $arg = { r => $rgb[0], g => $rgb[1], b => $rgb[2] };
    } elsif (ref $arg eq 'ARRAY'){
        return carp "need exactly 3 RGB numbers!" unless @$arg == 3;
        $arg = { r => $arg->[0], g => $arg->[1], b => $arg->[2] };
    }
    return carp $new_help unless ref $arg eq 'HASH' and keys %$arg == 3;
    my %named_arg = map { _shrink_key($_) =>  $arg->{$_} } keys %$arg; # reduce keys to lc first char

    my (@rgb, @hsl);
    if      (exists $named_arg{'r'} and exists $named_arg{'g'} and exists $named_arg{'b'}) {
        @rgb = trim_rgb(@named_arg{qw/r g b/});
        @hsl = hsl_from_rgb( @rgb );
    } elsif (exists $named_arg{'h'} and exists $named_arg{'s'} and exists $named_arg{'l'}) {
        @hsl = trim_hsl( @named_arg{qw/h s l/});
        @rgb = rgb_from_hsl( @hsl );
    } else { return carp "argument keys need to be r, g and b or h, s and l (long names and upper case work too!)" }
    $name = name_from_rgb( @rgb ) unless defined $name;
    bless [$name, @rgb, @hsl];
}
sub _rgb_from_name_or_hex {
    my $arg = shift;
    my $i = index( $arg, ':');
    if (substr($arg, 0, 1) eq '#'){                  # resolve #RRGGBB -> ($r, $g, $b)
        return rgb_from_hex( $arg );
    } elsif ($i > -1 ){                              # resolve pallet:name -> ($r, $g, $b)
        my $pallet_name = substr $arg,   0, $i-1;
        my $color_name = substr $arg, $i+1;
        
        my $module_base = 'Graphics::ColorNames';
        eval "use $module_base";
        return carp "$module_base is not installed, but it's needed to load external colors" if $@;
        
        my $module = $module_base.'::'.$pallet_name;
        eval "use $module";
        return carp "$module is not installed, to load color '$color_name'" if $@;
        
        my $pal = Graphics::ColorNames->new( $pallet_name );
        my @rgb = $pal->rgb( $color_name );
        return carp "color '$color_name' was not found, propably not part of $module" unless @rgb == 3;
        @rgb;
    } else {                                         # resolve name -> ($r, $g, $b)
        my @rgb = rgb_from_name( $arg );
        carp "'$arg' is an unknown color name, please check App::GUI::Harmonograph::Color::Constant::all_names()." unless @rgb == 3;
        @rgb;
    }
}

## getter ##############################################################

sub name        { $_[0][0] }
sub red         { $_[0][1] }
sub green       { $_[0][2] }
sub blue        { $_[0][3] }
sub hue         { $_[0][4] }
sub saturation  { $_[0][5] }
sub lightness   { $_[0][6] }
sub string      { $_[0][0] ? $_[0][0] : "[ $_[0][1], $_[0][2], $_[0][3] ]" }

sub hsl         { @{$_[0]}[4 .. 6] }
sub rgb         { @{$_[0]}[1 .. 3] }
sub rgb_hex     { hex_from_rgb( $_[0]->rgb() ) }

## methods ##############################################################

sub distance_to {
    my ($self, $c2, $metric) = @_;
    return croak "missing argument: color object or scalar color definition" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : new( __PACKAGE__, $c2 );
    return unless ref $c2 eq __PACKAGE__;
    
    return distance_hsl( [$self->hsl], [$c2->hsl] ) unless defined $metric;
    $metric = lc $metric;
    return distance_hsl( [$self->hsl], [$c2->hsl] ) if $metric eq 'hsl';
    return distance_rgb( [$self->rgb], [$c2->rgb] ) if $metric eq 'rgb';
    my @delta_rgb = difference_rgb( [$self->rgb], [$c2->rgb] );
    my @delta_hsl = difference_hsl( [$self->hsl], [$c2->hsl] );
    my $help = "unknown distance metric: $metric. try r, g, b, rg, rb, gb, rgb, h, s, l, hs, hl, sl, hsl (default).";
    if (length $metric == 2){
        if    ($metric eq 'hs' or $metric eq 'sh') {return sqrt( $delta_hsl[0] ** 2 + $delta_hsl[1] ** 2 )}
        elsif ($metric eq 'hl' or $metric eq 'lh') {return sqrt( $delta_hsl[0] ** 2 + $delta_hsl[2] ** 2 )}
        elsif ($metric eq 'sl' or $metric eq 'ls') {return sqrt( $delta_hsl[1] ** 2 + $delta_hsl[2] ** 2 )}
        elsif ($metric eq 'rg' or $metric eq 'gr') {return sqrt( $delta_rgb[0] ** 2 + $delta_rgb[1] ** 2 )}
        elsif ($metric eq 'rb' or $metric eq 'br') {return sqrt( $delta_rgb[0] ** 2 + $delta_rgb[2] ** 2 )}
        elsif ($metric eq 'gb' or $metric eq 'bg') {return sqrt( $delta_rgb[1] ** 2 + $delta_rgb[2] ** 2 )}
    }
    $metric = substr $metric, 0, 1;
    $metric eq 'h' ? $delta_hsl[0] :
    $metric eq 's' ? $delta_hsl[1] :
    $metric eq 'l' ? $delta_hsl[2] :
    $metric eq 'r' ? $delta_rgb[0] :
    $metric eq 'g' ? $delta_rgb[1] :
    $metric eq 'b' ? $delta_rgb[2] : croak $help;
}

sub add {
    my ($self, @args) = @_;
    my $add_help = 'Chart::Color->add argument options: 1. a color object with optional factor as second arg, '.
        '2. a color name as string, 3. a color hex definition as in "#FF0000"'.
        '4. a list of thre values (RGB) (also in an array ref)'.
        '5. a hash with RGB and HSL keys (as in new, but can be mixed) (also in an hash ref).';
    if ((@args == 1 or @args == 2) and ref $args[0] ne 'HASH'){
        my @add_rgb;
        if (ref $args[0] eq __PACKAGE__){ 
            @add_rgb = $args[0]->rgb;
        } elsif (ref $args[0] eq 'ARRAY'){ 
            @add_rgb = @{$args[0]};
            return carp "array ref argument needs to have 3 numerical values (RGB) in it." unless @add_rgb == 3;
        } elsif (not ref $args[0] and not $args[0] =~ /^\d/){
            @add_rgb = _rgb_from_name_or_hex($args[0]);
            return unless @add_rgb > 1;
        } else { return carp $add_help }
        @add_rgb = ($add_rgb[0] * $args[1], $add_rgb[1] * $args[1], $add_rgb[2] * $args[1]) if defined $args[1];
        @args = @add_rgb;
    }
    my @rgb = $self->rgb;
    if (@args == 3) {
        @rgb = trim_rgb( $rgb[0] + $args[0], $rgb[1] + $args[1], $rgb[2] + $args[2]);
        return new( __PACKAGE__, @rgb );
    }
    return carp $add_help unless @args and ((@args % 2 == 0) or (ref $args[0] eq 'HASH'));
    my %arg = ref $args[0] eq 'HASH' ? %{$args[0]} : @args;
    my %named_arg = map {_shrink_key($_) =>  $arg{$_}} keys %arg; # clean keys
    $rgb[0] += delete $named_arg{'r'} // 0;
    $rgb[1] += delete $named_arg{'g'} // 0;
    $rgb[2] += delete $named_arg{'b'} // 0;
    return new( __PACKAGE__, trim_rgb( @rgb ) ) unless %named_arg;
    my @hsl = App::GUI::Harmonograph::Color::Value::_hsl_from_rgb( @rgb ); # withound rounding
    $hsl[0] += delete $named_arg{'h'} // 0;
    $hsl[1] += delete $named_arg{'s'} // 0;
    $hsl[2] += delete $named_arg{'l'} // 0;
    if (%named_arg) {
        my @nrkey = grep {/^\d+$/} keys %named_arg;
        return carp "wrong number of numerical arguments (only 3 needed)" if @nrkey;
        carp "got unknown hash key starting with", map {' '.$_} keys %named_arg;
    }    
    @hsl = trim_hsl( @hsl );
    new( __PACKAGE__, { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
}

sub blend_with {
    my ($self, $c2, $pos) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : _new_from_scalar( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $pos //= 0.5;
    my $delta_hue = $c2->hue - $self->hue;
    $delta_hue -= 360 if $delta_hue >  180;
    $delta_hue += 360 if $delta_hue < -180;
    my @hsl = ( $self->hue        + ($pos * $delta_hue),
                $self->saturation + ($pos * ($c2->saturation - $self->saturation)),
                $self->lightness  + ($pos * ($c2->lightness  - $self->lightness))
    );
    @hsl = trim_hsl( @hsl );
    new( __PACKAGE__, { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
}

    
sub gradient_to {
    my ($self, $c2, $steps, $power) = @_;
    return carp "need color object or definition as first argument" unless defined $c2;
    $c2 = (ref $c2 eq __PACKAGE__) ? $c2 : _new_from_scalar( $c2 );
    return unless ref $c2 eq __PACKAGE__;
    $steps //= 3;
    $power //= 1;
    return carp "third argument (dynamics), has to be positive (>= 0)" if $power <= 0;
    return $self if $steps == 1;
    my @colors = ();
    my @delta_hsl = ($c2->hue - $self->hue, $c2->saturation - $self->saturation,
                                            $c2->lightness - $self->lightness  );
    $delta_hsl[0] -= 360 if $delta_hsl[0] >  180;
    $delta_hsl[0] += 360 if $delta_hsl[0] < -180;
    for my $i (1 .. $steps-2){
        my $pos = ($i / ($steps-1)) ** $power;
        my @hsl = ( $self->hue        + ($pos * $delta_hsl[0]),
                    $self->saturation + ($pos * $delta_hsl[1]),
                    $self->lightness  + ($pos * $delta_hsl[2]));
        @hsl = trim_hsl( @hsl );
        push @colors, new( __PACKAGE__, { H => $hsl[0], S => $hsl[1], L => $hsl[2] });
    }
    $self, @colors, $c2;
}

sub complementary {
    my ($self) = shift;
    my ($count) = int ((shift // 1) + 0.5);
    my ($saturation_change) = shift // 0;
    my ($lightness_change) = shift // 0;
    my @hsl2 = my @hsl_l = my @hsl_r = $self->hsl;
    $hsl2[0] += 180;
    $hsl2[1] += $saturation_change;
    $hsl2[2] += $lightness_change;
    @hsl2 = trim_hsl( @hsl2 ); # HSL of C2
    my $c2 = new( __PACKAGE__, { h => $hsl2[0], s => $hsl2[1], l => $hsl2[2] });
    return $c2 if $count < 2;
    my (@colors_r, @colors_l);
    my @delta = (360 / $count, (($hsl2[1] - $hsl_r[1]) * 2 / $count), (($hsl2[2] - $hsl_r[2]) * 2 / $count) );
    for (1 .. ($count - 1) / 2){
        $hsl_r[$_] += $delta[$_] for 0..2;
        $hsl_l[0] -= $delta[0];
        $hsl_l[$_] = $hsl_r[$_] for 1,2;
        $hsl_l[0] += 360 if $hsl_l[0] <    0;
        $hsl_r[0] -= 360 if $hsl_l[0] >= 360;
        push @colors_r, new( __PACKAGE__, { H => $hsl_r[0], S => $hsl_r[1], L => $hsl_r[2] });
        unshift @colors_l, new( __PACKAGE__, { H => $hsl_l[0], S => $hsl_l[1], L => $hsl_l[2] });
    }
    push @colors_r, $c2 unless $count % 2;
    $self, @colors_r, @colors_l;
}

sub _shrink_key { lc substr( $_[0], 0, 1 ) }

1;

