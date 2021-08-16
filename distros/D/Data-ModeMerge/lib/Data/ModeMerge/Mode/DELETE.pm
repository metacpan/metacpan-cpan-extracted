package Data::ModeMerge::Mode::DELETE;

our $DATE = '2021-08-15'; # DATE
our $VERSION = '0.360'; # VERSION

use 5.010;
use strict;
use warnings;
use Mo qw(build default);
extends 'Data::ModeMerge::Mode::Base';

sub name { 'DELETE' }

sub precedence_level { 1 }

sub default_prefix { '!' }

sub default_prefix_re { qr/^!/ }

# merge_left_only and merge_right_only are a bit different: they are
# called with $l only or $r only instead of both, and should return an
# extra argument $mode, i.e. ($key, $result, $backup, $is_circular,
# $mode)
sub merge_left_only {
    my ($self, $key, $l) = @_;
    return;
}

sub merge_right_only {
    my ($self, $key, $r) = @_;
    return;
}

sub merge_SCALAR_SCALAR {
    return;
}

sub merge_SCALAR_ARRAY {
    return;
}

sub merge_SCALAR_HASH {
    return;
}

sub merge_ARRAY_SCALAR {
    return;
}

sub merge_ARRAY_ARRAY {
    my ($self, $key, $l, $r) = @_;
    $self->merger->config->allow_destroy_array or
        $self->merger->push_error("Now allowed to destroy array via DELETE mode");
    return;
}

sub merge_ARRAY_HASH {
    return;
}

sub merge_HASH_SCALAR {
    return;
}

sub merge_HASH_ARRAY {
    return;
}

sub merge_HASH_HASH {
    my ($self, $key, $l, $r) = @_;
    $self->merger->config->allow_destroy_hash or
        $self->merger->push_error("Now allowed to destroy hash via DELETE mode");
    return;
}

1;
# ABSTRACT: Handler for Data::ModeMerge DELETE merge mode

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::ModeMerge::Mode::DELETE - Handler for Data::ModeMerge DELETE merge mode

=head1 VERSION

This document describes version 0.360 of Data::ModeMerge::Mode::DELETE (from Perl distribution Data-ModeMerge), released on 2021-08-15.

=head1 SYNOPSIS

 use Data::ModeMerge;

=head1 DESCRIPTION

This is the class to handle DELETE merge mode.

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

This software is copyright (c) 2021, 2016, 2015, 2013, 2012, 2011, 2010 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
