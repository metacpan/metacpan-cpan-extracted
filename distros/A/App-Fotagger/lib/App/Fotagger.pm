package App::Fotagger;

use strict;
use warnings;
use 5.010;
use version; our $VERSION = qv('0.001.1');

use Moose;

with 'MooseX::Getopt';

has 'dir' => ( isa => 'Str', is => 'ro', default => '.' );
has 'display_class' => (isa=>'Str',is=>'ro',default=>'SDL');

has 'display'=>(is=>'rw');
has 'images' => (isa=>'ArrayRef', is=>'rw');
has 'image_index' => (isa=>'Int', is=>'rw',default=>0);
has '_image_count' => (isa=>'Int', is =>'rw');
has '_current_image' => ( isa=>'App::Fotagger::Image', is=>'rw');
has '_lasttags'=>(isa=>'Str',is=>'rw');
has '_laststar'=>(isa=>'Str',is=>'rw');

has 'tagging' => (isa=>'Bool',is=>'rw',default=>0);

no Moose;
__PACKAGE__->meta->make_immutable;

use File::Find::Rule;
use App::Fotagger::Image;

sub run {
    my $self=shift;

    $self->get_images;
    $self->run_display;
}

sub get_images {
    my $self = shift;
    my @images = sort File::Find::Rule->file->name( '*.jpg' )->in( $self->dir);
    $self->images(\@images);
    $self->_image_count(scalar @images);
    $self->current_image(App::Fotagger::Image->new({file=>$self->images->[0]}));

}

sub run_display {
    my $self = shift;
    my $display_class = 'App::Fotagger::Display::'.$self->display_class;
    eval "use $display_class";
    die $@ if $@;
    $display_class->run($self);
}

sub next_image {
    my $self = shift;
    my $inc = shift || 1;
    my $next = $self->image_index + $inc;
    $next = 0 if $next >= $self->_image_count;
    $self->image_index($next);
    return $self->current_image(App::Fotagger::Image->new(file=>$self->images->[$next]));
}

sub prev_image {
    my $self = shift;
    my $dec = shift || 1;
    my $prev = $self->image_index - $dec;
    $prev = $self->_image_count -1 if $prev < 0;
    $self->image_index($prev);
    return $self->current_image(App::Fotagger::Image->new(file=>$self->images->[$prev]));
}

sub current_image {
    my ($self, $image) = @_;
    if ($image) {
        $image->read;
        $self->_current_image($image);
    }
    return $self->_current_image;
}

q{ listening to:
    Peter Fox - Stadtaffen
};

__END__

=head1 NAME

App::Fotagger - tag fotos

=head1 SYNOPSIS

  use App::Fotagger;

=head1 DESCRIPTION

Make it easy to tag fotos, storing the tags in the EXIF metadata of jepgs.

=head1 AUTHOR

Thomas Klausner E<lt>domm {at} cpan.orgE<gt>

=head1 SEE ALSO

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
