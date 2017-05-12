package DBIx::DSN::Resolver;

use strict;
use warnings;
use DBI;
use Socket;
use Carp;

our $VERSION = '0.09';

sub new {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    bless {
        resolver => sub { 
            my $ipaddr = Socket::inet_aton($_[0]);
            return unless $ipaddr;
            Socket::inet_ntoa($ipaddr);
        },
        %args,
    }, $class;
}

sub resolv {
    my $self = shift;
    my $dsn = shift;
    return unless $dsn;

    my ($scheme, $driver, $attr_string, $attr_hash, $driver_dsn)
        = DBI->parse_dsn($dsn) 
            or croak "Can't parse DBI DSN '$dsn'";

    my %driver_hash;
    my @driver_hash_keys; #to keep order
    for my $d ( split /;/, $driver_dsn ) {
        my ( $k, $v) = split /=/, $d, 2;
        $driver_hash{$k} = $v;
        push @driver_hash_keys, $k;
    }
    my $host_key = exists $driver_hash{hostname} ? 'hostname' : 'host';
    my $host = $driver_hash{$host_key};
    return $dsn unless $host;

    my $port = '';
    if ( $host =~ m!:(\d+)$! ) {
        $port = ':'.$1;
        $host =~ s!:(\d+)$!!;
    }

    my $ipaddr = $self->{resolver}->($host)
        or croak "Can't resolv host name: $host, $!";
    $driver_hash{$host_key} = $ipaddr . $port;
    
    $driver_dsn = join ';', map { defined $driver_hash{$_} ? $_.'='.$driver_hash{$_} : $_ } @driver_hash_keys;
    $attr_string = defined $attr_string
        ? '('.$attr_string.')'
        : '';
    sprintf "%s:%s%s:%s", $scheme, $driver, $attr_string, $driver_dsn;
}


1;
__END__

=head1 NAME

DBIx::DSN::Resolver - Resolve hostname within dsn string

=head1 SYNOPSIS

  use DBIx::DSN::Resolver;

  my $dsn = 'dbi:mysql:database=mytbl;host=myserver.example'

  my $resolver = DBIx::DSN::Resolver->new();
  $dsn = $resolver->resolv($dsn);

  is $dsn, 'dbi:mysql:database=mytbl;host=10.0.9.41';

=head1 DESCRIPTION

DBIx::DSN::Resolver parses dsn string and resolves hostname within dsn.
This module allows customize the resolver function.

=head1 CUSTOMIZE RESOLVER

use the resolver argument.
This sample code makes resolver cache with Cache::Memory::Simple.

  use Cache::Memory::Simple;
  use Socket;
    
  my $DNS_CACHE = Cache::Memory::Simple->new();
      
  my $r = DBIx::DSN::Resolver->new(
     resolver => sub {
         my $host = shift;
         my $ipr = $DNS_CACHE->get($host);
         my $ip = $ipr ? $$ipr : undef;
         if ( !$ipr ) {
              $ip = Socket::inet_aton($host);
              $DNS_CACHE->set($host,\$ip,5);
          }
          return unless $ip;
          Socket::inet_ntoa($ip);
      }
  );
  $dsn = $resolver->resolv($dsn);

Default:

  resolver => sub { Socket::inet_ntoa(Socket::inet_aton(@_)) }

Also L<DBIx::DSN::Resolver::Cached> is useful for cache resolver response.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo {at} gmail.comE<gt>

=head1 NOTES

DBIx::DSN::Resolver uses Socket::inet_aton for hostname resolution. 
If you use Solaris and fail hostname resolution, please recompile Socket with "LIBS=-lresolve"

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
