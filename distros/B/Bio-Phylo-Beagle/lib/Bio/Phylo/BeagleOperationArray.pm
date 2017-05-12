package Bio::Phylo::BeagleOperationArray;
use strict;
use warnings;
use Bio::Phylo::Util::Exceptions 'throw';
use Bio::Phylo::Util::CONSTANT qw'/looks_like/';
use beagle;

sub new {
    my $class = shift;
    my $size  = shift or throw 'BadArgs' => "Need size";
    my $self = bless {
        '_boa' => beagle::new_BeagleOperationArray($size)
    }, $class;
    return $self;
}

sub set_item {
    my $self = shift;
    if ( my %args = looks_like_hash @_ ) {
        my $index = $args{'-index'} || 0;
        my $op = $args{'-op'} or throw 'BadArgs' => "Need -op argument";
        beagle::BeagleOperationArray_setitem($self->get_array,$index,$op->get_op);
    }
}

sub get_array { shift->{'_boa'} }


1;
