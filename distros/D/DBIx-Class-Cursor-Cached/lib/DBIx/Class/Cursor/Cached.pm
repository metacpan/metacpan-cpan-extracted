package DBIx::Class::Cursor::Cached;

use strict;
use warnings;
use 5.008001;
use Storable ();
use Digest::SHA ();
use Carp::Clan qw/^DBIx::Class/;

use vars qw($VERSION);

$VERSION = '1.001004';

sub new {
  my $class = shift;
  my ($storage, $args, $attrs) = @_;
  $class = ref $class if ref $class;
  # This gives us the class the storage object -would- have used
  # (since cursor_class is inherited Class::Accessor::Grouped type)
  my $inner_class = (ref $storage)->cursor_class;
  my $inner = $inner_class->new(@_);
  if ($attrs->{cache_for}) {
    my %args = (
      inner => $inner,
      cache_for => delete $attrs->{cache_for},
      cache_object => delete $attrs->{cache_object},
      # this must be here to ensure the deletes have happened
      cache_key => $class->_build_cache_key(@_),
      pos => 0
    );
    return bless(\%args, $class);
  }
  return $inner; # return object that -would- have been constructed.
}

sub next {
  my ($self) = @_;
  return @{($self->{data} ||= $self->_fill_data)->[$self->{pos}++]||[]};
}

sub all {
  my ($self) = @_;
  return @{$self->{data} ||= $self->_fill_data};
}

sub reset {
  shift->{pos} = 0;
}

sub _build_cache_key {
  my ($class, $storage, $args, $attrs) = @_;
  # compose the query and bind values, like as_query(),
  # so the cache key is only affected by what the database sees
  # and not any other cruft in $attrs
  my $ref = $storage->_select_args_to_query(@{$args}[0..2], $attrs);

  my $conn;
  if (! ($conn = $storage->_dbh) ) {
    my $connect_info = $storage->_dbi_connect_info;
    if (! ref($connect_info->[0]) ) {
      $conn = { Name => $connect_info->[0], Username => $connect_info->[1] };
    } else {
      carp "Invoking connector coderef $connect_info->[0] in order to obtain cache-lookup information";
      $conn = $connect_info->[0]->();
    }
  }

  return $class->_build_cache_key_hash([ $ref, $conn->{Name}, $conn->{Username} || '' ]);
}

sub _build_cache_key_hash {
  my ($class, $key_data) = @_;
  local $Storable::canonical = 1;
  return Digest::SHA::sha1_hex(Storable::nfreeze( $key_data ));
}

sub _fill_data {
  my ($self) = @_;
  my $cache = $self->{cache_object};
  my $key = $self->{cache_key};
  return $cache->get($key) || do {
    my $data = $self->_fill_data_fetch_all();
    $cache->set($key, $data, $self->{cache_for});
    $data;
  };
}

sub _fill_data_fetch_all {
    my ($self) = @_;
    return [ $self->{inner}->all ];
}

sub clear_cache {
  my ($self) = @_;
  $self->{cache_object}->remove($self->{cache_key});
  delete $self->{data};
}

sub cache_key { shift->{cache_key} }

1;

=head1 NAME

DBIx::Class::Cursor::Cached - cursor class with built-in caching support

=head1 SYNOPSIS

  my $schema = SchemaClass->connect(
    $dsn, $user, $pass, { cursor_class => 'DBIx::Class::Cursor::Cached' }
  );

  $schema->default_resultset_attributes({
    cache_object => Cache::FileCache->new({ namespace => 'SchemaClass' }),
  });

  my $rs = $schema->resultset('CD')->search(undef, { cache_for => 300 });

  my @cds = $rs->all; # fills cache

  $rs = $schema->resultset('CD')->search(undef, { cache_for => 300 });
    # refresh resultset

  @cds = $rs->all; # uses cache, no SQL run

  $rs->cursor->clear_cache; # deletes data from cache

  @cds = $rs->all; # refills cache

=head1 AUTHOR

Matt S Trout <mst@shadowcat.co.uk> http://www.shadowcat.co.uk/

Initial development sponsored by and (c) Takkle, Inc. 2007

=head1 LICENSE

This library is free software under the same license as perl itself

=cut
