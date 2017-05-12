package My::Builder::Windows;

use strict;
use warnings;

use File::Copy qw/move cp/;

use base 'My::Builder';

sub prebuild {
    my $self = shift;
    my $dst = $self->notes('src_dir') . '/Makefile';
    my $src = $self->base_dir . '/inc/Makefile.mingw';
    cp($src, $dst) or die("Can't cp $src $dst: $!");
    print STDERR "Original Makefile has been overwritten.\n";
    $self->apply_patch($self->notes('src_dir'), $self->base_dir . '/inc/disable-dx.patch');
}


1;
