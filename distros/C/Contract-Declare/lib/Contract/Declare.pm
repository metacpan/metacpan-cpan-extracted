package Contract::Declare;

use v5.14;
use Exporter 'import';
use Role::Tiny ();
use Scalar::Util qw(blessed);
use Carp;


our @EXPORT = qw(contract interface method returns);

our $CURRENT_PKG;
my %REGISTRY;

our $VERSION = '1.0.0';


sub contract {
    local $CURRENT_PKG;
    my $block;
    ($CURRENT_PKG, $block) = @_;
    $block->();
    _build_contract($CURRENT_PKG, $REGISTRY{$CURRENT_PKG});
    delete $REGISTRY{$CURRENT_PKG} unless $ENV{CONTRACT_DECLARE_KEEP_CONTRACT};
}

sub interface (&) { shift }
sub returns       { [ @_ ] }

sub method {
    my ($name, @parts) = @_;
    my (@in, $out);

    for my $p (@parts) {
        if (ref($p) eq 'ARRAY') {
            $out = $p;
            last;
        }
        push @in, $p;
    }

    for my $arg (@in) {
        croak "Contract violation: input argument for method '$name' must be an object with 'compiled_check'"
            unless blessed($arg) && $arg->can('compiled_check');
    }

    if ($out) {
        croak "Contract violation: return type for method '$name' must be an arrayref"
            unless ref($out) eq 'ARRAY';

        for my $ret (@$out) {
            croak "Contract violation: each return type for method '$name' must be an object with 'compiled_check'"
                unless blessed($ret) && $ret->can('compiled_check');
        }
    }

    $REGISTRY{$CURRENT_PKG}{$name} = [ \@in, $out ];
}

sub _build_contract {
    my ($pkg, $contract) = @_;

    no strict 'refs';

    *{"${pkg}::new"} = sub {
        my ($class, $impl) = @_;
        my %cache;

        for my $method (keys %$contract) {
            my $code = $impl->can($method);
            croak "Contract violation: Implementation does not provide method '$method' for interface '$pkg'" unless $code;
            $cache{$method} = $code;
        }

        bless {
            _impl  => $impl,
            _cache => \%cache,
        }, $pkg;
    };

    for my $method (keys %$contract) {
        my ($in_rules, $out_rules) = @{$contract->{$method}};
        my @in_checks  = map { $_->compiled_check } @$in_rules;
        my @out_checks = map { $_->compiled_check } @$out_rules;

        *{"${pkg}::$method"} = sub {
            my ($self, @args) = @_;

            _validate(\@args, \@in_checks, "$pkg\::$method args");

            my @res = $self->{_cache}{$method}->($self->{_impl}, @args);

            _validate(\@res, \@out_checks, "$pkg\::$method return");

            return wantarray ? @res : $res[0];
        };
    }

    Role::Tiny->make_role($pkg);
    $Role::Tiny::INFO{$pkg}{requires} = [ sort keys %$contract ];

    use strict 'refs';
}

sub _validate {
    my ($values, $checkers, $label) = @_;

    return if @$checkers == 0;

    if (@$values != @$checkers) {
        croak "Contract violation in $label: expected " . scalar(@$checkers) . " argument(s), got " . scalar(@$values);
    }

    for (my $i = 0; $i < @$checkers; $i++) {
        next if $checkers->[$i]->($values->[$i]);
        my $val = defined($values->[$i]) ? "'$values->[$i]'" : 'undef';
        croak "Contract violation in $label: argument #$i ($val) failed type check";
    }
}

1;

__END__

=head1 NAME

Contract::Declare - Simple contract system for Perl interfaces

=head1 SYNOPSIS

    package MyInterface;
    
    use Contract::Declare;
    use Standard::Types qw/Int Str/;
    
    contract 'MyInterface' => interface {
        method add_number => (Str), returns(Int);
        method get_name   => returns(Str);
    };

    package MyImpl;
    
    sub new { bless {}, shift }
    
    sub add_number { my ($self, $x) = @_; return $x + 1 }
    
    sub get_name { return "example" }

    # Using the interface
    my $impl = MyImpl->new;
    my $obj = MyInterface->new($impl);

    say $obj->add_number(41); # 42
    say $obj->get_name;        # "example"

=head1 DESCRIPTION

C<Contract::Declare> allows you to define typed contracts (interfaces) in Perl,
similar to lightweight design-by-contract.

This module is intended for lightweight validation, especially useful during development
or for critical internal components.

=head1 FUNCTIONS

=head2 contract $package => interface { ... }

Defines a contract for the given package.

- C<$package> is the full package name as a string (e.g., 'MyInterface').
- C<interface { ... }> is a block where methods are declared.

=head2 interface { ... }

Marks the block containing method declarations.

=head2 method $name => @input_types, returns(@output_types)

Declares a method in the interface.

- C<$name> is the method name (string).
- C<@input_types> is a list of type objects (must implement C<compiled_check>).
- C<returns(@output_types)> defines expected return types.

Example:

    method add => Int(), Int(), returns(Int());

=head2 returns(@types)

Specifies the expected return types for a method.

=head1 AUTHOR

Alexander Ponomarev <shootnix@gmail.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

