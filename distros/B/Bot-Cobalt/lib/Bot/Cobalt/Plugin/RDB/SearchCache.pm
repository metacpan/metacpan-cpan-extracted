package Bot::Cobalt::Plugin::RDB::SearchCache;
$Bot::Cobalt::Plugin::RDB::SearchCache::VERSION = '0.021003';
## This is a fairly generic in-memory cache object.
##
## It's intended for use with Plugin::RDB, but will likely work for 
## just about situation where you want to store a set number of keys 
## mapping an identifier to an array reference.
##
## This can be useful for caching the results of deep searches against 
## Bot::Cobalt::DB instances, for example.
##
## This may get moved out to the core lib directory, in which case this 
## module will become a placeholder.

use 5.10.1;
use strictures 2;

use Time::HiRes ();

sub new {
  my $self = +{ Cache => +{} };
  my $class = shift;
  bless $self, $class;

  my %opts = @_;
  $self->MaxKeys($opts{MaxKeys} || 30);
 
  $self
}

sub cache {
  my ($self, $ckey, $match, $resultset) = @_;
  ## should be passed rdb, search str, and array of matching indices

  return unless defined $ckey and defined $match;
  $resultset = [] unless ref $resultset eq 'ARRAY';

  ## _shrink will do the right thing depending on size of cache
  ## (MaxKeys can be used to adjust cachesize per-rdb 'on the fly')
  $self->_shrink($ckey);
  
  $self->{Cache}->{$ckey}->{$match} = +{
    TS => Time::HiRes::time(),
    Results => $resultset,
  };
}

sub fetch {
  my ($self, $ckey, $match) = @_;
  
  return
    unless defined $ckey
    and defined $match
    and exists $self->{Cache}->{$ckey} 
    and $self->{Cache}->{$ckey}->{$match};

  my $ref = $self->{Cache}->{$ckey}->{$match};
  wantarray ? @{ $ref->{Results} } : $ref->{Results}
}

sub MaxKeys {
  my ($self, $max) = @_;
  return $self->{MAX_KEYS} = $max if defined $max;
  $self->{MAX_KEYS}
}

sub invalidate {
  my ($self, $ckey, $match) = @_;
  ## should be called on add/del operations 

  unless (defined $ckey) {
    ## invalidate all by not passing an arg
    $self->{Cache} = +{};
    return
  }

  return unless exists $self->{Cache}->{$ckey}
         and keys %{ $self->{Cache}->{$ckey} } ;

  return delete $self->{Cache}->{$ckey}->{$match}
    if defined $match;

  delete $self->{Cache}->{$ckey}
}

sub _shrink {
  my ($self, $ckey) = @_;
  
  return unless defined $ckey and ref $self->{Cache}->{$ckey};

  my $cacheref = $self->{Cache}->{$ckey};

  return unless scalar keys %$cacheref > $self->MaxKeys;

  my @cached = sort { 
      $cacheref->{$a}->{TS} <=> $cacheref->{$b}->{TS}
    } keys %$cacheref;
  
  my $deleted = 0;

  while (scalar keys %$cacheref > $self->MaxKeys) {
    my $nextkey = shift @cached;
    ++$deleted if delete $cacheref->{$nextkey};
  }

  $deleted
}

1;
__END__

=pod

=head1 NAME

Bot::Cobalt::Plugin::RDB::SearchCache - Simple in-memory cache

=head1 SYNOPSIS

  ## Add a SearchCache that allows 30 max keys:
  $self->{CacheObj} = Bot::Cobalt::Plugin::RDB::SearchCache->new(
    MaxKeys => 30,
  );
  
  ## Save some array of results/indexes to the cache obj:
  my $cache = $self->{CacheObj};
  $cache->cache('MyCache', $key, [ @results ] );
  
  ## Get it back later:
  my @results = $cache->fetch('MyCache', $key);
  ## ...or get the reference to the actual array:
  my $resultset = $cache->fetch('MyCache', $key);
  
  ## Data changed, invalidate this cache:
  $cache->invalidate('MyCache');
  
  ## Invalidate one entry:
  $cache->invalidate('MyCache', $key);

  ## Change the maximum number of keys on the fly:
  $cache->MaxKeys('40');
  ## ...or find out what the current max is:
  my $current_max = $cache->MaxKeys;

=head1 DESCRIPTION

B<SearchCache> is a very simplistic mechanism for storing some arrays of data 
in a hash with a set ceiling limit of keys.

If the number of keys in the specified cache grows above B<MaxKeys>, 
older entries will be removed from the hash to make room for the new 
set.

This can be useful for caching the result of deep searches against 
large L<Bot::Cobalt::DB> databases, for example.

This interface is used by L<Bot::Cobalt::Plugin::RDB> and 
L<Bot::Cobalt::Plugin::Info3>.

=head1 AUTHOR

Jon Portnoy <avenj@cobaltirc.org>

L<http://www.cobaltirc.org>

=cut
