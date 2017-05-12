package App::Fotagger::TagAll;

use strict;
use warnings;
use 5.010;

use Moose;
use Data::Dumper;

extends 'App::Fotagger';

has 'verbose' => ( isa => 'Bool', is => 'ro', default=>0);
has 'tag' => ( isa => 'ArrayRef', is => 'ro');

no Moose;
__PACKAGE__->meta->make_immutable;


sub tag_all {
    my $self = shift;
    $self->get_images;

    foreach my $file (@{$self->images}) {
        my $image = App::Fotagger::Image->new({file=>$file});
        $image->read;
        my %tags = map {$_=>1} split(/, /,$image->tags); 
        $image->add_tags($self->tag);
        $image->write;
    }
}

q{ listening to:
    Dan le Sac vs Scroobius Pip - Angels
};

