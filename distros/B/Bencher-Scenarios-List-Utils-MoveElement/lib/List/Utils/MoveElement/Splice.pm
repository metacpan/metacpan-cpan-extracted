package List::Utils::MoveElement::Splice;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-23'; # DATE
our $DIST = 'Bencher-Scenarios-List-Utils-MoveElement'; # DIST
our $VERSION = '0.003'; # VERSION

sub to_beginning_copy {
    my ($i, @ary) = @_;
    # XXX some sanity checks
    return @ary if $i == 0; # no-op
    my $el = splice @ary, $i, 1;
    unshift @ary, $el;
    @ary;
}

sub to_beginning_nocopy {
    my $i = shift;
    # XXX some sanity checks
    return @_ if $i == 0; # no-op
    my $el = splice @_, $i, 1;
    unshift @_, $el;
    @_;
}

1;
# ABSTRACT: A variant of List::Utils::MoveElement that uses splice()

__END__

=pod

=encoding UTF-8

=head1 NAME

List::Utils::MoveElement::Splice - A variant of List::Utils::MoveElement that uses splice()

=head1 VERSION

This document describes version 0.003 of List::Utils::MoveElement::Splice (from Perl distribution Bencher-Scenarios-List-Utils-MoveElement), released on 2021-07-23.

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Bencher-Scenarios-List-Utils-MoveElement>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Bencher-Scenarios-List-Utils-MoveElement>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Bencher-Scenarios-List-Utils-MoveElement>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
