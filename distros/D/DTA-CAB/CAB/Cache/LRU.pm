## -*- Mode: CPerl -*-
##
## File: DTA::CAB::Cache::LRU.pm
## Author: Bryan Jurish <moocow@cpan.org>
## Description: generic least-recently-used cache

package DTA::CAB::Cache::LRU;
use Carp;
use strict;

##==============================================================================
## Globals
##==============================================================================

our @ISA = qw();

##==============================================================================
## Constructors etc.
##==============================================================================

## $cache = CLASS_OR_OBJ->new(%args)
##  + %args, %$cache:
##    {
##     ##-- user data
##     max_size => $nelts,     ##-- maximum number of elements to cache; default=128
##     get_cb   => \&code,     ##-- subroutine called to generate key value as $data=$code->($key) ; default=none
##     autohit   => $bool,     ##-- whether or not to implicitly call hit() on get() and set(); default=1
##     ##
##     ##-- low-level data
##     #size     => $nelts,      ##-- current cache size (may differ from scalar(@pos2key), scalar(@pos2val) b/c some array items may be undef)
##     offset   => $pos,        ##-- index of least recently used item == next available index for new item
##     key2pos  => \%key2pos,   ##-- $pos=$key2pos{$key}: maps key to item-position
##     pos2val  => \@values,    ##-- $val=$pos2val[$pos]: maps item-position to value (or undef)
##     pos2key  => \@keys,      ##-- $key=$pos2key[$pos]: maps item-position to key   (or undef)
##    }
sub new {
  my $that = shift;
  my $cache = bless({
		     max_size => 128,
		     get_cb => undef,
		     autohit   => 1,

		     #size    => 0,
		     offset  => 0,
		     key2pos => {},
		     pos2val => [],
		     pos2key => [],
		     @_,
		    }, ref($that)||$that);
  return $cache->resize($cache->{max_size});
}

## $cache = $cache->clear()
##  + clears cache
sub clear {
  my $cache = shift;
  #$cache->{size} = 0;
  $cache->{offset} = 0;
  %{$cache->{key2pos}} = qw();
  @{$cache->{pos2val}} = qw();
  @{$cache->{pos2key}} = qw();
  $cache->{pos2val}[$cache->{max_size}-1]=undef; ##-- implicit auto-grow
  $cache->{pos2key}[$cache->{max_size}-1]=undef; ##-- implicit auto-grow
  return $cache;
}

## $cache = $cache->resize($max_size)
##  + resize the cache
##  + implicitly clears the cache
sub resize {
  my ($cache,$max_size) = @_;
  $cache->{max_size} = $max_size;
  return $cache->clear();
}

##==============================================================================
## Methods: API
##==============================================================================

## $n = $cache->size()
##  + number of stored items
##  + TODO
#sub size {
#  return $_[0]{size};
#}

## $bool = $cache->exists($key)
##  + returns true if cache has a stored value for $key
sub exists {
  return CORE::exists($_[0]{key2pos}{$_[1]});
}

## $pos = $cache->getpos($key)
##  + returns cache position for $key, or undef if $key is not in cache
sub getpos {
  return $_[0]{key2pos}{$_[1]};
}

## $offset = $cache->incr()
##  + increments offset
sub incr {
  $_[0]{offset} = ($_[0]{offset}+1) % $_[0]{max_size};
}

## $val_or_undef = $cache->get($key, %opts)
##  + %opts:
##     get_cb => \&code,     ##-- get callback (locally overrides $cache->{get_cb})
##     autohit => $bool,     ##-- locally override $cache->{autohit}
sub get {
  my ($cache,$key,%opts) = @_;
  foreach (qw(get_cb autohit)) {
    $opts{$_} = $cache->{$_} if (!exists($opts{$_}));
  }

  my $pos = $cache->{key2pos}{$key};
  my ($val);
  if (defined($pos)) {
    ##-- cached value
    $val = $cache->{pos2val}[$pos];
    $cache->hit($key,$pos) if ($opts{autohit});
  }
  elsif (defined($opts{get_cb})) {
    ##-- user callback
    $val = $opts{get_cb}->($key);
    $cache->set($key,$val,%opts);
  }
  return $val;
}

## $val = $cache->_get($key, %opts)
##  + wrapper for $cache->get($key, %opts, autohit=>0)
sub _get {
  return $_[0]->get(@_[1..$#_], autohit=>0);
}

## $val = $cache->set($key, $val, %opts)
##  + sets value for $key
##  + implicitly calls $cache->hit($key) and $cache->clean(%opts)
##  + returns index position
sub set {
  my ($cache,$key,$val, %opts) = @_;
  foreach (qw(autohit autoclean)) {
    $opts{$_} = $cache->{$_} if (!exists($opts{$_}));
  }
  my $pos = $cache->{key2pos}{$key};
  if (defined($pos)) {
    ##-- key already cached: just set value
    $cache->{pos2val}[$pos] = $val;
    $cache->hit($key,$pos) if ($opts{autohit});
  } else {
    ##-- key not cached yet: insert new value at LRU position
    $pos = $cache->{offset};
    $cache->remove(undef,$pos);
    $cache->insert($key,$val,$pos);
    $cache->incr();
  }

  return $val;
}

## $pos = $cache->_set($key, $val, %opts)
##  + wrapper for $cache->set($key,$val,%opts,autohit=>0)
sub _set {
  return $_[0]->set(@_[1..$#_],autohit=>0);
}

## $cache = $cache->insert($key,$val,$pos)
##  + insert ($key=>$val) at position $pos
##  + low-level method; no offset-modification is done
sub insert {
  my ($cache,$key,$val,$pos) = @_;
  $cache->{pos2key}[$pos] = $key;
  $cache->{pos2val}[$pos] = $val;
  $cache->{key2pos}{$key} = $pos;
  return $cache;
}

## $cache = $cache->remove($key)
## $cache = $cache->remove($key,  $pos)
## $cache = $cache->remove(undef, $pos)
##  + remove an item from the cache by key and/or position
sub remove {
  my ($cache,$key,$pos) = @_;
  $pos = $cache->{key2pos}{$key} if (!defined($pos));
  $key = $cache->{pos2key}[$pos] if (!defined($key));
  delete($cache->{key2pos}{$key}) if (defined($key));
  if (defined($pos)) {
    $cache->{pos2val}[$pos]=undef;
    $cache->{pos2key}[$pos]=undef;
    #$cache->{offset} = ($pos+1) % $cache->{max_size} if ($pos==$cache->{offset}); ##-- increment LRU position if required
  }
  return $cache;
}

## $cache = $cache->hit($key)
## $cache = $cache->hit($key,$oldpos)
##  + promotes $key to most recently used
sub hit {
  my ($cache,$key,$oldpos) = @_;
  $oldpos = $cache->{key2pos}{$key} if (!defined($oldpos));
  return $cache if (!defined($oldpos) || $oldpos == (($cache->{offset}-1) % $cache->{max_size})); ##-- no update required
  my $newpos = $cache->{offset};
  my $val    = $cache->{pos2val}[$oldpos];
  $cache->remove(undef,$newpos);
  $cache->remove($key, $oldpos);
  $cache->insert($key, $val, $newpos);
  $cache->incr();
  return $cache;
}


1; ##-- be happy

__END__
