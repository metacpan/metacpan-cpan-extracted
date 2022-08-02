## no critic: TestingAndDebugging::RequireUseStrict
package Data::CSel::Selection;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-06-07'; # DATE
our $DIST = 'Data-CSel'; # DIST
our $VERSION = '0.128'; # VERSION

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

This document describes version 0.128 of Data::CSel::Selection (from Perl distribution Data-CSel), released on 2022-06-07.

=head1 DESCRIPTION

A selection object holds zero or more nodes and lets you perform operations on
all of them. It is inspired by jQuery.

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-CSel>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-CSel>.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 CONTRIBUTING


To contribute, you can send patches by email/via RT, or send pull requests on
GitHub.

Most of the time, you don't need to build the distribution yourself. You can
simply modify the code, then test via:

 % prove -l

If you want to build the distribution (e.g. to try to install it locally on your
system), you can install L<Dist::Zilla>,
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2021, 2020, 2019, 2016 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-CSel>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
