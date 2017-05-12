package GDTestApp;

use strict;
use warnings;

use Catalyst;
use GD;

use GDTestApp::View::GD;

__PACKAGE__->config({
    name       => 'GDTestApp',
    'View::GD' => {} # go with the defaults for now
});

__PACKAGE__->setup;

sub create_image : Private {
    my $self = shift;
    
    my $img   = GD::Image->new(100, 100);

    my $white = $img->colorAllocate(255, 255, 255);
    my $black = $img->colorAllocate(0, 0, 0);       
    my $red   = $img->colorAllocate(255, 0, 0);      

    $img->rectangle(0, 0, 20, 20, $black);    
    $img->rectangle(20, 20, 50, 50, $red);    
    
    return $img;    
}

sub test_one : Global {
    my ($self, $c) = @_;

    $c->stash->{gd_image} = $self->create_image;
    
    $c->forward('GDTestApp::View::GD');
}

1;

__END__
