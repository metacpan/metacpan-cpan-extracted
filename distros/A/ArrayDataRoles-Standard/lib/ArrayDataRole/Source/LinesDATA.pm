package ArrayDataRole::Source::LinesDATA;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-13'; # DATE
our $DIST = 'ArrayDataRoles-Standard'; # DIST
our $VERSION = '0.001'; # VERSION

use Role::Tiny;
use Role::Tiny::With;
with 'ArrayDataRole::Spec::Basic';

sub new {
    no strict 'refs';

    my $class = shift;

    my $fh = \*{"$class\::DATA"};
    my $fhpos_data_begin = tell $fh;

    bless {
        fh => $fh,
        fhpos_data_begin => $fhpos_data_begin,
        index => 0, # iterator
    }, $class;
}

sub elem {
    my $self = shift;
    die "Out of range" if eof($self->{fh});
    chomp(my $elem = readline($self->{fh}));
    $self->{index}++;
    $elem;
}

sub get_elem {
    my $self = shift;
    return undef if eof($self->{fh});
    chomp(my $elem = readline($self->{fh}));
    $self->{index}++;
    $elem;
}

sub get_iterator_index {
    my $self = shift;
    $self->{index};
}

sub reset_iterator {
    my $self = shift;
    seek $self->{fh}, $self->{fhpos_data_begin}, 0;
    $self->{index} = 0;
}

1;
# ABSTRACT: Role to access array data from DATA section, one line per element

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayDataRole::Source::LinesDATA - Role to access array data from DATA section, one line per element

=head1 VERSION

This document describes version 0.001 of ArrayDataRole::Source::LinesDATA (from Perl distribution ArrayDataRoles-Standard), released on 2021-04-13.

=head1 DESCRIPTION

This role expects array data in lines in the DATA section.

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

Other C<ArrayDataRole::Source::*>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
