package ColorTheme::Test::Dynamic;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-09'; # DATE
our $DIST = 'ColorThemeBase-Static'; # DIST
our $VERSION = '0.006'; # VERSION

use strict;
use warnings;
use parent 'ColorThemeBase::Base';

our %THEME = (
    v => 2,
    summary => 'A simple color theme',
    dynamic => 1,
    args => {
        tone => {schema=>['str*', in=>['red','green']], req=>1},
        opt1 => {schema=>'str*', default=>'foo'},
        opt2 => {schema=>'str*'},
    },
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

This document describes version 0.006 of ColorTheme::Test::Dynamic (from Perl distribution ColorThemeBase-Static), released on 2020-06-09.

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
