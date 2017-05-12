package Apache::Session::libmemcached;

use warnings;
use strict;

=head1 NAME

Apache::Session::libmemcached - An implementation of Apache::Session using
Memcached::libmemcache

=head1 VERSION

Version 0.01

=cut

our $VERSION = '0.01';

use base 'Apache::Session';

use Apache::Session::Store::libmemcached;
use Apache::Session::Lock::Null;
use Apache::Session::Generate::MD5;
use Apache::Session::Serialize::Storable;


=head1 SYNOPSIS

  use Apache::Session::libmemcache

  tie %hash, 'Apache::Session::libmemcache', $id, {
      servers => ['1.2.3.4:2100', '4.3.2.1:2100'],
      expiration => 300, # In seconds
      log_errors => 1,
  }

  # to enable a simple load balancing feature
  # and/or fail over
  tie %hash, 'Apache::Session::libmemcache', $id, {
     load_balance => [
        ['1.2.3.4:2100', '4.3.2.1:2100'],
        ['1.1.1.1:2100', '2.2.2.2:2100'],
     ],
     failover => 1,
     expiration => 300, # In seconds
     log_errors => 1,

 }

=head1 DESCRIPTION

This module is an implementation of Apache::Session. It uses the fast
L<Memcached::libmemcached> module to store sessions in memcached. See the
example, and the documentation for L<Apache::Session::libmemcached> for more
details.

=head1 METHODS

=head2 populate

Populate necessary object references and subroutine references.

=cut
sub populate {
    my ($self) = @_;

    $self->{object_store} = Apache::Session::Store::libmemcached->new($self);
    $self->{lock_manager} = Apache::Session::Lock::Null->new($self);
    $self->{generate} = \&Apache::Session::Generate::MD5::generate;
    $self->{validate} = \&Apache::Session::Generate::MD5::validate;
    $self->{serialize} = \&Apache::Session::Serialize::Storable::serialize;
    $self->{unserialize} = \&Apache::Session::Serialize::Storable::unserialize;

    return $self;
}

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Apache::Session::libmemcached


=head1 AUTHOR

Javier Uruen Val C<< <javi.uruen@gmail.com> >>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2010 Venda Ltd

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.


=cut

1; # End of Apache::Session::libmemcached
