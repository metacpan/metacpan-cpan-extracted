package Data::CSel::WrapStruct::Scalar;

our $DATE = '2016-09-01'; # DATE
our $VERSION = '0.002'; # VERSION

sub new {
    my ($class, $data_ref, $parent) = @_;
    bless [$data_ref, $parent];
}

sub value {
    ${$_[0][0]};
}

sub parent {
    $_[0][1];
}

sub children {
    [];
}

1;
# ABSTRACT: Wrap a scalar

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CSel::WrapStruct::Scalar - Wrap a scalar

=head1 VERSION

This document describes version 0.002 of Data::CSel::WrapStruct::Scalar (from Perl distribution Data-CSel-WrapStruct), released on 2016-09-01.

=for Pod::Coverage .*

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel-WrapStruct>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel-WrapStruct>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel-WrapStruct>

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
