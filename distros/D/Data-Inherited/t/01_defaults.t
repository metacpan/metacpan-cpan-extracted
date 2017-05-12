#!/usr/bin/env perl
use warnings;
use strict;
use Test::More tests => 15;

package Person;
use parent 'Data::Inherited';

sub DEFAULTS {
    first_name  => 'John',
      last_name => 'Smith',
      ;
}
our $override_cache = 0;

sub new {
    my $class = shift;
    my $self  = bless {}, $class;
    my %args  = @_;
    our $override_cache;
    $override_cache = 1 - $override_cache;
    %args = ($self->every_hash('DEFAULTS', $override_cache), %args);
    $self->$_($args{$_}) for keys %args;
    $self;
}

sub first_name {
    return $_[0]->{first_name} if @_ == 1;
    $_[0]->{first_name} = $_[1];
}

sub last_name {
    return $_[0]->{last_name} if @_ == 1;
    $_[0]->{last_name} = $_[1];
}

package Employee;
our @ISA = 'Person';

sub DEFAULTS {
    salary => 10_000,
      ;
}

sub salary {
    return $_[0]->{salary} if @_ == 1;
    $_[0]->{salary} = $_[1];
}

package LocatedEmployee;
our @ISA = 'Employee';

# Note: no default for address, but different salary
sub DEFAULTS {
    salary       => 20_000,
      first_name => 'Johan',
      ;
}

sub address {
    return $_[0]->{address} if @_ == 1;
    $_[0]->{address} = $_[1];
}

package main;
use Test::More;
my $p;

# twice, to test the every_hash caching mechanism, and twice again to get
# both use the cache and use override_cache (see new() above)
for (1 .. 4) {
    $p = Person->new;
    ok_prop(
        $p,
        first_name => 'John',
        last_name  => 'Smith',
    );
}

# now use hash context
my %defaults = $p->every_hash('DEFAULTS');
is_deeply(
    \%defaults,
    {   first_name => 'John',
        last_name  => 'Smith',
    },
    'defaults in hash context'
);
$p = Employee->new;
ok_prop(
    $p,
    first_name => 'John',
    last_name  => 'Smith',
    salary     => 10_000,
);
$p = LocatedEmployee->new;
ok_prop(
    $p,
    first_name => 'Johan',
    last_name  => 'Smith',
    salary     => 20_000,
);

sub ok_prop {
    my ($obj, %property) = @_;
    while (my ($property, $value) = each %property) {
        is( $obj->$property, $value,
            sprintf '%s %s is %s' => ref($obj),
            $property, $value
        );
    }
}
