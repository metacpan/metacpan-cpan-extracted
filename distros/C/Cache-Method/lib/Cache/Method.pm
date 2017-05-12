package Cache::Method;
use strict;
use warnings;
use parent 'Teng';
use Digest::MD5   qw/ md5_hex /;
use Storable      qw/ freeze thaw /;
use Hook::LexWrap qw/ wrap /;
use Scalar::Util  qw/ blessed /;

our $VERSION = "0.03";
our $CACHE_TABLE_NAME = 'cache';

sub new {
  my $class = shift;
  my %args = @_ == 1 ? %{$_[0]} : @_;
  $args{dbfile} ||= '';
  $args{dbh} ||= DBI->connect(
    "dbi:SQLite:$args{dbfile}",
    undef,
    undef,
    { RaiseError => 1 }
  );
  my $self = Teng::new($class, %args);
  $self->do(qq{
    CREATE TABLE IF NOT EXISTS $CACHE_TABLE_NAME (
      id       INTEGER PRIMARY KEY AUTOINCREMENT,
      method   VARCHAR NOT NULL,
      checksum VARCHAR,
      result   VARCHAR
    )
  });
  return $self;
}

sub set {
  my $self = shift;
  for my $method (@_) {
    $self->_wrap(caller.'::'.$method);
  }
}

sub _wrap {
  my ($self, $method) = @_;
  wrap $method,
    pre => sub {
      my @args = @_;
      shift @args if blessed $args[0];
      my $arg0 = $args[0];
      shift @args if $method =~ /^$arg0/;
      $args[-1] = wantarray;
      my $row = $self->single($CACHE_TABLE_NAME, {
        method   => $method,
        checksum => (md5_hex freeze \@args)
      });
      $_[-1] = ${thaw $row->result} if $row;
    },
    post => sub {
      my @args = @_;
      shift @args if blessed $args[0];
      $args[-1] = wantarray;
      my $return = $_[-1];
      return unless defined wantarray;
      $self->insert($CACHE_TABLE_NAME, {
        method   => $method,
        checksum => (md5_hex freeze \@args),
        result   => freeze \$return
      });
    };
}

sub DESTROY {
  my $self = shift;
  $self->dbh->disconnect if $self->dbh;
}


package Cache::Method::Schema;
use Teng::Schema::Declare;

table {
  name $CACHE_TABLE_NAME;
  pk 'id';
  columns qw/id method checksum result/;
};


1;
__END__

=encoding utf-8

=head1 NAME

Cache::Method - Cache the execution result of your method.

=head1 SYNOPSIS

=head2 Cache on memory

  use Cache::Method;

  Cache::Method->new->set('foo');

  sub foo { ... }

  print foo(); #=> Execute foo
  print foo(); #=> Cached result

=head2 Cache on SQLite

  use Cache::Method;

  my $cache = Cache::Method->new( dbfile => 'cache.db' );
  $cache->set('foo');

  sub foo { ... }

=head1 DESCRIPTION

Cache::Method caches the execution result of your method.
You are able to store cache data to SQLite.

=head1 LICENSE

Copyright (C) Hoto.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Hoto E<lt>hoto@cpan.orgE<gt>

=cut

