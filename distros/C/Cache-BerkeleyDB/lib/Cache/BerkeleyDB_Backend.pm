package Cache::BerkeleyDB_Backend;

our $VERSION = '0.03';

use strict;
use Storable qw(freeze thaw);
use BerkeleyDB;
use Fcntl qw(:DEFAULT);

my $Caches = {};

sub new {
	my ($class, $root, $namespace) = @_;
	$namespace = _canonic_namespace($namespace);
	$class = ref $class if ref $class;
	my $obj = _initial_tie($root,$namespace);
	my $self = { _filename   => $obj->{filename},
				 _cache_root => $root,
				 _namespace  => $namespace };
	$self = bless($self, $class);
	return $self;
}

sub _initial_tie {
	my ($root,$namespace) = @_;
	$root ||= '/tmp';
	$namespace ||= 'Default';
	return $Caches->{$namespace} if $Caches->{$namespace};
	my $env = new BerkeleyDB::Env(
								  -Home => $root,
								  -Flags => DB_INIT_CDB | DB_CREATE | DB_INIT_MPOOL,
								 )
	  or die "Can't create BerkeleyDB::Env (home=$root): $BerkeleyDB::Error";
	my $fn = "$root/$namespace.bdbcache";
	my $obj = BerkeleyDB::Btree->new(
	  -Filename => $fn,
	  -Flags    => DB_CREATE,
	  -Mode     => 0666,
	  -Env      => $env, )
		or die "Can't tie to $root/$namespace.bdbcache";
	$Caches->{$namespace} = {};
	$Caches->{$namespace}->{obj}       = $obj;
	$Caches->{$namespace}->{filename}  = $fn;
	$Caches->{$namespace}->{namespace} = $namespace;
	return $Caches->{$namespace};
}

sub _canonic_namespace {
	my $namespace = shift;
	$namespace =~ s/[^A-Za-z0-9\-_\+]/+/g;
	$namespace = substr($namespace,0,56) if length($namespace)>56;
	return $namespace;
}

sub _retie {
	my ($self, $namespace) = @_;
	$namespace ||= 'Default';
	return if $namespace eq $self->{_namespace};
	my $obj = _initial_tie($self->{_cache_root},$namespace);
	$self->{_filename} = $obj->{filename};
	$self->{_namespace} = $namespace;
}

sub get_root {
	my $self = shift;
	return $self->{_cache_root};
}

sub set_root {
	my ($self,$root) = @_;
	$root ||= '/tmp';
	return $root if $self->{_cache_root} eq $root;
	$self->{_cache_root} = $root;
	$Caches = {};
	my $obj = _initial_tie($root,$self->{_namespace});
	$self->{_filename} = $obj->{filename};
	return $root;
}

sub delete_key {
	my ($self, $namespace, $key) = @_;
	$self->_retie($namespace);
	$self->_get_obj->db_del($key);
}

sub delete_namespace {
	my $self = shift;
	my $count = 0;
	$self->_get_obj->truncate($count);
	return $count;
}

sub get_keys {
	my ($self, $namespace) = @_;
	$self->_retie($namespace);
	my $db = $Caches->{ $self->{_namespace} }->{obj};
	my ($k,$v) = ('','');
	my @keys = ();
	my $cursor = $db->db_cursor();
	while ($cursor->c_get($k, $v, DB_NEXT) == 0) {
		push @keys, $k;
	}
	undef $cursor;
	return @keys;
}

sub get_namespaces {
	my $self = shift;
	opendir DIR, $self->{_cache_root} or return;
	my @ns = ();
	while (my $fn = readdir DIR) {
		push @ns, $fn if $fn =~ s/\.bdbcache$//;
	}
	closedir DIR;
	return @ns;
}

sub get_size {
	my ($self, $namespace, $key) = @_;
	$self->_retie($namespace);
	my $val;
	$self->_get_obj->db_get( $key, $val);
	return defined $val ? length($val) : undef;
}

sub _get {
	my ($self,$key) = @_;
	my $val;
	my $rc = $self->_get_obj->db_get( $key, $val);
	my $ret = eval { thaw($val) };
	return $ret;
}

sub _get_obj {
	my $self = shift;
	return $Caches->{ $self->{_namespace} }->{obj};
}

sub _set {
	my ($self,$key,$val) = @_;
	$self->_get_obj->db_put($key, freeze($val));
}

sub restore {
	my ($self,$namespace,$key) = @_;
	$self->_retie($namespace);
	return $self->_get($key);
}

sub store {
	my ($self,$namespace,$key,$val) = @_;
	$self->_retie($namespace);
	$self->_set($key,$val);
}


1;

__END__

=pod

=head1 NAME

Cache::BerkeleyDB_Backend -- persistance mechanism based on BerkeleyDB

=head1 DESCRIPTION

The BerkeleyDB_Backend class is used to persist data to a BerkeleyDB
file.

=head1 SYNOPSIS

  my $backend = new Cache::BerkeleyDB_Backend( );

  See Cache::FileBackend or Cache::MemoryBackend for the usage
  synopsis.

=head1 METHODS

See Cache::FileBackend for the API documentation.

=head1 SEE ALSO

Cache::BerkeleyDB.

=head1 AUTHOR

Baldur Kristinsson <bk@mbl.is>, January 2006.

 Copyright (c) 2006 Baldur Kristinsson. All rights reserved.
 This program is free software; you can redistribute it and/or
 modify it under the same terms as Perl itself.

=cut

