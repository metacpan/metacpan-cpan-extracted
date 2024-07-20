package ColorTheme::Test::Dynamic;

use strict;
use warnings;
use parent 'ColorThemeBase::Base';

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-07-17'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.009'; # VERSION

our %THEME = (
    v => 2,
    summary => 'A dynamic color theme',
    dynamic => 1,
    args => {
        tone => {schema=>['str*', in=>['red','green']], req=>1},
        opt1 => {schema=>'str*', default=>'foo'},
        opt2 => {schema=>'str*'},
    },
    examples => [
        {
            summary => 'An red tone',
            args => { tone => 'red' },
        },
    ],
);

sub list_items {
    my $self = shift;

    my @list;
    if ($self->{tone} eq 'red') {
        @list = ('red1', 'red2', 'red3');
    } else {
        @list = ('green1', 'green2', 'green3');
    }
    wantarray ? @list : \@list;
}

sub get_item_color {
    my ($self, $name, $args) = @_;

    +{
        red1 => 'ff0000',
        red2 => 'cc0000',
        red3 => '992211',
        green1 => '00ff00',
        green2 => '00cc00',
        green3 => '15a008',
    }->{$name};
}

1;
# ABSTRACT: A dynamic color theme

__END__

=pod

=encoding UTF-8

=head1 NAME

ColorTheme::Test::Dynamic - A dynamic color theme

=head1 VERSION

This document describes version 0.009 of ColorTheme::Test::Dynamic (from Perl distribution ColorThemeBase-Static), released on 2024-07-17.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/ColorThemeBase-Static>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-ColorThemeBase-Static>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2024, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=ColorThemeBase-Static>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
