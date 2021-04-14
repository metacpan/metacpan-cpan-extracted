package ArrayDataRole::Source::Array;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-13'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use Role::Tiny;
use Role::Tiny::With;
with 'ArrayDataRole::Spec::Basic';

sub new {
    my ($class, %args) = @_;

    my $ary = delete $args{array} or die "Please specify 'array' argument";

    die "Unknown argument(s): ". join(", ", sort keys %args)
        if keys %args;

    bless {
        array => $ary,
        index => 0,
    }, $class;
}

sub elem {
    my $self = shift;
    die "Out of range" unless $self->{index} < @{ $self->{array} };
    $self->{array}->[ $self->{index}++ ];
}

sub get_elem {
    my $self = shift;
    return undef unless $self->{index} < @{ $self->{array} };
    $self->{array}->[ $self->{index}++ ];
}

sub reset_iterator {
    my $self = shift;
    $self->{index} = 0;
}

sub get_iterator_index {
    my $self = shift;
    $self->{index};
}

1;
# ABSTRACT: Get array data from a Perl array

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Source::Array - Get array data from a Perl array

=head1 VERSION

This document describes version 0.001 of ArrayDataRole::Source::Array (from Perl distribution ArrayDataRoles-Standard), released on 2021-04-13.

=head1 SYNOPSIS

 my $ary = ArrayData::Array->new(array => [1,2,3]);

=head1 DESCRIPTION

This role retrieves elements from a Perl array. It is basically an iterator.

=for Pod::Coverage ^(.+)$

=head1 ROLES MIXED IN

L<ArrayDataRole::Spec::Basic>

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayDataRoles-Standard>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayDataRoles-Standard>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-ArrayDataRoles-Standard/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayData>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
