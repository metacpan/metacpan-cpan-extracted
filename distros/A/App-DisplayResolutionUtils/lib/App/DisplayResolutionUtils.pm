package App::DisplayResolutionUtils;

our $DATE = '2016-10-12'; # DATE
our $VERSION = '0.003'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{list_display_resolution_names} = {
    v => 1.1,
    summary => 'List known display resolution names',
    args => {
        query => {
            schema => 'str*',
            pos => 0,
        },
    },
    result => {
        schema => ['hash*', of=>'str*'],
    },
    result_naked => 1,
};
sub list_display_resolution_names {
    require Display::Resolution;

    my %args = @_;

    my $q = lc($args{query} // '');

    my $res0 = Display::Resolution::list_display_resolution_names();
    my $res = {};

    for (keys %$res0) {
        if (length $q) {
            next unless index(lc($_), $q) >= 0 ||
                index(lc($res0->{$_}), $q) >= 0;
        }
        $res->{$_} = $res0->{$_};
    }

    $res;
}

1;
# ABSTRACT: CLI utilities related to display resolution

__END__

=pod

=encoding UTF-8

=head1 NAME

App::DisplayResolutionUtils - CLI utilities related to display resolution

=head1 VERSION

This document describes version 0.003 of App::DisplayResolutionUtils (from Perl distribution App-DisplayResolutionUtils), released on 2016-10-12.

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<get-display-resolution-name>

=item * L<get-display-resolution-size>

=item * L<list-display-resolution-names>

=back

=head1 FUNCTIONS


=head2 list_display_resolution_names(%args) -> hash

List known display resolution names.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<query> => I<str>

=back

Return value:  (hash)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-DisplayResolutionUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-DisplayResolutionUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-DisplayResolutionUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Display::Resolution>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
