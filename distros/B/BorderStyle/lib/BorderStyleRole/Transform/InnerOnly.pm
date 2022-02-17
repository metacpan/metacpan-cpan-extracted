package BorderStyleRole::Transform::InnerOnly;

use strict;
use 5.010001;
use Role::Tiny;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-02-14'; # DATE
our $DIST = 'BorderStyle'; # DIST
our $VERSION = '3.0.2'; # VERSION

around get_border_char => sub {
    my $orig = shift;
    my ($self, %args) = @_;

    my $char = $args{char} or die "Please specify 'char'";
    if ($char =~ /_[tblr]\z/) {
        return '';
    } else {
        return $orig->(@_);
    }
};

1;
# ABSTRACT: Strip outer border characters

__END__

=pod

=encoding UTF-8

=head1 NAME

BorderStyleRole::Transform::InnerOnly - Strip outer border characters

=head1 VERSION

This document describes version 3.0.2 of BorderStyleRole::Transform::InnerOnly (from Perl distribution BorderStyle), released on 2022-02-14.

=head1 SYNOPSIS

 package BorderStyle::MyStyle;
 use Role::Tiny::With;
 with 'BorderStyle::OtherStyle';
 with 'BorderStyleRole::Transform::InnerOnly';

 ...
 1;

=head1 DESCRIPTION

This role modifies C<get_border_char()> to return empty string (C<''>) when
requested border character is one of the outer borders (C</_[tblr]$>>).
Otherwise, it passes to the original routine.

=for Pod::Coverage ^(.+)$

=head1 MODIFIED METHODS

=head2 get_border_char

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/BorderStyle>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-BorderStyle>.

=head1 SEE ALSO

L<BorderStyleRole::Transform::OuterOnly>

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

This software is copyright (c) 2022, 2021, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=BorderStyle>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
