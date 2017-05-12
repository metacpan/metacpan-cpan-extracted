package Cache::Memcached::AnyEvent::Protocol;
use strict;

sub new {
    my $class = shift;
    my $self  = bless {@_}, $class;
    return $self;
}

sub prepare_handle {}

1;

__END__

=head1 NAME

Cache::Memcached::AnyEvent::Protocol - Base Class For Memcached Protocol

=head1 SYNOPSIS

    package NewProtocol;
    use strict;
    use base 'Cache::Memcached::AnyEvent::Protocol';

=head1 METHODS

=head2 new

=head2 prepare_handle

=cut