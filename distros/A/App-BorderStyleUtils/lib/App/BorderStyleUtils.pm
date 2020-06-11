package App::BorderStyleUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-06-11'; # DATE
our $DIST = 'App-BorderStyleUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

$SPEC{list_border_style_modules} = {
    v => 1.1,
    summary => 'List BorderStyle modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_border_style_modules {
    require Module::List::Tiny;

    my %args = @_;

    my @res;
    my %resmeta;

    my $mods = Module::List::Tiny::list_modules(
        "", {list_modules => 1, recurse => 1});
    for my $mod (sort keys %$mods) {
        next unless $mod =~ /(\A|::)BorderStyle::/;
        push @res, $mod;
    }

    [200, "OK", \@res, \%resmeta];
}

1;
# ABSTRACT: CLI utilities related to border styles

__END__

=pod

=encoding UTF-8

=head1 NAME

App::BorderStyleUtils - CLI utilities related to border styles

=head1 VERSION

This document describes version 0.001 of App::BorderStyleUtils (from Perl distribution App-BorderStyleUtils), released on 2020-06-11.

=head1 DESCRIPTION

This distribution contains the following CLI utilities:

=over

=item * L<list-border-style-modules>

=back

=head1 FUNCTIONS


=head2 list_border_style_modules

Usage:

 list_border_style_modules(%args) -> [status, msg, payload, meta]

List BorderStyle modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-BorderStyleUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-BorderStyleUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-BorderStyleUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<BorderStyle>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
