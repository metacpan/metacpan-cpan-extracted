package Boundary;
use strict;
use warnings;

use namespace::allclean ();
use Class::Load qw(try_load_class);

our $VERSION = "0.01";

our %INFO;

sub import {
    my $class = shift;
    my $target = scalar caller;

    my $requires = $class->gen_requires($target);
    {
        no strict 'refs';
        *{"${target}::requires"} = $requires;
    }

    namespace::allclean->import(
        -cleanee => $target,
    );
 
    return;
}


our $CROAK_MESSAGE_SUFFIX;
sub croak {
  require Carp;
  push @_ => $CROAK_MESSAGE_SUFFIX if $CROAK_MESSAGE_SUFFIX;
  goto &Carp::croak;
}

sub gen_requires {
    my ($class, $target) = @_;
    sub {
        my @methods = @_;
        push @{$INFO{$target}{requires}||=[]} => @methods;
        return;
    }
}

sub assert_requires {
    my ($class, $impl, $interface) = @_;
    croak "Not found interface info. $interface" if !$INFO{$interface};

    my @requires = @{$INFO{$interface}{requires}};
    return if !@requires;

    if (my @requires_fail = grep { !$impl->can($_) } @requires) {
        croak "Can't apply ${interface} to ${impl} - missing ". join(', ', @requires_fail);
    }
    return;
}

sub apply_interfaces_to_package {
    my ($class, $impl, @interfaces) = @_;
    croak "No interfaces supplied!" unless @interfaces;

    for my $interface (@interfaces) {
        my ($ok, $e) = try_load_class($interface);
        croak("cannot load interface package: $e") if !$ok;

        $class->assert_requires($impl, $interface);
    }
    $INFO{$impl}{interface_map}{$_} = 1 for @interfaces;
    return;
}

sub check_implementations {
    my ($class, $impl, @interfaces) = @_;
    return if !$INFO{$impl};
    my %interface_map = %{$INFO{$impl}{interface_map}};
    for (@interfaces) {
        return if !$interface_map{$_}
    }
    return !!1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Boundary - declare interface package

=head1 SYNOPSIS

Declare interface package C<IFoo>:

    package IFoo {
        use Boundary;

        requires qw(hello world);
    }

Implements the interface package C<IFoo>:

    package Foo {
        use Boundary::Impl qw(IFoo);

        sub hello { ... }
        sub world { ... }
    }

Use the type C<ImplOf>:

    use Boundary::Types -types;
    use Foo;

    my $type = ImplOf['IFoo'];
    my $foo = Foo->new; # implements of IFoo
    $type->check($foo); # pass!

=head1 DESCRIPTION

This module provides a interface.
C<Boundary> declares abstract functions without implementation and defines an interface package.
C<Bounary::Impl> checks if the abstract functions are implemented at B<compile time>.

The difference with Role is that the implementation cannot be reused.
L<namespace::allclean> prevents the reuse of the implementation.

=head1 LICENSE

Copyright (C) kfly8.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

kfly8 E<lt>kfly8@cpan.orgE<gt>

=cut

