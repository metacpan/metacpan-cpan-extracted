package App::Fotagger::Export;

use strict;
use warnings;
use 5.010;

use Moose;
use Data::Dumper;
use Imager;
use File::Spec::Functions qw(catfile);
extends 'App::Fotagger';

has 'verbose' => ( isa => 'Bool', is => 'ro', default=>0);
has 'resize' => ( isa => 'Str', is => 'ro', default=>'1600x1050');
has 'tags' => ( isa => 'ArrayRef', is => 'ro');
has 'star' => ( isa => 'Str', is => 'ro');
has 'target' => ( isa => 'Str', is => 'ro');

no Moose;
__PACKAGE__->meta->make_immutable;

sub export {
    my $self = shift;
    $self->get_images;
    my $keep_tags = $self->tags;
    my $keep_star = $self->star;
    my ($resize_x,$resize_y) = split(/x/,$self->resize);
    
    my $count=0;

    foreach my $file (@{$self->images}) {
        my $image = App::Fotagger::Image->new({file=>$file});
        $image->read;
        
        
        #if ($keep_tags) { 
        #    my @tags = $image->tags; ..
        #    }
        
        if ($keep_star) {
            my $cmp = eval $image->stars.$keep_star;
            next unless ($cmp);
        }
        say $image->file, $image->stars;
        
        # export it!
        $count++;
        my $img = Imager->new();
        $img->read(file=>$image->file) or die $img->errstr();
        my $scaled = $img->scale(xpixels=>$resize_x, ypixels=>$resize_y);
        $scaled->write(file=>catfile($self->target,sprintf("%08d.jpg",$count)));


    }
}

q{ listening to:
    Dan le Sac vs Scroobius Pip - Angels
};

