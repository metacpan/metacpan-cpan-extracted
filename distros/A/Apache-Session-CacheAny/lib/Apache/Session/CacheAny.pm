package Apache::Session::CacheAny;

use strict;
use vars qw($VERSION);
$VERSION = '0.03';

use base qw(Apache::Session);

use Apache::Session::Generate::MD5;
use Apache::Session::Lock::Null;
use Apache::Session::Serialize::Storable;
use Apache::Session::Store::CacheAny;

sub populate {
    my $self = shift;

    $self->{object_store} = Apache::Session::Store::CacheAny->new($self);
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

Apache::Session::CacheAny - use Cache::* for Apache::Session storage

=head1 SYNOPSIS

  use Apache::Session::CacheAny;
  tie %session, 'Apache::Session::CacheAny', $sid, {
      CacheImpl => 'Cache::FileCache',
  };

  tie %size_aware_session, 'Apache::Session::CacheAny', $sid, {
      CacheImpl        => 'Cache::SizeAwareFileCache',
      Namespace        => 'apache-session-cacheany',
      DefaultExpiresIn => '2 hours',
      AutoPurgeOnGet   => 0,
      AutoPurgeOnSet   => 1,
      MaxSize          => 10_000,
      CacheRoot        => 'cache_root',
      CacheDepth       => 'cache_depth',
      DirectoryUmask   => 'directory_umask',
  };

=head1 DESCRIPTION

Apache::Session::CacheAny is a bridge between Apache::Session and
Cache::Cache. This module provides a way to use Cache::Cache
subclasses as Apache::Session storage implementation.

=head1 ARGUMENTS

You must specify class name of Cache::Cache implementation (like
Cache::SharedMemoryCache) in arguments to the constructor. See
L<Apache::Session::Store::CacheAny> for details about other optional
arguments.

=head1 NOTE

Apache::Session::CacheAny uses Apache::Session::Lock::Null as its
locking scheme. This is not suitable when your apps need Transactional
Session Management. You can use Apache::Session::Flex to change this.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session>, L<Cache::Cache>

=cut
