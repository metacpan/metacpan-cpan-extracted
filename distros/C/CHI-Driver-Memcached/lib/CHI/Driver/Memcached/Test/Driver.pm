package CHI::Driver::Memcached::Test::Driver;
$CHI::Driver::Memcached::Test::Driver::VERSION = '0.16';
use strict;
use warnings;
use Moose;
use CHI::t::Driver;
use CHI::Driver::Memcached::t::CHIDriverTests;
use base qw(CHI::Driver::Memcached);

__PACKAGE__->meta->make_immutable;

# Reverse declare_unsupported_methods
#
foreach my $method (qw(dump_as_hash is_empty purge)) {
    no strict 'refs';
    *{ __PACKAGE__ . "::$method" } = sub {
        my $self        = shift;
        my $full_method = "CHI::Driver::$method";
        return $self->$full_method(@_);
    };
}

sub all_test_keys {
    my ($standard_keys) =
      CHI::Driver::Memcached::t::CHIDriverTests->set_standard_keys_and_values();
    my $all_test_keys = [
        values(%$standard_keys),
        CHI::Driver::Memcached::t::CHIDriverTests->extra_test_keys()
    ];
    return $all_test_keys;
}

# Memcached doesn't support get_keys. For testing purposes, define get_keys
# and clear by checking for all keys used during testing. Note, some keys
# are changed in CHIDriverTests::set_standard_keys_and_values.
#
sub get_keys {
    my $self = shift;

    my $all_test_keys = $self->all_test_keys;
    my $values        = $self->get_multi_hashref($all_test_keys);
    my @defined_keys  = grep { defined $values->{$_} } keys(%$values);
    return @defined_keys;
}

sub clear {
    my $self = shift;

    my $all_test_keys = $self->all_test_keys;
    foreach my $key (@$all_test_keys) {
        $self->remove($key);
    }
}

1;
