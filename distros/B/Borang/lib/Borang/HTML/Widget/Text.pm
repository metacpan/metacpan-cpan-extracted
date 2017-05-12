package Borang::HTML::Widget::Text;

our $DATE = '2015-09-22'; # DATE
our $VERSION = '0.02'; # VERSION

use 5.010;
use strict;
use warnings;

use HTML::Entities;

use Mo qw(build default);
extends 'Borang::HTML::Widget';

has size => (is => 'rw');
has max_len => (is => 'rw');
has mask => (is => 'rw');

# TODO: Mask can be a format pattern, e.g.: "##.##.##" This will result in 3
# HTML text fields that can only enter two digits each.

sub to_html {
    my $self = shift;

    my $value = $self->value;

    join(
        "",
        "<input name=", $self->name,
        (defined($self->size) ? " size=".$self->size : ""),
        (defined($self->max_len) ? " maxlength=".$self->max_len : ""),
        (" type=password") x !!$self->mask,
        (" value=\"", encode_entities($value), "\"") x !!defined($value),
        ">",
    );
}

1;
# ABSTRACT: Text input widget

__END__

=pod

=encoding UTF-8

=head1 NAME

Borang::HTML::Widget::Text - Text input widget

=head1 VERSION

This document describes version 0.02 of Borang::HTML::Widget::Text (from Perl distribution Borang), released on 2015-09-22.

=for Pod::Coverage .+

=head1 ATTRIBUTES

=head2 size => int

=head2 mask => bool

Whether to mask text being entered (e.g. for password entry)

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
