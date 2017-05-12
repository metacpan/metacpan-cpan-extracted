# ABSTRACT: Object Orientation for Bubblegum via Moo
package Bubblegum::Class;

use 5.10.0;
use namespace::autoclean;

use Moo 'with';

with 'Bubblegum::Role::Configuration';

our $VERSION = '0.45'; # VERSION

sub import {
    my $target = caller;
    my $class  = shift;
    my @export = @_;

    $class->prerequisites($target);
    Moo->import::into($target, @export);
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Class - Object Orientation for Bubblegum via Moo

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    package BankAccount;

    use Bubblegum::Class;

    has balance => (
        is      => 'rw',
        default => 0
    );

    sub withdrawal {
        my $self = shift;
        my $amount = $self->balance - shift // 0;
        return $self->balance($amount);
    }

And elsewhere:

    my $account = BankAccount->new(balance => 100000);
    say $account->withdrawal(1500);

=head1 DESCRIPTION

Bubblegum::Class provides object orientation for your classes by way of L<Moo>
and activates all of the options enabled by the L<Bubblegum> module. Using this
module allows you to define classes as if you were using Moo directly. B<Note:
This is an early release available for testing and feedback and as such is
subject to change.>

    use Bubblegum::Class;

is equivalent to

    use 5.10.0;
    use strict;
    use autobox;
    use autodie ':all';
    use feature ':5.10';
    use warnings FATAL => 'all';
    use English -no_match_vars;
    use utf8::all;
    use mro 'c3';
    use Moo;

=head1 AUTHOR

Al Newkirk <anewkirk@ana.io>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Al Newkirk.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
