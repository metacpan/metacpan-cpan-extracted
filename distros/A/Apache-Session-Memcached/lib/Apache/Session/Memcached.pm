package Apache::Session::Memcached;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(Apache::Session);

use Apache::Session::Generate::MD5;
use Apache::Session::Lock::Null;
use Apache::Session::Serialize::Storable;
use Apache::Session::Store::Memcached;

sub populate {
	my $self = shift;
	$self->{object_store} = Apache::Session::Store::Memcached->new($self);
	$self->{lock_manager} = Apache::Session::Lock::Null->new($self);
	$self->{generate}     = \&Apache::Session::Generate::MD5::generate;
	$self->{validate}     = \&Apache::Session::Generate::MD5::validate;
	$self->{serialize}    = \&Apache::Session::Serialize::Storable::serialize;
	$self->{unserialize}  = \&Apache::Session::Serialize::Storable::unserialize;
	return $self;
}

1;
__END__

=head1 NAME

Apache::Session::Memcached - Stores persistent data using memcached (memory
cache daemon) for Apache::Session storage

=head1 SYNOPSIS

   use Apache::Session::Memcached;
   tie %session, 'Apache::Session::Memcached', $sid, {
      Servers => '10.0.0.1:20000 10.0.0.2:20000',
      NoRehash => 1,
      Readonly => 0,
      Debug => 1,
      CompressThreshold => 10_000
   };

=head1 DESCRIPTION

Apache::Session::Memcached is a bridge between Apache::Session and
memcached, a distributed memory cache daemon.

More informations about memcached are available at
L<http://www.danga.com/memcached>.

This module provides a way to use Cache::Memcached (memcached Perl API) as
Apache::Session storage implementation.

=head1 INSTALLATION

In order to install and use this package you will need Perl version 5.005 or
better.

Prerequisites:

=over 4

=item * Apache::Session >= 1.54

=item * Cache::Memcached >= 1.14

=back

Installation as usual:

   %> perl Makefile.PL
   %> make
   %> make test
   %> make install

Note: for live tests, you must run at least a memcached daemon and you could
need to edit t/CONFIG file, in order to set correct parameters used for
testing. 

=head1 SEE ALSO

L<Apache::Session::Store::Memcached|Apache::Session::Store::Memcached>,
L<Apache::Session|Apache::Session>,
L<Apache::Session::Flex|Apache::Session::Flex>,
L<Cache::Memcached|Cache::Memcached>, L<memcached>.

=head1 AUTHOR

Enrico Sorcinelli E<lt>enrico at sorcinelliE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Enrico Sorcinelli

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.1 or,
at your option, any later version of Perl 5 you may have available.

=cut
