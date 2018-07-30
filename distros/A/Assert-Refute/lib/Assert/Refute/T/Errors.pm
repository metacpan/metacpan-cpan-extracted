package Assert::Refute::T::Errors;

use 5.006;
use strict;
use warnings;
our $VERSION = '0.1301';

=head1 NAME

Assert::Refute::T::Errors - exception and warning check for Assert::Refute suite

=head1 SYNOPSIS

    use Assert::Refute qw(:all);
    use Assert::Refute::T::Errors;

    my $c = contract {
        my $foo = shift;
        dies_like {
            $foo->bar;
        } "Bar requires an argument";
        dies_like {
            $foo->bar(1);
        } '', "Bar works fine with 1";
    };

    $c->apply( $my_foo ); # check whether foo lives/dies as expected

Ditto with L<Test::More> (although there are more fine-grained L<Test::Warn>
and L<Test::Exception>):

    use Test::More;
    use Assert::Refute::T::Errors; # always *after* Test::More

    use My::Module;

    dies_like {
        My::Module->foo;
    } qw/foo requires/, "Epmty argument prohibited";
    dies_like {
        My::Module->bar;
    } '', "Works without arguments";

=head1 EXPORTED FUNCTIONS

All functions below are exported by default.

=cut

use Carp;
use parent qw(Exporter);
our @EXPORT = qw(foobar);

use Assert::Refute::Build;
use Assert::Refute::Contract;

=head2 dies_like

    dies_like {
        # shoddy code here
    } 'pattern', 'explanation';

Check that supplied code throws the expected exception.

If pattern is empty, expect the code to live through.

Otherwise convert it to regular expression if needed
and match C<$@> against it.

=cut

build_refute dies_like => sub {
    my ($block, $rex) = @_;

    my $lived = eval {
        $block->();
        1;
    };

    if ($rex) {
        $rex = qr/$rex/;
        return "Block didn't die" if $lived;
        return "Exception wasn't true" unless $@;
        return $@ =~ $rex ? '' : "Exception was: $@\nExpected: $rex";
    } else {
        return if $lived;
        return $@
            ? "Exception was: $@\nExpected to live"
            : Carp::shortmess "Block died"."Expected to live";
    }
}, block => 1, export => 1, args => 1;

=head2 warns_like { ... }

    warns_like {
        warn "Foo";
        warn "Bar";
    } [qr/Foo/, "Bar"], "Human comment";

    warns_like {
        # Shoddy code here
    } '', "No warnings";

Check that exactly the specified warnings were emitted by block.
A single string or regex value is accepted and converted to 1-element array.

An empty array or a false value mean no warnings at all.

Note that this block does NOT catch exceptions.
This MAY change in the future.

=cut

# TODO better diagnostic
my $multi_like = Assert::Refute::Contract->new( code => sub {
    my ($self, $got, $exp) = @_;

    for (my $i = 0; $i < @$got or $i < @$exp; $i++) {
        defined $exp->[$i]
            ? $self->like( $got->[$i], $exp->[$i] )
            : $self->is ( $got->[$i], undef );
    };
}, need_object => 1 );

build_refute warns_like => sub {
    my ($block, $exp) = @_;

    $exp = $exp ? [ $exp ] : []
        unless ref $exp eq 'ARRAY';
    $_ = qr/$_/ for @$exp;

    my @warn;
    {
        local $SIG{__WARN__} = sub { push @warn, shift };
        $block->();
    };

    my $c = $multi_like->apply( \@warn, $exp );
    return $c->is_passing ? '' : $c->get_tap;
}, block => 1, args => 1, export => 1;

=head1 LICENSE AND COPYRIGHT

This module is part of L<Assert::Refute> suite.

Copyright 2017-2018 Konstantin S. Uvarin. C<< <khedin at cpan.org> >>

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

=cut

1;
