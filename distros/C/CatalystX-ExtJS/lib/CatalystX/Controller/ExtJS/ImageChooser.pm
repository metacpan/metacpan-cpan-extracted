#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
package CatalystX::Controller::ExtJS::ImageChooser;
BEGIN {
  $CatalystX::Controller::ExtJS::ImageChooser::VERSION = '2.1.3';
}
# ABSTRACT: Controller for the ExtJS ImageChooser class

use strict;
use Carp;
use Path::Class;

use base 'Catalyst::Controller', 'Class::Accessor::Fast';

__PACKAGE__->mk_accessors('_extjs_ic_config');

sub new {
    my $self = shift->next::method(@_);
    my ($c) = @_;

    my $self_config = $self->config || {};
    my $parent_config = $c->config->{'Controller::ExtJS:ImageChooser'} || {};

    $self->_extjs_ic_config( { %$self_config, %$parent_config } );

    return $self;

}

sub _parse_NSPathPart_attr {
    my ( $self, $c ) = @_;
    return ( PathPart => $self->action_namespace );
}

sub foo : Chained('/') NSPathPart Args {
    my ( $self, $c ) = @_;
    my $config = $self->_extjs_ic_config;
    croak
q(please specify __PACKAGE__->config({image_chooser_dir => '...', image_chooser_url => '...'}))
      unless ( $config->{image_chooser_dir} && $config->{image_chooser_url} );

    my @images = ();

    my $base = Path::Class::Dir->new( $config->{image_chooser_dir} );
    my $dir = $base->subdir(@{$c->req->args});
    
    croak "$dir is a parent of $base" if($dir ne $base && $dir->subsumes($base));
    
    while ( my $file = $dir->next ) {
        next if $file->is_dir;
        push(
            @images,
            {
                name    => $file->basename,
                size    => $file->stat->size,
                lastmod => $file->stat->mtime,
                url     => $config->{image_chooser_url} . "/" . $file->basename
            }
        );

    }
    $c->stash({images => \@images});

}

1;



=pod

=head1 NAME

CatalystX::Controller::ExtJS::ImageChooser - Controller for the ExtJS ImageChooser class

=head1 VERSION

version 2.1.3

=head1 SYNOPSIS

  package MyApp::Controller::Images;
  
  use base 'CatalystX::Controller::ExtJS::Image::Chooser';
 
  __PACKAGE__->config(
      {
          image_chooser_dir => 'root/static/images',
          image_chooser_url => '/static/images'
      }
  );
  
  # use a JSON view
  
  # output is available at /images
  
  1;

Example at L<http://www.extjs.com/deploy/dev/examples/view/chooser.html>.

=head1 DESCRIPTION

This module generates an object which can be serialized to a json string. The ImageChooser class of ExtJS expects
the data in this way.

You can even look in subdirectories by simply adding the directory name to the url. Example: C</images/subdir> gives you the
files from C<root/static/images/subdir>. You cannot access directories, which are parents of the base directory.

=head1 AUTHOR

Moritz Onken <onken@netcubed.de>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2011 by Moritz Onken.

This is free software, licensed under:

  The (three-clause) BSD License

=cut


__END__

