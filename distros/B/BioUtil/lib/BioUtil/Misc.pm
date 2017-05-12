package BioUtil::Misc;

use BioUtil::Seq;

require Exporter;
@ISA    = (Exporter);
@EXPORT = qw(
    parse_embossre
);

use vars qw($VERSION);

use 5.010_000;
use strict;
use warnings FATAL => 'all';

=head1 NAME

BioUtil::Misc - Miscellaneous functions

=head1 VERSION

Version 2014.0901

=cut

our $VERSION = 2014.0901;

=head1 EXPORT

    parse_embossre

=head1 SYNOPSIS

  use BioUtil::Misc;


=head1 SUBROUTINES/METHODS

=head2 parse_embossre

Example

    my $enzs = parse_embossre("embossre.enz");

    for my $enz ( sort keys %$enzs ) {
        my $e = $$enzs{$enz};
        print join ", ",
            (
            $$enzs{$enz}{name},     $$enzs{$enz}{pattern},
            $$enzs{$enz}{length},   $$enzs{$enz}{cuts_number},
            $$enzs{$enz}{is_blunt}, $$enzs{$enz}{c1},
            $$enzs{$enz}{c2},       $$enzs{$enz}{c3},
            $$enzs{$enz}{c4},
            ),
            "\n";
    } 

=cut

sub parse_embossre {
    my ($file) = @_;
    my ( $enzs, $enz ) = ( {}, '' );
    open my $fh, $file or die "fail to open enzyme file $file!\n";
    while (<$fh>) {
        next if /^#/;    # annotation
        next unless /(\w+)       # name
                    \t(\w+)     # pattern
                    \t(\d+)     # length of pattern
                    \t(\d+)     # number of cuts made by enzyme
                    \t(\d+)     # is blunt
                    \t([\d\-]+) # c1 = First 5' cut
                    \t([\d\-]+) # c2 = First 3' cut
                    \t([\d\-]+) # c3 = Second 5' cutx;
                    \t([\d\-]+) # c4 = Second 3' cut
                    /x;
        $enz = $1;
        $enz .= '*' while defined $$enzs{$enz};
        $$enzs{$enz}{name}    = $1;
        $$enzs{$enz}{pattern} = uc $2;
        $$enzs{$enz}{pattern_regexp}
            = degenerate_seq_to_regexp( $$enzs{$enz}{pattern} );
        $$enzs{$enz}{length}      = $3;
        $$enzs{$enz}{cuts_number} = $4;
        $$enzs{$enz}{is_blunt}    = $5;
        $$enzs{$enz}{c1}          = $6;
        $$enzs{$enz}{c2}          = $7;
        $$enzs{$enz}{c3}          = $8;
        $$enzs{$enz}{c4}          = $9;
    }
    close $fh;
    return $enzs;
}

1;
