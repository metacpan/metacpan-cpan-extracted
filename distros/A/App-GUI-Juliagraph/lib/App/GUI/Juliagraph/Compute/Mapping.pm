
# map different scales

package App::GUI::Juliagraph::Compute::Mapping;
use v5.12;
use warnings;

sub scales {
    my( $scaling_type, $scale_length, $parts ) = @_;
    my (%mapping);
    my @iterator = 1 .. $parts;
    my $jumping_index = 0;
    if ($scaling_type eq 'linear'){
        my $scale_max = $scale_length / $parts;
        for my $part_nr (@iterator) {
            my $next_scale_notch = round ($part_nr * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    } elsif ($scaling_type eq 'square'){
        my $scale_max = $scale_length / ($parts ** 2);
        for my $part_nr ( @iterator) {
            my $next_scale_notch = round (($part_nr**2) * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    } elsif ($scaling_type eq 'cube'){
        my $scale_max = $scale_length / ($parts ** 3);
        for my $part_nr ( @iterator) {
            my $next_scale_notch = round (($part_nr**3) * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    } elsif ($scaling_type eq 'sqrt'){
        my $scale_max = $scale_length / sqrt ($parts);
        for my $part_nr ( @iterator) {
            my $next_scale_notch = round ((sqrt $part_nr) * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    } elsif ($scaling_type eq 'cubert'){
        my $third = 1/3;
        my $scale_max = $scale_length /(($parts) ** $third);
        for my $part_nr (@iterator) {
            my $next_scale_notch = round (($part_nr ** $third) * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    } elsif ($scaling_type eq 'log'){
        my $scale_max = $scale_length / log ($parts+1);
        for my $part_nr (@iterator) {
            my $next_scale_notch = round (log($part_nr+1) * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    } elsif ($scaling_type eq 'exp'){
        my $scale_max = $scale_length / exp($parts);
        for my $part_nr ( @iterator) {
            my $next_scale_notch = round (exp($part_nr) * $scale_max);
            $mapping{$_} = $part_nr-1 for $jumping_index .. $next_scale_notch;
            $jumping_index = $next_scale_notch + 1;
        }
    }
    return \%mapping;
}

my $half      = 0.50000000000008;
sub round {
    $_[0] >= 0 ? int ($_[0] + $half)
               : int ($_[0] - $half)
}

1;
