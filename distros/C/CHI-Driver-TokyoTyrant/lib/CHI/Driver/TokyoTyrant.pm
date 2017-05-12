package CHI::Driver::TokyoTyrant;

use strict;
use warnings;

use Moose;
use TokyoTyrant;

use Carp qw(croak);

use utf8;

extends 'CHI::Driver';

our $VERSION = '0.02';

has 'rdb'      => ( is => 'rw', init_arg => undef, lazy_build => 1);
has 'hostname' => ( is => 'ro', required => 1, default => 'localhost' );
has 'port'     => ( is => 'ro', required => 1, default => '1978');

__PACKAGE__->meta->make_immutable();

sub _build_rdb {
  my ( $self,) = @_;

  my $rdb = TokyoTyrant::RDB->new();

  die "Cannot instantiate TokyoTyrant::RDB $@" unless $rdb;


  # connect to the server
  if(!$rdb->open($self->hostname, $self->port)){
    my $ecode = $rdb->ecode();
    die  $rdb->errmsg($ecode);
  }

  return $rdb;

}

sub DEMOLISH {
  my $self = shift;

  $self->rdb->close() if $self->{rdb};
}




sub fetch {
  my ( $self, $key ) = @_;


  my $value = $self->rdb->get($self->namespace . ':' .  $key);


  return $value;


}

sub store {

  my ( $self, $key, $data ) = @_;


  if (!$self->rdb->put($self->namespace . ':' .  $key, $data)) {

    my $ecode = $self->rdb->ecode();

    die $self->rdb->errmsg($ecode);
}


}

sub remove {
  my ( $self, $key ) = @_;


  if (! $self->rdb->out($self->namespace . ':' .  $key) ) {


    my $ecode = $self->rdb->ecode();

    die $self->rdb->errmsg($ecode);

  }

}

sub clear {
  my ($self) = @_;

  my $namespace = $self->namespace;

  my $keys = $self->rdb->fwmkeys($namespace . ":", -1);

  $self->rdb->misc('outlist', $keys);

}


sub get_keys {
  my ($self) = @_;


  $self->rdb->iterinit();

  my $namespace = $self->namespace;

  my $keys = $self->rdb->fwmkeys($namespace . ":", -1);
  my $l = length($namespace)+1;

  my @keys = map { substr($_,$l) } @$keys;

  return @keys;

}


sub get_namespaces {
  my ($self) = @_;


  $self->rdb->iterinit();


  my %namespaces;
  while(defined(my $key = $self->rdb->iternext())){
    my ($namespace) = $key =~ /^(.+):/;
    $namespace ||= '';
    $namespaces{$namespace}++;
  }
   

  return sort keys %namespaces;

}

sub fetch_multi_hashref {

  my ($self, $keys) = @_;

  my $namespace = $self->namespace;
  my @keys = map {"${namespace}:$_"} @$keys;

  my $out = $self->rdb->misc('getlist', \@keys) ||
    die $self->rdb->errmsg($self->rdb->ecode);

  my $l = length($namespace)+1;
  my $c = 0;
  my %res = map { $c++ % 2 ? $_ : substr($_,$l) } @{$out};
  return \%res; 
}

1;


__END__

=pod

=head1 NAME

CHI::Driver::TokyoTyrant -- Distributed cache via Tokyo Tyrant - a network interface to the DBM  Tokyo Cabinet.

=head1 SYNOPSIS

    use CHI;

    my $cache = CHI->new(
        driver => 'TokyoTyrant',
        namespace => 'products',
        hostname  => 'localhost',
        port      => 1978,
    );

=head1 DESCRIPTION

A CHI driver that uses Tokyo Tyrant as a storage backend.
As Tokyo Tyrant 
Tokyo Tyrant also supports Memcached protocol so other option is to use it with Memcached driver.
This driver is much faster though.

=head1 CONSTRUCTOR OPTIONS

Namespaces are handled by prepending namespace to the key.
Hostname defaults to localhost and port to 1978.


=head1 METHODS

Besides the standard CHI methods:

=over

=item rdb

Returns a handle to the underlying TokyoTyrant::RDB object. You can use this
to call specific methods that are not supported by the general API.

=back

=head1 AUTHOR

Jiří Pavlovský

=head1 SEE ALSO

L<CHI|CHI> L<CHI::Driver::Memcached::Fast>, L<CHI::Driver::Memcached>

Documentation, API libraries for Tokyo Tyrant and Tokyo Cabinet can be found at: http://1978th.net

=head1 COPYRIGHT & LICENSE

Copyright (C) 2010 Jiří Pavlovský.

CHI::Driver::TokyoTyrant is provided "as is" and without any express or implied
warranties, including, without limitation, the implied warranties of
merchantibility and fitness for a particular purpose.

This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
