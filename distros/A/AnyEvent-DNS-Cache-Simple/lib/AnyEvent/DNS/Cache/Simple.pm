package AnyEvent::DNS::Cache::Simple;

use 5.008005;
use strict;
use warnings;
use base qw/AnyEvent::DNS/;
use Cache::Memory::Simple;
use List::Util qw//;
use Time::HiRes qw//;

our $VERSION = "0.01";

sub request($$) {
   my ($self, $req, $cb) = @_;
   my ($name, $qtype, $class) = @{$req->{qd}[0]};
   my $cache_key = "$class $qtype $name"; #compatibility with Net::DNS::Lite
   if ( my $cached = $self->{adcs_cache}->get($cache_key) ) {
        my ($res,$expires_at) = @$cached;
        if ( $expires_at < Time::HiRes::time ) {
            undef $res;
            $self->{adcs_cache}->remove($cache_key)
        }
        if ( !defined $res ) {
            $cb->();
            return;
        }
        return $cb->($res);
    }

    # request
    $self->SUPER::request($req, sub {
        my ($res) = @_;
        if ( !@_ ) {
            $self->{adcs_cache}->set($cache_key, [undef, $self->{adcs_negative_ttl} + Time::HiRes::time() ], $self->{adcs_negative_ttl});
            return $cb->();
        }
        my $ttl = List::Util::min(
            $self->{adcs_ttl},
            map {
                $_->[3]
            } (@{$res->{an}} ? @{$res->{an}} : @{$res->{ns}}),
        );
        $self->{adcs_cache}->set($cache_key, [$res, $ttl + Time::HiRes::time ], $ttl);
        $cb->($res);
    });        
}

sub register {
    my $class = shift;
    my %args = @_ == 1 ? %{$_[0]} : @_;
    my $ttl = exists $args{ttl} ? delete $args{ttl} : 5;
    my $negative_ttl = exists $args{negative_ttl} ? delete $args{negative_ttl} : 1;
    my $cache = exists $args{cache} ? delete $args{cache} : Cache::Memory::Simple->new;

    my $old = $AnyEvent::DNS::RESOLVER;
    $AnyEvent::DNS::RESOLVER = do {
        no warnings 'uninitialized';
        my $resolver = AnyEvent::DNS::Cache::Simple->new(
            untaint         => 1,
            max_outstanding => $ENV{PERL_ANYEVENT_MAX_OUTSTANDING_DNS}*1 || 1,
            adcs_ttl => $ttl,
            adcs_negative_ttl => $negative_ttl,
            adcs_cache => $cache,
            %args
        );
        if ( !$args{server} ) {
            $ENV{PERL_ANYEVENT_RESOLV_CONF} 
                ? $resolver->_load_resolv_conf_file ($ENV{PERL_ANYEVENT_RESOLV_CONF})
                : $resolver->os_config;
        }
        $resolver;
    };
    AnyEvent::Util::guard {
        $AnyEvent::DNS::RESOLVER = $old;
    };
}

1;
__END__

=encoding utf-8

=head1 NAME

AnyEvent::DNS::Cache::Simple - Simple cache for AnyEvent::DNS

=head1 SYNOPSIS

    use AnyEvent::DNS::Cache::Simple;

    my $guard = AnyEvent::DNS::Cache::Simple->register(
        ttl => 60,
        negative_ttl => 5,
        timeout => [1,1]
    );
    
    for my $i ( 1..3 ) {
        my $cv = AE::cv;
        AnyEvent::DNS::a "example.com", sub {
            say join " | ",@_;
            $cv->send;
        };
        $cv->recv;
    }
    
    undef $guard;

=head1 DESCRIPTION

AnyEvent::DNS::Cache::Simple provides simple cache capability for AnyEvent::DNS

CPAN already has AnyEvent::CacheDNS module. It also provides simple cache. 
AnyEvent::DNS::Cache::Simple support ttl, negative_ttl and can use with any cache module.
And AnyEvent::DNS::Cache::Simple does not use AnyEvent->timer for purging cache.

=head1 METHOD

=head2 register

Register cache to C<$AnyEvent::DNS::RESOLVER>. This method returns guard object.
If the guard object is destroyed, original resolver will be restored

register can accept all C<AnyEvent::DNS->new> arguments and has some additional arguments.

=over 4

=item ttl: Int

maximum positive cache ttl in seconds. (default: 5)

=item negative_ttl: Int

negative cache ttl in seconds. (default: 1)

=item cache: Object

Cache object, requires support get, set and remove methods.
default: Cache::Memory::Simple is used

=back

=head1 SEE ALSO

L<AnyEvent::DNS>, L<AnyEvent::Socket>, L<AnyEvent::CacheDNS>, L<Cache::Memory::Simple>

=head1 LICENSE

Copyright (C) Masahiro Nagano.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Masahiro Nagano E<lt>kazeburo@gmail.comE<gt>

=cut

