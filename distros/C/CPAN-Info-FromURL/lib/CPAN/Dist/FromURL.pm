package CPAN::Dist::FromURL;

our $DATE = '2020-10-02'; # DATE
our $VERSION = '0.092'; # VERSION

use 5.010001;
use strict;
use warnings;

use CPAN::Info::FromURL qw(extract_cpan_info_from_url);

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_dist_from_url);

our %SPEC;

$SPEC{extract_cpan_dist_from_url} = {
    v => 1.1,
    summary => 'Extract CPAN distribution name from a URL',
    args => {
        url => {
            schema => 'str*',
            req => 1,
            pos => 0,
        },
    },
    args_as => 'array',
    result => {
        schema => 'str',
    },
    result_naked => 1,
    examples => [

        {
            name => "mcpan/pod/MOD",
            args => {url=>'https://metacpan.org/pod/Foo::Bar'},
            result => undef,
        },
        {
            name => "mcpan/pod/release/AUTHOR/DIST-VERSION/lib/MOD.pm",
            args => {url=>'http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm'},
            result => 'Mojolicious',
        },
        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },
    ],
};
sub extract_cpan_dist_from_url {
    my $url = shift;

    my $ecires = extract_cpan_info_from_url($url);
    return undef unless defined $ecires;
    $ecires->{dist};
}

1;
# ABSTRACT: Extract CPAN distribution name from a URL

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Dist::FromURL - Extract CPAN distribution name from a URL

=head1 VERSION

This document describes version 0.092 of CPAN::Dist::FromURL (from Perl distribution CPAN-Info-FromURL), released on 2020-10-02.

=head1 FUNCTIONS


=head2 extract_cpan_dist_from_url

Usage:

 extract_cpan_dist_from_url($url) -> str

Extract CPAN distribution name from a URL.

Examples:

=over

=item * Example #1 (mcpanE<sol>podE<sol>MOD):

 extract_cpan_dist_from_url("https://metacpan.org/pod/Foo::Bar"); # -> undef

=item * Example #2 (mcpanE<sol>podE<sol>releaseE<sol>AUTHORE<sol>DIST-VERSIONE<sol>libE<sol>MOD.pm):

 extract_cpan_dist_from_url("http://metacpan.org/pod/release/SRI/Mojolicious-6.46/lib/Mojo.pm"); # -> "Mojolicious"

=item * Example #3 (unknown):

 extract_cpan_dist_from_url("https://www.google.com/"); # -> undef

=back

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$url>* => I<str>


=back

Return value:  (str)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/CPAN-Info-FromURL>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-CPAN-Info-FromURL>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=CPAN-Info-FromURL>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<CPAN::Info::FromURL>, the more generic module which is used by this module.

L<CPAN::Author::FromURL>

L<CPAN::Module::FromURL>

L<CPAN::Release::FromURL>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
