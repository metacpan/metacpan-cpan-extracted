package Catalyst::Helper::Controller::Imager;
$Catalyst::Helper::Controller::Imager::VERSION = '0.06';
use strict;

=head1 NAME

Catalyst::Helper::Controller::Imager - Helper for Imager Controllers

=head1 VERSION

version 0.06

=head1 SYNOPSIS

    script/create.pl controller Image Imager

=head1 DESCRIPTION

Helper for Imager Controllers.

=head2 METHODS

=head3 mk_compclass

=cut

sub mk_compclass {
    my ( $self, $helper ) = @_;
    my $file = $helper->{file};
    
    $helper->render_file( 'compclass', $file, {} );
}

=head1 SEE ALSO

L<Catalyst::Manual>, L<Catalyst::Helper>

=head1 AUTHOR

Wolfgang Kinkeldei, E<lt>wolfgang@kinkeldei.deE<gt>

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;

__DATA__

__compclass__
package [% class %];

use Moose;
BEGIN { extends 'Catalyst::Controller::Imager'; }

__PACKAGE__->config(
    # the directory to look for files (inside root)
    # defaults to 'static/images'
    #root_dir => 'static/images',
        
    # specify a cache dir if caching is wanted
    # defaults to no caching (more expensive)
    #cache_dir => undef,
        
    # specify a maximum value for width and height of images
    # defaults to 1000 pixels
    #max_size => 1000,
    
	# specify a typical size for thumnnails (/thumbnail/ in URI-path)
	# defaults to 80 x 80 square
	#thumbnail_size => 80,
        
    # specify a default format
    # default: jpg
    #default_format => 'jpg',

    # in case of jpeg, specify quality in percent
	# default: 95%
	# jpeg_quality => 95,
);

=head1 NAME

[% class %] - Imager Controller for [% app %]

=head1 DESCRIPTION

Imager Controller for [% app %]. 

=head1 METHODS

=cut

# uncomment if you like to change default behavior
# =head2 index
# 
# generate an image
# 
# =cut
# 
# sub index :Local :Args() {
#     my ( $self, $c, @args ) = @_;
#     # whatever we need to do here
#     
#     $c->detach('generate_image', @args);
# }

=head1 SEE ALSO

L<[% app %]>

=head1 AUTHOR

[% author %]

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
