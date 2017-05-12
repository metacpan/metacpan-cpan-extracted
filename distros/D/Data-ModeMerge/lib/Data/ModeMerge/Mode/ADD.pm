package Data::ModeMerge::Mode::ADD;

our $DATE = '2016-07-22'; # DATE
our $VERSION = '0.35'; # VERSION

use 5.010;
use strict;
use warnings;
use Mo qw(build default);
extends 'Data::ModeMerge::Mode::NORMAL';

sub name { 'ADD' }

sub precedence_level { 3 }

sub default_prefix { '+' }

sub default_prefix_re { qr/^\+/ }

sub merge_SCALAR_SCALAR {
    my ($self, $key, $l, $r) = @_;
    ($key, ( $l // 0 ) + $r);
}

sub merge_SCALAR_ARRAY {
    my ($self, $key, $l, $r) = @_;
    $self->merger->push_error("Can't add scalar and array");
    return;
}

sub merge_SCALAR_HASH {
    my ($self, $key, $l, $r) = @_;
    $self->merger->push_error("Can't add scalar and hash");
    return;
}

sub merge_ARRAY_SCALAR {
    my ($self, $key, $l, $r) = @_;
    $self->merger->push_error("Can't add array and scalar");
    return;
}

sub merge_ARRAY_ARRAY {
    my ($self, $key, $l, $r) = @_;
    ($key, [ @$l, @$r ]);
}

sub merge_ARRAY_HASH {
    my ($self, $key, $l, $r) = @_;
    $self->merger->push_error("Can't add array and hash");
    return;
}

sub merge_HASH_SCALAR {
    my ($self, $key, $l, $r) = @_;
    $self->merger->push_error("Can't add hash and scalar");
    return;
}

sub merge_HASH_ARRAY {
    my ($self, $key, $l, $r) = @_;
    $self->merger->push_error("Can't add hash and array");
    return;
}

1;
# ABSTRACT: Handler for Data::ModeMerge ADD merge mode

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::ModeMerge::Mode::ADD - Handler for Data::ModeMerge ADD merge mode

=head1 VERSION

This document describes version 0.35 of Data::ModeMerge::Mode::ADD (from Perl distribution Data-ModeMerge), released on 2016-07-22.

=head1 SYNOPSIS

 use Data::ModeMerge;

=head1 DESCRIPTION

This is the class to handle ADD merge mode.

=for Pod::Coverage ^merge_.*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-ModeMerge>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-ModeMerge>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-ModeMerge>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
