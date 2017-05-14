#!/usr/bin/env perl
#Copyright (c) 2010 Joachim Bargsten <code at bargsten dot org>. All rights reserved.
package Bio::Gonzales::Align::Jalview;
use Carp;


use Mouse;
use Bio::Gonzales::Seq;
our $VERSION = '0.0546'; # VERSION


has 'sequence' => (
    is => 'rw',
);

sub track_marks {
    #array of coordinate references [start, end, name]
    my ($self,$data) = @_;
    my $coords = $data->{track};



    my $track_prefix = "NO_GRAPH\t$data->{name}\t$data->{description}\t";
    my @track = ('|')x($self->sequence->length);
    for my $c (@{$coords}) {
        $track[$c->[0]-1] = "H,$c->[2],[000000]";
        for(my $i = $c->[0]; $i < $c->[1]; $i++) {
            $track[$i] = '|H,[000000]';

        }
    }
    print STDERR "Track length: " . scalar @track, "\n";
    return $track_prefix . join('', @track) . '|';


}

sub annotation_track {
    # array [[start,end,name], ...]
    my ($self,$s) = @_;
    my $an = "JALVIEW_ANNOTATION\n\n";

    $an .= "SEQUENCE_REF\t" . $self->sequence->display_id ."\n";
    $an .= $self->track_marks($s) . "\n";

    return $an;
}


1;
