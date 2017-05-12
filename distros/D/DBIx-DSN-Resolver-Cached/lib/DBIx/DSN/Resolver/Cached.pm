package DBIx::DSN::Resolver::Cached;

use strict;
use warnings;
use parent qw/DBIx::DSN::Resolver Exporter/;
use Cache::Memory::Simple;
use Carp;

our $VERSION = '0.04';
our @EXPORT = qw/dsn_resolver/;
my %RR;

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $ttl = exists $args{ttl} ? delete $args{ttl} : 5;
    my $negative_ttl = exists $args{negative_ttl} ? delete $args{negative_ttl} : 1;
    my $cache = exists $args{cache} ? delete $args{cache} : Cache::Memory::Simple->new;
    my $resolver = sub {
        my $host = shift;
        if ( my $cached = $cache->get($host) ) {
            return if @$cached == 0;
            if ( exists $RR{$host} ) {
                $RR{$host}++;
                $RR{$host} = 0 if $RR{$host} >= scalar @$cached;
            } else {
                $RR{$host} = 0;
            }
            return $cached->[$RR{$host}]
        }
        my ($name,$aliases,$addrtype,$length,@addrs)= gethostbyname($host);
        if ( ! defined $name ) {
            $cache->set($host,[],$negative_ttl);
            return;
        }
        my @ipaddr = map { Socket::inet_ntoa($_) } @addrs;
        $cache->set($host,\@ipaddr,$ttl);
        $RR{$host} = int(rand(scalar @ipaddr));
        return $ipaddr[$RR{$host}];
    };
    $class->SUPER::new(
        resolver => $resolver
    );
}


our $RESOLVER;
sub dsn_resolver {
    my $dsn = shift;
    return unless $dsn;
    $RESOLVER ||= DBIx::DSN::Resolver::Cached->new();
    my $resolved = $RESOLVER->resolv($dsn)
        or croak "Can't resolv dsn: $dsn";
    return @_ ? ($resolved,@_) : $resolved;
}

1;

__END__

=head1 NAME

DBIx::DSN::Resolver::Cached - Cached resolver for DBIx::DSN::Resolver

=head1 SYNOPSIS

  use 5.10.0;
  use DBIx::DSN::Resolver::Cached;

  sub connect_db {
      state $resolver = DBIx::DSN::Resolver::Cached->new(
          ttl => 30,
          negative_ttl => 5,
      );
      my $dsn = $resolver->resolv('dbi:mysql:database=mytbl;host=myserver.example');
      DBI->connect($dsn,'user','password');
  }

=head1 DESCRIPTION

DBIx::DSN::Resolver::Cached is extension module of DBIx::DSN::Resolver.
This module allows CACHE resolver response, useful for reduce load of DNS.
DBIx::DSN::Resolver::Cached also supports DNS-RR

=head1 OPTIONS

=over 4

=item ttl: Int

positive cache ttl in seconds. (default: 5)

=item negative_ttl: Int

negative cache ttl in seconds. (default: 1)

=item cache: Object

Cache object, requires support get and set methods.
default: Cache::Memory::Simple is used

=back

=head1 FUNCTION

=over 4

=item dsn_resolver($dsn: Str)

shortcut function for 

  state $resolver = DBIx::DSN::Resolver::Cached->new();
  $resolver->resolv('dbi:mysql:database=mytbl;host=myserver.example')

To customize ttl, negative_ttl and cache object. override $DBIx::DSN::Resolver::Cached::RESOLVER

  my $other_ttl = DBIx::DSN::Resolver::Cached->new(
        ttl => ..
  );
  sub {
      local $DBIx::DSN::Resolver::Cached::RESOLVER = $other_ttl;
      dsn_resolver($dsn);
  }

=back

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 SEE ALSO

L<DBIx::DSN::Resolver>, L<Cache::Memory::Simple>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
