package ColorThemeBase::Base;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-19'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.008'; # VERSION

use strict 'subs', 'vars';
#use warnings;
use parent 'ColorThemeBase::Constructor';

sub get_struct {
    my $self_or_class = shift;
    if (ref $self_or_class) {
        \%{"$self_or_class->{orig_class}::THEME"};
    } else {
        \%{"$self_or_class\::THEME"};
    }
}

sub get_args {
    my $self = shift;
    $self->{args};
}

1;
# ABSTRACT: A suitable base class for all ColorTheme::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorThemeBase::Base - A suitable base class for all ColorTheme::* modules

=head1 VERSION

This document describes version 0.008 of ColorThemeBase::Base (from Perl distribution ColorThemeBase-Static), released on 2020-06-19.

=head1 DESCRIPTION

=for Pod::Coverage ^(.+)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
