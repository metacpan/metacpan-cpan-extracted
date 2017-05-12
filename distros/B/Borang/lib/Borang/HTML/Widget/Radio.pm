package Borang::HTML::Widget::Radio;

our $DATE = '2015-09-22'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010;
use strict;
use warnings;

use HTML::Entities;

use Mo qw(build default);
extends 'Borang::HTML::Widget';

has radios => (is => 'rw');

sub to_html {
    my $self = shift;

    my $value = $self->value;

    my @res;
    for my $item (@{$self->radios}) {
        my $icaption = ref($item) ? $item->{caption} : $item;
        my $ivalue   = ref($item) ? $item->{value} : $item;

        push(
            @res,
            "<input name=", $self->name, " type=radio",
            ((" value=\"", encode_entities($ivalue), "\"") x !!ref($item)),
            ((" checked") x !!(defined($value) && $value eq $ivalue)),
            ">",
            ((" ", encode_entities($icaption)) x !!defined($icaption)),
        );
    }
    join "", @res;
}

1;
# ABSTRACT: Radio group input widget

__END__

=pod

=encoding UTF-8

=head1 NAME

Borang::HTML::Widget::Radio - Radio group input widget

=head1 VERSION

This document describes version 0.02 of Borang::HTML::Widget::Radio (from Perl distribution Borang), released on 2015-09-22.

=for Pod::Coverage .+

=head1 ATTRIBUTES

=head2 radios => array*

A list of radio items. Example:

 ["on", "off"]

Another example:

 [{caption=>"on", value=>1}, {caption=>"off", value=>0}]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Borang>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Borang>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Borang>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
