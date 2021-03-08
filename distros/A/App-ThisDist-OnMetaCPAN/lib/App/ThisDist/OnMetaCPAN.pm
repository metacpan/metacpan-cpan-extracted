package App::ThisDist::OnMetaCPAN;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-03-07'; # DATE
our $DIST = 'App-ThisDist-OnMetaCPAN'; # DIST
our $VERSION = '0.002'; # VERSION

use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'this-dist-on-metacpan and some other CLIs',
};

$SPEC{this_dist_on_metacpan} = {
    v => 1.1,
    summary => 'Open MetaCPAN release page for "the current distribution"',
    description => <<'_',

This is a thin wrapper for <prog:this-dist>. See its documentation for details
on how the script determines "the current distribution".

_
    args => {},
    deps => {
        prog => 'this-dist',
    },
};
sub this_dist_on_metacpan {
    require Browser::Open;

    my $dist = `this-dist`;
    return [412, "this-dist failed"] unless length $dist;
    chomp($dist);
    Browser::Open::open_browser("https://metacpan.org/release/$dist");
    [200];
}

$SPEC{this_mod_on_metacpan} = {
    v => 1.1,
    args => {},
    summary => 'Open MetaCPAN module page for "the current module"',
    description => <<'_',

This is a thin wrapper for <prog:this-mod>. See its documentation for details on
how the script determines "the current module".

_
    deps => {
        prog => 'this-mod',
    },
};
sub this_mod_on_metacpan {
    require Browser::Open;

    my $mod = `this-mod`;
    return [412, "this-mod failed"] unless length $mod;
    chomp($mod);
    Browser::Open::open_browser("https://metacpan.org/pod/$mod");
    [200];
}

1;
# ABSTRACT: this-dist-on-metacpan and some other CLIs

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ThisDist::OnMetaCPAN - this-dist-on-metacpan and some other CLIs

=head1 VERSION

This document describes version 0.002 of App::ThisDist::OnMetaCPAN (from Perl distribution App-ThisDist-OnMetaCPAN), released on 2021-03-07.

=head1 DESCRIPTION

This distribution provides the following CLIs:

=over

=item * L<this-dist-on-metacpan>

=item * L<this-mod-on-metacpan>

=back



=head1 FUNCTIONS


=head2 this_dist_on_metacpan

Usage:

 this_dist_on_metacpan() -> [status, msg, payload, meta]

Open MetaCPAN release page for "the current distribution".

This is a thin wrapper for L<this-dist>. See its documentation for details
on how the script determines "the current distribution".

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 this_mod_on_metacpan

Usage:

 this_mod_on_metacpan() -> [status, msg, payload, meta]

Open MetaCPAN module page for "the current module".

This is a thin wrapper for L<this-mod>. See its documentation for details on
how the script determines "the current module".

This function is not exported.

No arguments.

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ThisDist-OnMetaCPAN>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ThisDist-OnMetaCPAN>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ThisDist-OnMetaCPAN>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::ThisDist>

L<lcpan> subcommands: C<lcpan metacpan-mod>, C<lcpan metacpan-dist>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
