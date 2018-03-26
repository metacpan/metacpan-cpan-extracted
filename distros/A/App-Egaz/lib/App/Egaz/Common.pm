package App::Egaz::Common;
use strict;
use warnings;
use autodie;

use 5.010001;

use Carp qw();
use File::ShareDir qw();
use IO::Zlib;
use IPC::Cmd qw();
use List::Util qw();
use Path::Tiny qw();
use Template;
use YAML::Syck qw();

use App::Fasops::Common;

sub resolve_file {
    my $original = shift;
    my @paths   = @_;

    my $file = $original;
    if ( !-e $file ) {
        $file = Path::Tiny::path($file)->basename();

        if ( !-e $file ) {
            for my $p (@paths) {
                $file = Path::Tiny::path($p)->child($file);
                last if -e $file;
            }
        }
    }

    if ( -e $file ) {
        return $file->stringify;
    }
    else {
        Carp::confess "Can't resole file for [$original]\n";
    }
}

sub round {
    my $float = shift;

    return int( $float + $float / abs( $float * 2 || 1 ) );
}

# Return a list of 1-based overlapping ranges
sub overlap_ranges {
    my $start   = shift;
    my $end     = shift;
    my $chunk   = shift;
    my $overlap = shift;

    my @ranges;
    for ( my $i = $start - 1; $i < $end; $i += $chunk ) {
        my $j = $i + $chunk + $overlap;
        $j = $end if ( $j > $end );
        push @ranges, [ ( $i + 1 ), $j ];
    }
    return \@ranges;
}

1;

