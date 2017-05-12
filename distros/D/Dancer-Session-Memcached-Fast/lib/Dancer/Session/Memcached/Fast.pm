use strict;
use warnings;

package Dancer::Session::Memcached::Fast;

# ABSTRACT: Cache::Memcached::Fast based session backend for Dancer

our $VERSION = '0.002';    # VERSION

use mro;
use Carp;
use Cache::Memcached::Fast;
use CBOR::XS qw(encode_cbor decode_cbor);
use Dancer::Config qw(setting);
use parent 'Dancer::Session::Abstract';

my $setting_prefix = 'session_memcached_fast_';

sub _setting {
    setting( $setting_prefix . shift(), @_ );
}

sub _config {
    Dancer::Config::settings();
}

sub new {
    shift->next::method(@_);
}

sub init {
    my $self = shift;

    $self->next::method(@_);

    my $servers = _setting('servers');
    croak "The setting session_memcached_servers must be defined"
      unless defined $servers;

    $servers = [ split /,/, $servers ];

    $self->{cmf} = Cache::Memcached::Fast->new(
        {
            servers    => $servers,
            check_args => '',
        }
    );

    $self;
}

sub _engine {
    Dancer::engine('session');
}

sub _mkns {
    my $id = shift;
    my $ns = _setting('namespace') || _config->{appname};
    return "$ns#$id";
}

sub _boot {
    my ( $class, %config ) = @_;
    my $engine = _engine;
    bless {
        id  => undef,
        cmf => $engine->{cmf},
        %config
    } => $class;
}

sub _set_expire {
    my ( $self, $expire ) = @_;
    $expire //= setting('session_expires');
    if ($expire) {
        if ( $expire !~ m{^\d+$} ) {
            $expire = Dancer::Cookie::_parse_duration($expire);
        }
        $expire -= time;
    }
    else {
        $expire = undef;
    }
    $self->{cmf}->set( '' => time, $expire );
}

sub create {
    my ($class) = @_;
    my $self = $class->_boot( id => $class->build_id );
    $self->{cmf}->namespace( _mkns( $self->id ) );
    $self->_set_expire;
    $self;
}

sub retrieve {
    my ( $class, $id ) = @_;
    my $self = $class->_boot( id => $id );
    $self->{cmf}->namespace( _mkns( $self->id ) );
    my $time = $self->{cmf}->get('');
    return unless defined $time and $time =~ m{^\d+$};
    $self->_set_expire;
    $self;
}

sub get_value {
    my ( $self, $key ) = @_;
    my $value = $self->{cmf}->get($key);
    return unless defined $value;
    decode_cbor $value;
}

sub set_value {
    my ( $self, $key, $value ) = @_;
    $self->{cmf}->set( $key => encode_cbor $value);
}

sub destroy {
    my ($self) = @_;
    $self->{cmf}->flush_all;
    undef;
}

sub flush {
    my $self = shift;
    $self->{cmf}->nowait_push;
    $self;
}

1;

__END__

=pod

=head1 NAME

Dancer::Session::Memcached::Fast - Cache::Memcached::Fast based session backend for Dancer

=head1 VERSION

version 0.002

=head1 DESCRIPTION

This session engine uses L<Cache::Memcached::Fast> as backend and L<CBOR::XS> for serialization.

=head1 CONFIGURATION

In config.yml:

	session: "Memcached::Fast"
	session_memcached_fast_servers: "1.2.3.4"
	session_memcached_fast_namespace: "foobar" # defaults to config->{appname}

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website
https://github.com/zurborg/libdancer-session-memcached-fast-perl/issues

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

David Zurborg <zurborg@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2015 by David Zurborg.

This is free software, licensed under:

  The ISC License

=cut
