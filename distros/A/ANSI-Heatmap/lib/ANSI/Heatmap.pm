package ANSI::Heatmap;
# POD after __END__

use strict;
use warnings;

our $VERSION = 0.3;

use overload '""' => 'to_string';
use Carp;
use List::Util qw(min max);
use POSIX qw(floor modf);
use Class::Accessor::Fast;
our @ISA = qw(Class::Accessor::Fast);
our @_minmax_fields = map { ("min_$_", "max_$_") } qw(x y z);
our @_fields = ('half', 'interpolate', 'width', 'height', @_minmax_fields);
__PACKAGE__->mk_accessors(@_fields);

my $TOPBLOCK = "\N{U+2580}";
my %SWATCHES = (
    'blue-red'  => [0x10 .. 0x15, 0x39, 0x5d, 0x81, 0xa5, reverse(0xc4 .. 0xc9)],
    'grayscale' => [0xe8 .. 0xff],
);
my $DEFAULT_SWATCH = 'blue-red';

sub new {
    my $class = shift;
    my %args = (@_ == 1 && ref $_[0] && ref $_[0] eq 'HASH') ? %{$_[0]} : @_;
    my $self = bless { map => [], minmax => {} }, $class;
    $self->swatch($DEFAULT_SWATCH);
    $self->interpolate(0);
    $self->half(0);
    for my $field (@_fields, 'swatch') {
        $self->$field(delete $args{$field}) if exists $args{$field};
    }
    if (keys %args) {
        croak "Invalid constructor argument(s) " . join(', ', sort keys %args);
    }
    return $self;
}

sub swatch_names {
    my $self = shift;
    return (sort keys %SWATCHES);
}

sub set {
    my ($self, $x, $y, $z) = @_;
    $self->{map}[$y][$x] = $z;
    $self->_set_minmax(x => $x, y => $y, z => $z);
}

sub get {
    my ($self, $x, $y) = @_;
    return $self->{map}[$y][$x] || 0;
}

sub inc {
    my ($self, $x, $y) = @_;
    $self->set( $x, $y, $self->get($x, $y) + 1 );
}

sub swatch {
    my $self = shift;
    if (@_) {
        my $sw = shift;
        @_ == 0 or croak "swatch: excess arguments";
        if (ref $sw) {
            ref $sw eq 'ARRAY' or croak "swatch: invalid argument, should be string or arrayref";
            @$sw > 0 or croak "swatch: swatch is empty";
            $self->{swatch} = $sw;
        }
        else {
            defined $sw or croak "swatch: swatch name is undefined";
            exists $SWATCHES{$sw} or croak "swatch: swatch '$sw' does not exist";
            $self->{swatch} = $SWATCHES{$sw};
        }
    }
    return $self->{swatch};
}

sub to_string {
    my $self = shift;
    return $self->render($self->data);
}

# Convert heatmap hash to a 2D grid of intensities, normalised between 0 and 1,
# cropped to the min/max range supplied and scaled to the desired width/height.
sub data {
    my ($self, $mm) = @_;
    my %mm = $self->_figure_out_min_and_max;
    my $inv_max_z = $mm{zrange} ? 1 / $mm{zrange} : 0;
    my @out;

    my $xscale = $mm{width} / ($mm{max_x} - $mm{min_x} + 1);
    my $yscale = $mm{height} / ($mm{max_y} - $mm{min_y} + 1);
    my $get = sub { $self->{map}[ $_[1] ][ $_[0] ] || 0 };
    my $sample;
    if (!$self->interpolate
        || $xscale == int($xscale) && $yscale == int($yscale)) {
        $sample = $get;  # nearest neighbour/direct lookup
    }
    else {
        $sample = _binterp($get);
    }

    for my $y (0..$mm{height}-1) {
        for my $x (0..$mm{width}-1) {
            my $sx = ($x / $xscale) + $mm{min_x};
            my $sy = ($y / $yscale) + $mm{min_y};
            my $z = $sample->($sx, $sy);

            # Normalise intensity
            $z = $mm{max_z} if $z > $mm{max_z};
            $z -= $mm{min_z};
            $z *= $inv_max_z;

            $out[$y][$x] = $z;
        }
    }

    return \@out;
}

