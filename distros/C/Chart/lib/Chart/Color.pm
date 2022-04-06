
# Chart::Color: color object with basic color space method and conversion

use v5.12;

package Chart::Color;

use Chart::Color::Named;
use Chart::Color::Scheme;


sub new {
    my ($pkg) = shift;
    return "need 3 arguments in hash form e.g. (r => 1, g => 2, b => 3)" unless @_ == 6;
    my $hash = {lc($_[0]) => $_[1], lc($_[2]) => $_[3], lc($_[4]) => $_[5] };
    my ($self, $rest);
    if      (exists $hash->{'r'} and exists $hash->{'g'} and exists $hash->{'b'}) {
        $rest = rgb_to_hsl( $hash->{'r'}, $hash->{'g'}, $hash->{'b'} );
        return "RGB values are out of range" unless ref $rest eq 'ARRAY';
        $self = [$hash->{'r'}, $hash->{'g'}, $hash->{'b'}, @$rest];
    } elsif (exists $hash->{'h'} and exists $hash->{'s'} and exists $hash->{'l'}) {
        $rest = hsl_to_rgb( $hash->{'h'}, $hash->{'s'}, $hash->{'l'} );
        return "HSL values are out of range" unless ref $rest eq 'ARRAY';
        $self = [@$rest, $hash->{'h'}, $hash->{'s'}, $hash->{'l'}];
    } else { return "need argument keys to be r, g, b or h, s, l" }
    bless $self;
}


sub rgb { @{$_[0]}[0 .. 2] }
sub hsl { @{$_[0]}[3 .. 5] }
sub hex { sprintf "%x%x%x", @{$_[0]}[0 .. 2]}

sub rgb_to_hsl{
    my ($r, $g, $b) = @_;
}

sub hsl_to_rgb {
    my ($h, $s, $l) = @_;
}


sub add {
    my ($self) = shift;
}

sub distance {
    my ($self) = shift;
}

sub gradient {
    my ($self) = shift;
}


1;

__END__


