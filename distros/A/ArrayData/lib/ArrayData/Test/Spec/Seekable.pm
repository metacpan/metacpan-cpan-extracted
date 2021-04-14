package ArrayData::Test::Spec::Seekable;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-04-11'; # DATE
our $DIST = 'ArrayData'; # DIST
our $VERSION = '0.1.0'; # VERSION

use parent 'ArrayData::Test::Spec::Basic';
use Role::Tiny::With;

with 'ArrayDataRole::Spec::Seekable';

sub set_iterator_index {
    my ($ary, $index) = @_;

    $index = int($index);
    if ($index >= 0) {
        die "Index out of range" unless $index < @{ $ary->_elems };
        $ary->{index} = $index;
    } else {
        die "Index out of range" unless -$index <= @{ $ary->_elems };
        $ary->{index} = @{ $ary->_elems } + $index;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

ArrayData::Test::Spec::Seekable

=head1 VERSION

This document describes version 0.1.0 of ArrayData::Test::Spec::Seekable (from Perl distribution ArrayData), released on 2021-04-11.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ArrayData>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ArrayData>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ArrayData>

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
