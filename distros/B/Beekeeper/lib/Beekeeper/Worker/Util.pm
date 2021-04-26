package Beekeeper::Worker::Util;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME
 
Beekeeper::Worker::Util
 
=head1 VERSION
 
Version 0.01

=head1 SYNOPSIS

  use Beekeeper::Worker::Util 'shared_cache';
  
  my $c = $self->shared_cache( ... );
  
  $c->set( $key => $value );
  $c->get( $key );
  $c->delete( $key );

=head1 DESCRIPTION

=cut

use Beekeeper::Worker::Util::SharedCache;

use Exporter 'import';

our @EXPORT = qw( shared_cache );


sub shared_cache {
    my ($self, %args) = @_;

    my $shared = Beekeeper::Worker::Util::SharedCache->new( worker => $self, %args );

    return $shared;
}

1;

=encoding utf8

=head1 AUTHOR

José Micó, C<jose.mico@gmail.com>

=head1 COPYRIGHT AND LICENSE

Copyright 2015 José Micó.

This is free software; you can redistribute it and/or modify it under the same 
terms as the Perl 5 programming language itself.

This software is distributed in the hope that it will be useful, but it is 
provided “as is” and without any express or implied warranties. For details, 
see the full text of the license in the file LICENSE.

=cut
