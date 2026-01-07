package Async::Redis::URI;

use strict;
use warnings;
use 5.018;

our $VERSION = '0.001';

# URL decode
sub _decode {
    my ($str) = @_;
    return unless defined $str;
    $str =~ s/%([0-9A-Fa-f]{2})/chr(hex($1))/eg;
    return $str;
}

sub new {
    my ($class, %args) = @_;
    return bless \%args, $class;
}

sub parse {
    my ($class, $uri_string) = @_;

    return undef unless defined $uri_string && $uri_string ne '';

    my %parsed = (
        host     => 'localhost',
        port     => 6379,
        database => 0,
        tls      => 0,
        is_unix  => 0,
    );

    # Handle unix socket: redis+unix://[:password@]/path[?query]
    if ($uri_string =~ m{^(redis\+unix)://(?:(?::([^@]*))?@)?(/[^?]+)(?:\?(.*))?$}) {
        $parsed{scheme} = $1;
        $parsed{password} = _decode($2) if defined $2 && $2 ne '';
        $parsed{path} = $3;
        $parsed{is_unix} = 1;

        # Remove host/port for unix sockets
        delete $parsed{host};
        delete $parsed{port};

        # Parse query string
        if (defined $4) {
            my %query;
            for my $pair (split /&/, $4) {
                my ($k, $v) = split /=/, $pair, 2;
                $query{$k} = _decode($v);
            }
            $parsed{database} = $query{db} if exists $query{db};
        }

        return $class->new(%parsed);
    }

    # Standard URI: redis[s]://[user:pass@]host[:port][/database]
    unless ($uri_string =~ m{^(rediss?)://(.+)$}) {
        die "Invalid Redis URI: must start with redis://, rediss://, or redis+unix://";
    }

    my $scheme = $1;
    my $rest = $2;

    $parsed{scheme} = $scheme;
    $parsed{tls} = 1 if $scheme eq 'rediss';

    # Split userinfo from host
    my ($userinfo, $hostinfo);
    if ($rest =~ /^([^@]*)@(.+)$/) {
        $userinfo = $1;
        $hostinfo = $2;
    } else {
        $hostinfo = $rest;
    }

    # Parse userinfo: empty, :password, user:password, or just user
    if (defined $userinfo && $userinfo ne '') {
        if ($userinfo =~ /^:(.*)$/) {
            # :password (no username)
            $parsed{password} = _decode($1);
        } elsif ($userinfo =~ /^([^:]*):(.*)$/) {
            # user:password
            $parsed{username} = _decode($1);
            $parsed{password} = _decode($2);
        } else {
            # just username
            $parsed{username} = _decode($userinfo);
        }
    }

    # Parse hostinfo: host[:port][/database]
    if ($hostinfo =~ m{^([^:/]+)(?::(\d+))?(?:/(\d+))?$}) {
        $parsed{host} = $1;
        $parsed{port} = int($2) if defined $2;
        $parsed{database} = int($3) if defined $3;
    } elsif ($hostinfo =~ m{^([^:/]+)(?::(\d+))?/?$}) {
        # host:port with trailing slash but no database
        $parsed{host} = $1;
        $parsed{port} = int($2) if defined $2;
    } else {
        die "Invalid Redis URI format: cannot parse host from '$hostinfo'";
    }

    # Validate we got a host
    die "Invalid Redis URI: empty host" unless $parsed{host};

    return $class->new(%parsed);
}

# Accessors
sub scheme   { shift->{scheme} }
sub host     { shift->{host} }
sub port     { shift->{port} }
sub path     { shift->{path} }
sub database { shift->{database} }
sub username { shift->{username} }
sub password { shift->{password} }
sub tls      { shift->{tls} }
sub is_unix  { shift->{is_unix} }

# Convert to hash suitable for Async::Redis->new()
sub to_hash {
    my ($self) = @_;
    my %hash;

    if ($self->is_unix) {
        $hash{path} = $self->path;
    } else {
        $hash{host} = $self->host;
        $hash{port} = $self->port;
    }

    $hash{database} = $self->database if $self->database;
    $hash{username} = $self->username if defined $self->username;
    $hash{password} = $self->password if defined $self->password;
    $hash{tls} = 1 if $self->tls;

    return %hash;
}

1;

__END__

=head1 NAME

Async::Redis::URI - Redis connection URI parser

=head1 SYNOPSIS

    use Async::Redis::URI;

    my $uri = Async::Redis::URI->parse('redis://localhost:6379/0');

    say $uri->host;      # localhost
    say $uri->port;      # 6379
    say $uri->database;  # 0

    # Use with constructor
    my $redis = Async::Redis->new($uri->to_hash);

=head1 DESCRIPTION

Parses Redis connection URIs in standard formats:

    redis://host:port/database
    redis://:password@host
    redis://user:password@host
    rediss://host              (TLS)
    redis+unix:///path/to/socket?db=N

=head1 METHODS

=head2 parse($uri_string)

Class method. Parses URI string and returns URI object.
Returns undef for empty/undef input. Dies on invalid URI.

=head2 to_hash

Returns hash suitable for passing to Async::Redis->new().

=head2 Accessors

scheme, host, port, path, database, username, password, tls, is_unix

=cut
