use strict;
use warnings;
package Acme::CatFS;

# ABSTRACT: Fuse filesystem with a random pic of a cat

use feature qw(say state);
use Carp;
use Try::Tiny;
use LWP::Simple;
use Fuse::Simple;

use Moo;
use MooX::Options;
use Types::Path::Tiny qw(Dir);

option mountpoint => ( 
  is       => 'ro', 
  isa      => Dir,
  required => 1,
  format   => 's',
  coerce   => Dir->coercion,
  doc      => 'mount point for catfs (should be a directory). Required.',
);

option cat_url => (
  is      => 'ro',
  format  => 's',
  default => sub {
    'http://thecatapi.com/api/images/get?format=src&type=jpg'
  },
  doc     => 'url used to find a random pic of a cat (default thecatapi.com)',
);

option cat_file => (
  is      => 'ro',
  format  => 's',
  default => sub { 'cat.jpg' },
  doc     => 'name of the file (default is cat.jpg)',
);

option forking => (
  is  => 'ro',
  doc => 'if enable, will fork and exit (default false)',
);

option debug => (
  is  => 'ro',
  doc => 'if enable, will run Fuse::Simple in debug mode (default false)',
);

option cached => (
  is  => 'ro',
  doc => 'if enable, will cached the picture instead choose another each open (default false)',
);

sub _get_cat_picture {
  my $self = shift;
  state $cached_content;
  
  if($self->cached && $cached_content){
    return $cached_content;
  }

  my $content = try { 
    LWP::Simple::get($self->cat_url) 
  } catch {
    carp $_ if $self->debug;
  };

  if($self->cached){
    $cached_content = $content
  }

  $content
}

sub run {
  my ($self) = @_;

  if($self->forking){
    fork and exit  
  }

  my $mountpoint = $self->mountpoint;
  my $cat_file   = $self->cat_file;

  say "Initializing Fuse mountpoint '$mountpoint'... ";

  Fuse::Simple::main(
    mountpoint => $mountpoint,
    debug      => $self->debug,
    '/'        => {
      $cat_file => sub {
        $self->_get_cat_picture
      },
    },
  );
}

END {
   say "Don't forget run 'fusermount -u <mountpoint>'"
}

=head1 NAME

Acme::CatFS

=head1 SYNOPSIS

  Acme::CatFS->new(mountpoint => '/tmp/catfs', debug => 0, cat_file => 'kitten.jpg')->run();

=head1 DESCRIPTION

Acme::CatFS will create a Fuse mountpoint and generate one virtual file, a random image of a cat. Will return a different image each time.

It is the equivalent to:

  Fuse::Simple::main(
    mountpoint => $mountpoint,
    "/"        => {
      'cat.jpg' => sub {
          LWP::Simple::get('http://thecatapi.com/api/images/get?format=src&type=jpg');
       },
    },
  );

=head1 METHODS

=head2 run

Will initialize the Fuse mountpoint.

=head1 SCRIPT

You can call acme-catfs helper script in you command line to easily create the mountpoint. Try C<acme-catfs -h> to see the options.


=head1 ATTRIBUTES

=head2 mountpoint

Specify the directory mountpoint for Fuse. Should be an empty directory.

=head2 cat_url

Specify the url for the random pic of cat. Default is 'thecatapi.com' service.

=head2 cat_file

Specify the name of the file. Default is 'cat.jpg'

=head2 debug

If true, will run Fuse::Simple::main in debug mode.

=head2 forking

If true, we will fork then exit.

=head2 cached

if true, we will cache the cat picture instead download a new one.

=head1 SEE ALSO

L<Fuse::Simple> and L<Fuse>

=head1 ACKNOWLEDGE

Thanks to Julia Evans (twitter => @b0rk, blog => L<http://jvns.ca/>) with the original idea and support on twitter. And Nick Waterman (pause => NOSEYNICK) by L<Fuse::Simple> module - it is awesome!

=head1 AUTHOR

Tiago Peczenyj, E<lt>tiago.peczenyj@gmail.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Tiago Peczenyj

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
