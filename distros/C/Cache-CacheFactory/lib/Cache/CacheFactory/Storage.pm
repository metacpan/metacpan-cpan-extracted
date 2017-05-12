###############################################################################
# Purpose : Cache Storage Policy Factory.
# Author  : Sam Graham
# Created : 23 Jun 2008
# CVS     : $Id: Storage.pm,v 1.9 2010-02-16 12:25:41 illusori Exp $
###############################################################################

package Cache::CacheFactory::Storage;

use warnings;
use strict;

use Class::Factory;

use base qw/Class::Factory/;

$Cache::CacheFactory::Storage::VERSION = '1.10';

sub new
{
    my ( $this, $type, @params ) = @_;
    my ( $class );

    $class = $this->get_factory_class( $type );
    return( undef ) unless $class;
    return( $class->new( @params ) );
}

__PACKAGE__->register_factory_type(
    memory       => 'Cache::MemoryCache' );
__PACKAGE__->register_factory_type(
    sharedmemory => 'Cache::SharedMemoryCache' );
__PACKAGE__->register_factory_type(
    file         => 'Cache::FileCache' );
__PACKAGE__->register_factory_type(
    null         => 'Cache::NullCache' );
__PACKAGE__->register_factory_type(
    fastmemory   => 'Cache::FastMemoryCache' );

1;

__END__

=pod

=head1 NAME

Cache::CacheFactory::Storage - Factory class for storage policies for Cache::CacheFactory.

=head1 DESCRIPTION

L<Cache::CacheFactory::Storage> is a class factory for
storage policies used by L<Cache::CacheFactory>.

You will only need to know about this module if you're
writing your own storage policy modules, documented in
L<Cache::CacheFactory/"WRITING NEW POLICIES">.

=head1 METHODS

=over

=item $policy = Cache::CacheFactory::Storage->new( $type, @param );

Construct an storage policy of the specified type, supplying C<@param>
to the constructor of the policy object.

=back

=head1 SEE ALSO

L<Cache::CacheFactory>, L<Class::Factory>

=head1 AUTHORS

Original author: Sam Graham <libcache-cachefactory-perl BLAHBLAH illusori.co.uk>

Last author:     $Author: illusori $

=head1 COPYRIGHT

Copyright 2008-2010 Sam Graham.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=cut
