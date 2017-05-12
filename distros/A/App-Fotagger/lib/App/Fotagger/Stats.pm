package App::Fotagger::Stats;

use strict;
use warnings;
use 5.010;

use Moose;
use Data::Dumper;

extends 'App::Fotagger';

has 'verbose' => ( isa => 'Bool', is => 'ro', default=>0);

no Moose;
__PACKAGE__->meta->make_immutable;


sub get_stats {
    my $self = shift;
    $self->get_images;
    my %tags;
    my %stars;

    foreach my $file (@{$self->images}) {
        my $image = App::Fotagger::Image->new({file=>$file});
        $image->read;
        my @tags = split(/, /,$image->tags); 
        if (@tags) {
            foreach my $tag (@tags) {
                push(@{$tags{$tag}},$image->file);
            }
        }
        else {
            push(@{$tags{'NO_TAG'}},$image->file);
        }
        
        push(@{$stars{$image->stars}},$image->file); 

    }
    
    return {
        tags=>\%tags,
        stars=>\%stars,
        count=>scalar @{$self->images},
    };
}

sub dump {
    my ($self, $stats) = @_;
    local $Data::Dumper::Sortkeys=1;
    say Dumper $stats;
}

sub report {
    my ($self, $stats) = @_;

    say "Processed ".$stats->{count}." images";
    
    my $format="  %".length($stats->{count})."d  ";
    for my $s (0..5) {
        next unless $stats->{stars}{$s};
        my $line = ("*" x $s ) .  (" " x (5-$s)). sprintf($format,scalar @{$stats->{stars}{$s}}) ;
        say $line;
    }

    foreach my $tag (sort { scalar @{$stats->{tags}{$b}} <=> scalar @{$stats->{tags}{$a}} } keys %{$stats->{tags}}) {
        say sprintf($format,scalar @{$stats->{tags}{$tag}}).$tag;
    }
}

q{ listening to:
    Dan le Sac vs Scroobius Pip - Angels
};

