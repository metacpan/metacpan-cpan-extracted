package Data::CSel::Selection;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-07-01'; # DATE
our $DIST = 'Data-CSel'; # DIST
our $VERSION = '0.125'; # VERSION

sub new {
    my $class = shift;
    bless [@_], $class;
}

sub AUTOLOAD {
    my $method = $AUTOLOAD;
    $method =~ s/.*:://;

    my $self = shift;
    for (@$self) {
        $self->$method if $self->can($method);
    }
}

1;
# ABSTRACT: Selection object

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::CSel::Selection - Selection object

=head1 VERSION

This document describes version 0.125 of Data::CSel::Selection (from Perl distribution Data-CSel), released on 2021-07-01.

=head1 DESCRIPTION

A selection object holds zero or more nodes and lets you perform operations on
all of them. It is inspired by jQuery.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021, 2020, 2019, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
