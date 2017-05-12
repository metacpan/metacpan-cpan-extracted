package Cache::Memcached::Indexable::Logic;

use strict;
use warnings;
use Carp;

our $VERSION = 0.01;

sub new {
    my $self = bless {}, shift;
    if (defined $_[0]) {
        my $args = shift;
        for my $method (keys %$args) {
            $self->$method($args->{$method});
        }
    }
    return $self;
}

sub _key_prefix {
    my $self = shift;
    return $self->{__key_prefix} if exists $self->{__key_prefix};
    my $base_package = __PACKAGE__;
    (my $prefix = ref($self)) =~ s/^${base_package}:://;
    $self->{__key_prefix} = $prefix;
    return $self->{__key_prefix};
}

sub trunk_keys {
    my $self = shift;
    my $prefix = $self->_key_prefix;
    return map { "${prefix}::${_}" } $self->all_keys;
}

sub branch_key {
    my($self, $key) = @_;
    return sprintf('%s::%s', $self->_key_prefix, $self->find_branch_key($key));
}

sub _deleted_key {
    my $self = shift;
    return sprintf('%s::%s', $self->_key_prefix, '_Deleted');
}

sub all_keys        { shift->_abstract }
sub find_branch_key { shift->_abstruct }

sub _abstract {
    my $self = shift;
    my $pkg = ref($self);
    my @caller = caller(1);
    my $base_package = __PACKAGE__;
    (my $method_name = $caller[3]) =~ s/^${base_package}:://;
    carp qq|This is an abstract method. "$pkg" must have $method_name method.|;
}

1;

__END__

=head1 NAME

Cache::Memcached::Indexable::Logic - The logic provider for Cache::Memcached::Indexable

=head1 SYNOPSIS

B<DO NOT USE THIS MODULE DIRECTLY>.

This class is a base class of some logics. You can write your original logic
with inheriting this class.

=head1 AUTHOR

Koichi Taniguchi E<lt>taniguchi@livedoor.jpE<gt>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Cache::Memcached::Indexable>,
L<Cache::Memcached::Indexable::Logic::Default>,
L<Cache::Memcached::Indexable::Logic::DigestSHA1>

=cut
