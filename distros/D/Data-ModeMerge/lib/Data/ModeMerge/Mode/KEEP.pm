package Data::ModeMerge::Mode::KEEP;

our $DATE = '2016-07-22'; # DATE
our $VERSION = '0.35'; # VERSION

use 5.010;
use strict;
use warnings;
use Mo qw(build default);
extends 'Data::ModeMerge::Mode::Base';

sub name { 'KEEP' }

sub precedence_level { 6 }

sub default_prefix { '^' }

sub default_prefix_re { qr/^\^/ }

sub merge_SCALAR_SCALAR {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_SCALAR_ARRAY {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_SCALAR_HASH {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_ARRAY_SCALAR {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_ARRAY_ARRAY {
    my ($self, $key, $l, $r) = @_;
    $self->SUPER::merge_ARRAY_ARRAY($key, $l, $r, 'KEEP');
};

sub merge_ARRAY_HASH {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_HASH_SCALAR {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_HASH_ARRAY {
    my ($self, $key, $l, $r) = @_;
    ($key, $l);
}

sub merge_HASH_HASH {
    my ($self, $key, $l, $r) = @_;
    $self->SUPER::merge_HASH_HASH($key, $l, $r, 'KEEP');
};

1;
# ABSTRACT: Handler for Data::ModeMerge KEEP merge mode

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::ModeMerge::Mode::KEEP - Handler for Data::ModeMerge KEEP merge mode

=head1 VERSION

This document describes version 0.35 of Data::ModeMerge::Mode::KEEP (from Perl distribution Data-ModeMerge), released on 2016-07-22.

=head1 SYNOPSIS

 use Data::ModeMerge;

=head1 DESCRIPTION

This is the class to handle KEEP merge mode.

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
