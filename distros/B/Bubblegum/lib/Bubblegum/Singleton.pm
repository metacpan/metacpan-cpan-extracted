# ABSTRACT: Singleton Pattern for Bubblegum via Moo
package Bubblegum::Singleton;

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

    my $inst;
    my $orig = $class->can('new');
    no strict 'refs';
    *{"${target}::new"} = sub {
        $inst //= $orig->(@_)
    };

    if (!$class->can('renew')) {
        *{"${target}::renew"} = sub {
            $inst = $orig->(@_)
        };
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Bubblegum::Singleton - Singleton Pattern for Bubblegum via Moo

=head1 VERSION

version 0.45

=head1 SYNOPSIS

    package Configuration;

    use Bubblegum::Singleton;

    has hostname => (
        is      => 'rw',
        default => 'localhost'
    );

And elsewhere:

    my $config = Configuration->new;
    $config->hostname('example.com');

    $config = Configuration->new;
    say $config->hostname; # example.com

    $config = $config->renew;
    say $config->hostname; # localhost

=head1 DESCRIPTION

Bubblegum::Singleton provides a simple singleton object for your convenience by
way of L<Moo> and activates all of the options enabled by the L<Bubblegum>
module. Using this module allows you to define classes as if you were using Moo
directly. B<Note: This is an early release available for testing and feedback
and as such is subject to change.>

    use Bubblegum::Singleton;

is equivalent to

    use 5.10.0;
    use strict;
    use warnings;
    use autobox;
    use autodie ':all';
    use feature ':5.10';
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