sub render {
    my ($self, $matrix) = @_;
    my $half = $self->half;

    my @s;
    for my $y (0..$#{$matrix}) {
        next if $half && $y % 2 == 1;

        for my $x (0..$#{$matrix->[$y]}) {
            my $top = $matrix->[$y][$x] || 0;
            my $bottom = $half ? ($y == $#{$matrix} ? undef : $matrix->[$y+1][$x] || 0)
                               : $top;

            my ($top_color, $bottom_color) = map {
                $self->_swatch_lookup($_)
            } grep { defined } ($top, $bottom);

            my $fg = sprintf "\e[38;5;%d%s", $top_color, 'm';
            my $bg = defined $bottom ? sprintf "\e[48;5;%d%s", $bottom_color, 'm'
                                     : '';

            my $char = $half ? $fg . $bg . $TOPBLOCK : $bg . ' ';

            push @s, $char . "\e[0m";
        }
        push @s, "\n";
    }
    return join '', @s;
}


# Return hash of min/max values for each axis.
sub _figure_out_min_and_max {
    my $self = shift;
    my %calc = (
        (map { $_ => 0 } @_minmax_fields),
        %{$self->{minmax}},
        ($self->{minmax}{min_z}||0) >= 0 ? (min_z => 0) : (),
    );

    # Override with user-specified values, if supplied.
    for my $k (keys %calc) {
        $calc{$k} = $self->{$k} if defined $self->{$k};
    }

    # If user did not specify width/height, assume 1x scale.
    $calc{width}  = $self->{width} || ($calc{max_x} - $calc{min_x} + 1);
    $calc{height} = $self->{height} || ($calc{max_y} - $calc{min_y} + 1);
    $calc{zrange} = $calc{max_z} - $calc{min_z};

    return %calc;
}

sub _binterp {
    my $get = shift;
    return sub {
        my ($x, $y) = @_;
        my ($fx, $bx) = modf($x);
        my ($fy, $by) = modf($y);
        my @p = map { $get->($bx + $_->[0], $by + $_->[1]) } ([0,0],[0,1],[1,0],[1,1]);

        my $y1 = $p[0] + ($p[1] - $p[0]) * $fy;
        my $y2 = $p[2] + ($p[3] - $p[2]) * $fy;
        my $z = $y1 + ($y2 - $y1) * $fx;
        return $z;
    };
}

sub _set_minmax {
    my ($self, %vals) = @_;
    my $mm = $self->{minmax};
    while (my ($k, $v) = each %vals) {
        if (!defined $mm->{"min_$k"}) {
            $mm->{"min_$k"} = $mm->{"max_$k"} = $v;
        }
        else {
            $mm->{"min_$k"} = min($mm->{"min_$k"}, $v);
            $mm->{"max_$k"} = max($mm->{"max_$k"}, $v);
        }
    }
}

# Maps a number from [0,1] to a swatch colour.
sub _swatch_lookup {
    my ($self, $index) = @_;
    return $self->{swatch}->[$index * $#{$self->{swatch}} + .5];
}

1;

=head1 NAME

ANSI::Heatmap - render heatmaps to your terminal

=head1 SYNOPSIS

 my $map = ANSI::Heatmap->new(
    half => 1,
    min_x => 0, max_x => 49,
    min_y => 0, max_y => 49,
    swatch => 'blue-red',
 );

 for (1..2000) {
     my $x = int(rand(50));
     my $y = int(rand(50));
     $map->inc($x, $y);
 }

 print $map;

 $map->interpolate(1);
 $map->width(25);
 $map->height(25);
 $map->swatch('grayscale');
 print $map;

 my $data = $map->data;
 # Mess with the data...
 print $map->render($data);

 # Custom swatch
 $map->swatch([0x10 .. 0x15]);

=head1 DESCRIPTION

Produce cutting-edge ANSI heatmaps using 256 colours and weird Unicode
characters! Perfect for 3D (2D + intensity) data.

=head1 METHODS

=head2 new ( [ARGS] )

C<ARGS> may be a hash or hashref accepting the following keys, which
also have getter/setter methods:

=over 4

=item min_x, max_x ( INT )

Specify the smallest and largest X-axis value to include. If not
provided, defaults to the smallest/largest values passed to C<set>
or C<inc>. Can be used to crop the map or ensure it keeps a fixed
size even if some values are unset.

To make automatic again, set to C<undef>.

=item min_y, max_y ( INT )

Ditto for the Y-axis.

=item min_z, max_z ( FLOAT )

Ditto for intensity; useful for keeping a fixed intensity across
multiple heatmaps.

The default C<min_z> value is 0, unless negative intensities are
used.

=item swatch ( STR | ARRAYREF )

Set the colour swatch; see C<swatch> below.

=item half ( BOOL )

A boolean indicating if the map should be rendered in half-height
mode using special characters. On most terminals, this means the
X and Y axis will be scaled identically.

Off by default.

=item width, height ( INT )

Specify the width/height of the map in characters. Defaults to
using the min_I<axis> and max_I<axis> values to determine the
width/height.

=item interpolate ( BOOL )

If width/height is not a nice multiple of the input data and
this flag is set, perform bilinear interpolation (instead of
nearest neighbour). This is a trade off; interpolated data is
blurrier, but retains a linear relationship with the original
data. Off by default.

=back

=head2 set ( X, Y, Z )

Set the heatmap intensity for the given X and Y co-ordinate.

Currently, only integer values for X and Y are supported.

=head2 get ( X, Y )

Return the heatmap intensity for the given X and Y co-ordinate,
or 0 if unset.

=head2 inc ( X, Y )

Increase the intensity at the given co-ordinate by 1.

=head2 to_string

Return a string containing the ANSI heatmap. If C<half> is set,
this string contains wide characters, so you may need to:

 binmode STDOUT, ':utf8';

or

 use open OUT => ':utf8';

before printing anything (in this case) to STDOUT.

=head2 data

Returns the heatmap data, cropped, scaled and normalised with
intensity values between 0 and 1.

Expressed as an arrayref of arrayrefs indexed by Y and then
X co-ordinate.

=head2 render ( DATA )

Manually render heatmap data as returned by C<data>. Useful
if you want to do any custom processing.

=head2 swatch ( [ARRAYREF | STRING] )

Set the colour swatch that decided how the heatmap will look.
A string alias can be provided, or an arrayref of numeric values
from 0..255 declaring the colour indexes to use from least
intensive to most.

With no arguments, returns thw swatch as an arrayref.

Defaults to a traditional 'thermography' blue -> red swatch
('blue-red'). Another valid option is 'grayscale'.

=head2 swatch_names

Returns an list of string swatch aliases.

=head1 AUTHOR

Richard Harris <richardjharris@gmail.com>

=head1 COPRIGHT AND LICENSE

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
