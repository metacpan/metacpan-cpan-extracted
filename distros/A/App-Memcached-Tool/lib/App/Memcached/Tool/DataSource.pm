package App::Memcached::Tool::DataSource;

use strict;
use warnings;
use 5.008_001;

use Carp;
use IO::Socket;

use App::Memcached::Tool::Util qw(is_unixsocket debug);

sub new {
    my $class = shift;
    my %args  = @_;
    bless \%args, $class;
}

sub connect {
    my $class = shift;
    my $addr  = shift;
    my %opts  = @_;

    my $socket = sub {
        return IO::Socket::UNIX->new(Peer => $addr) if is_unixsocket($addr);
        return IO::Socket::INET->new(
            PeerAddr => $addr,
            Proto    => 'tcp',
            Timeout  => $opts{timeout} || 5,
        );
    }->();
    confess "Can't connect to $addr" unless $socket;

    return $class->new(socket => $socket);
}

sub disconnect {
    my $self = shift;
    $self->{socket}->close or confess "Failed to close connection!";
    undef $self->{socket};
}

sub get {
    my $self = shift;
    my @keys = @_;

    my $key_str = join(q{ }, @keys);
    $self->{socket}->write("get $key_str\r\n");

    my @results;

    while (1) {
        my $response = $self->{socket}->getline;
        next if ($response =~ m/^[\r\n]+$/);
        if ($response =~ m/^VALUE (\S+) (\d+) (\d+)(?: (\d+))?/) {
            my %data = (
                key    => $1,
                flags  => $2,
                length => $3,
                cas    => $4,
            );
            $self->{socket}->read($response, $data{length});
            $data{value} = $response;
            push @results, \%data;
        } elsif ($response =~ m/^END/) {
            last;
        } else {
            warn "Unknown response '$response'";
        }
    }

    return \@results;
}

sub query {
    my $self  = shift;
    my $query = shift;

    $self->{socket}->write("$query\r\n");

    my @response;
    while ($_ = $self->{socket}->getline) {
        last if m/^END/;
        confess $_ if m/^(CLIENT|SERVER_)?ERROR/;
        $_ =~ s/[\r\n]+$//;
        push @response, $_;
    }

    return \@response;
}

sub DESTROY {
    my $self = shift;
    if ($self->{socket}) { $self->{socket}->close; }
}

1;
__END__

=encoding utf-8

=head1 NAME

App::Memcached::Tool::DataSource - Interface for Memcached

=head1 SYNOPSIS

    use App::Memcached::Tool::DataSource;
    my $ds = App::Memcached::Tool::DataSource->connect(
            $params{addr}, timeout => $params{timeout}
        );
    my $stats = $ds->query('stats');

=head1 DESCRIPTION

App::Memcached::Tool::DataSource is interface module for Memcached.

=head1 LICENSE

Copyright (C) YASUTAKE Kiyoshi.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

YASUTAKE Kiyoshi E<lt>yasutake.kiyoshi@gmail.comE<gt>

=cut

