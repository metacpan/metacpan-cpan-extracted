package Cache::BerkeleyDB;

our $VERSION = '0.03';

use strict;
use vars qw( @ISA );
use Cache::BaseCache;
use Cache::Cache;
use Cache::CacheUtils qw ( Assert_Defined Static_Params );
use Cache::BerkeleyDB_Backend;

@ISA = qw ( Cache::BaseCache );

my $DEFAULT_CACHE_ROOT   = "/tmp";
my $DEFAULT_NAMESPACE    = 'Default';
my $DEFAULT_UMASK        = 0002;

sub Clear {
	my ($self,$cache_root) = _chkparm(@_);
	foreach my $ns ($self->_get_backend->get_namespaces) {
		_get_cache( $ns, $cache_root )->clear;
	}
}

sub Purge {
	my ($self,$cache_root) = _chkparm(@_);
	foreach my $ns ($self->_get_backend->get_namespaces) {
		_get_cache( $ns, $cache_root )->purge;
	}
}

sub Size {
	my ($self,$cache_root) = _chkparm(@_);
	my $size;
	foreach my $ns ($self->_get_backend->get_namespaces) {
		$size += _get_cache( $ns, $cache_root )->size;
	}
	return $size;
}

# For methods callable as either instance or class methods.
# This applies to Clear, Purge and Size.
sub _chkparm {
	my ($self,$cache_root) = @_;
	unless (ref $self) {
		$cache_root = $self;
		$self = new Cache::BerkeleyDB;
	}
	$cache_root ||= $self->{cache_root} || $DEFAULT_CACHE_ROOT;
	return ($self,$cache_root);
}

sub new {
	my ($class, $opt) = @_;
	$opt ||= {};
	$opt->{cache_root} ||= $DEFAULT_CACHE_ROOT;
	$opt->{namespace} ||= $DEFAULT_NAMESPACE;
	$opt->{umask} ||= $DEFAULT_UMASK;
	$class = ref $class if ref $class;
	my $self = $class->SUPER::_new( $opt );
	my $normal_umask = umask($opt->{umask});
	mkdir $opt->{cache_root}, 0777 unless -d $opt->{cache_root};
	$self->_set_backend(
						Cache::BerkeleyDB_Backend->new
						  ( $opt->{cache_root}, $opt->{namespace} )
					   );
	umask($normal_umask);
	$self->_complete_initialization;
	return $self;
}

sub _get_cache {
	my ($namespace, $cache_root) = Static_Params(@_);
	Assert_Defined($namespace);
	$cache_root ||= $DEFAULT_CACHE_ROOT;
	return Cache::BerkeleyDB->new({ namespace => $namespace,
									cache_root=> $cache_root });
}

sub get_cache_root {
	my $self = shift;
	return $self->_get_backend->get_root;
}

sub set_cache_root {
	my ($self,$cache_root) = @_;
	mkdir $cache_root, 0777 unless -d $cache_root;
	return $self->_get_backend->set_root($cache_root);
}

sub size {
	my $self = shift;
	my $back = $self->_get_backend;
	my @keys = $back->get_keys;
	return 0 unless @keys;
	my $size;
	$size += $back->get_size($back->{_namespace},$_) for @keys;
	return $size;
}


1;


__END__

=pod

=head1 NAME

Cache::BerkeleyDB -- implements the Cache::Cache interface.

=head1 DESCRIPTION

This module implements the Cache interface provided by the
Cache::Cache family of modules written by DeWitt Clinton. It provides
a practically drop-in replacement for Cache::FileCache.

As should be obvious from the name, the backend is based on
BerkeleyDB.

=head1 SYNOPSIS

  use Cache::BerkeleyDB;

  my $cache = new Cache::BerkeleyDB( { 'namespace' => 'MyNamespace',
                                       'default_expires_in' => 600 } );

  See Cache::Cache for the usage synopsis.

=head1 METHODS

See Cache::Cache for the API documentation. Only changes relative to
the standard methods are mentioned below.

=over

=item B<Clear( [$cache_root] )>

See Cache::Cache, with the optional I<$cache_root> parameter.

=item B<Purge( [$cache_root] )>

See Cache::Cache, with the optional I<$cache_root> parameter.

=item B<Size( [$cache_root] )>

See Cache::Cache, with the optional I<$cache_root> parameter.

=back

=head1 OPTIONS

See Cache::Cache for standard options.  Additionally, options are set
by passing in a reference to a hash containing any of the following
keys:

=over

=item I<cache_root>

The location in the filesystem that will hold the BDB files
representing the cache namespaces.  Defaults to /tmp unless explicitly
set.

=item I<umask>

The umask which will be active when any cache files are created.
Defaults to 002. Note that this will have no effect on existing files.

=back

=head1 PROPERTIES

See Cache::Cache for default properties.

=over

=item B<(get|set)_cache_root>

Acessor pair for the option I<cache_root> - see description above.

=back

=head1 SEE ALSO

=over

=item Cache::Cache

=item Cache::FileCache

=item BerkeleyDB

=item Cache::BerkeleyDB_Backend

=back

=head1 TODO

(1) The current version (0.03) uses the framework provided by the
Cache::Cache family of modules quite heavily. In particular, it relies
on Cache::BaseCache and Cache::Object for much of its
functionality. This has obvious advantages; it means, however, that
the extra speed gained by switching from the flat files of
Cache::FileCache to a BerkeleyDB backend is much reduced compared with
a top-to-bottom implementation utilizing the latter's strengths to the
full. Currently the speed gain relative to Cache::FileCache is in the
range of 200% to 350%; I'm confident this can be increased
significantly.

(2) Since each cache namespace is represented as a separate BDB file,
operating with (very) many namespaces in the same process may get you
in trouble. While this has not been verified yet, it may make this
version unsuitable for some uses, such as in an HTML::Mason
environment under mod_perl. Future versions will probably implement
multiple namespaces in the same file.

(3) The current version is Unix-specific. That will probably change.

=head1 AUTHOR

Baldur Kristinsson <bk@mbl.is>, January 2006.

 Copyright (c) 2006 Baldur Kristinsson. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut
