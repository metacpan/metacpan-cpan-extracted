package CHI::Driver::Cache::RedisDB;

use strict;
use warnings;

our $VERSION = '0.03';

use Moo;
extends 'CHI::Driver';

use Cache::RedisDB;

has 'namespace_set_key' => (
    is      => 'ro',
    default => sub { 'CHI-MANAGED-NAMESPACES' },
);

sub BUILD {
    my ($self, $params) = @_;
    Cache::RedisDB->redis->sadd($self->namespace_set_key, $self->namespace);
    return;
}

sub fetch {
    my ($self, $key) = @_;

    return Cache::RedisDB->get($self->namespace, $key);
}

sub store {
    my ($self, $key, $data, $expires_in) = @_;

    my @to_set = ($self->namespace, $key, $data);
    push @to_set, $expires_in if defined $expires_in;

    return Cache::RedisDB->set(@to_set);
}

sub remove {
    my ($self, $key) = @_;

    return Cache::RedisDB->del($self->namespace, $key);
}

sub clear {
    my ($self) = @_;

    my @keys = $self->get_keys;

    return (@keys) ? Cache::RedisDB->del($self->namespace, @keys) : 0;
}

sub get_keys {
    my ($self) = @_;

    return @{Cache::RedisDB->keys($self->namespace, '*')};
}

sub get_namespaces {
    my ($self) = @_;

    return @{Cache::RedisDB->redis->smembers($self->namespace_set_key)};

}

sub flush_all {
    my ($self) = @_;

    foreach my $ns ($self->get_namespaces) {
        if (my @keys = @{Cache::RedisDB->keys($ns, '*')}) {
            Cache::RedisDB->del($ns, @keys);
        }
    }
    return Cache::RedisDB->redis->del($self->namespace_set_key);
}

1;
__END__

=encoding utf-8

=head1 NAME

CHI::Driver::Cache::RedisDB - CHI Driver for Cache::RedisDB

=head1 SYNOPSIS

  CHI->new(driver => 'Cache::RedisDB');

=head1 DESCRIPTION

CHI::Driver::Cache::RedisDB is a simple wrapper around Cache::RedisDB
to provide the common CHI interface.

=head1 AUTHOR

Matt Miller E<lt>matt@inspire.comE<gt>

=head1 COPYRIGHT

Copyright 2017- Matt Miller

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

=cut
