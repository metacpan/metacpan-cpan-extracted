package Apache::Session::Store::CacheAny;

use strict;
use vars qw($VERSION);
$VERSION = '0.02';


sub new {
    my($class, $session) = @_;
    bless { cache => undef }, $class;
}

sub insert {
    my($self, $session) = @_;
    my $cache = $self->_cache($session);

    if ($cache->get_object($session->{data}->{_session_id})) {
	die "Object already exists in the data store.";
    }

    $cache->set($session->{data}->{_session_id} => $session->{serialized});
}

sub update {
    my($self, $session) = @_;
    my $cache = $self->_cache($session);
    $cache->set($session->{data}->{_session_id} => $session->{serialized});
}

sub materialize {
    my($self, $session) = @_;
    my $cache = $self->_cache($session);
    $session->{serialized} = $cache->get($session->{data}->{_session_id})
	or die "Object does not exist in data store.";
}

sub remove {
    my($self, $session) = @_;
    $self->_cache($session)->remove($session->{data}->{_session_id});
}

sub _cache {
    my($self, $session) = @_;
    unless ($self->{cache}) {
	# Tries to load implementation
	# We ignore "Can't locate" exception
	my $impl = $session->{args}->{CacheImpl};
	eval qq{require $impl};
	if ($@ && !$impl->can('new')) {
	    die "Failed to load $impl: $@";
	}

	# Different named parameter style here
	my %arg2opt = (
	    Namespace         => 'namespace',
	    DefaultExpiresIn  => 'default_expires_in',
	    AutoPurgeInterval => 'auto_purge_interval',
	    AutoPurgeOnSet    => 'auto_purge_on_set',
	    AutoPurgeOnGet    => 'auto_purge_on_get',
	    MaxSize           => 'max_size',
	    CacheRoot         => 'cache_root',
	    CacheDepth        => 'cache_depth',
	    DirectoryUmask    => 'directory_umask',
	);

	my %opt = map {
	    exists $session->{args}->{$_} ?
		($arg2opt{$_} => $session->{args}->{$_}) : ();
	} keys %arg2opt;
	$self->{cache} = $impl->new(\%opt);
    }
    $self->{cache};
}

1;
__END__

=head1 NAME

Apache::Session::Store::CacheAny - use Cache::* for Apache::Session storage

=head1 SYNOPSIS

  tie %auto_expire_session, 'Apache::Session::CacheAny', $sid, {
      CacheImpl => 'Cache::SizeAwareFileCache',
      DefaultExpiresIn => '2 hours',
  };

  # or use with another locking scheme!

  use Apache::Session::Flex;

  tie %hash, 'Apache::Session::Flex', $id, {
      Store     => 'CacheAny',
      Lock      => 'File',
      Generate  => 'MD5',
      Serialize => 'Storable',
      CacheImpl => 'Cache::SharedMemoryCache',
   };

=head1 DESCRIPTION

Apache::Session::Store::CacheAny implpements the storage interface for
Apache::Session. Session data is stored using one of Cache::Cache
imeplementations.

=head1 CONFIGURATIONS

This module wants to know standard options for Cache::Cache. You can
specify these options as Apache::Session's tie options like this:

  tie %size_aware_session, 'Apache::Session::CacheAny', $sid, {
      CacheImpl        => 'Cache::SizeAwareFileCache',
      Namespace        => 'apache-session-cacheany',
      DefaultExpiresIn => '2 hours',
      AutoPurgeOnGet   => 0,
      AutoPurgeOnSet   => 1,
      MaxSize          => 10_000,
      CacheRoot        => '/tmp',
      CacheDepth       => 3,
      DirectoryUmask   => 077,
  };

Note that spelling of options are slightly differernt from those for
Cache::Cache. Here is a conversion table.

  A::S::Store::CacheAny  => Cache::Cache
  -----------------------------------------
  Namespace              => namespace
  DefaultExpiresIn       => default_expires_in
  AutoPurgeInterval      => auto_purge_interval
  AutoPurgeOnSet         => auto_purge_on_set
  AutoPurgeOnGet         => auto_purge_on_get
  MaxSize                => max_size
  CacheRoot              => cache_root
  CacheDepth             => cache_depth
  DirectoryUmask         => directory_umask

See L<Cache::Cache> for details.

=head1 AUTHOR

Tatsuhiko Miyagawa <miyagawa@bulknews.net>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Apache::Session::CacheAny>, L<Apache::Session::Flex>, L<Cache::Cache>

=cut
