package CPAN::Module::FromURL;

our $DATE = '2020-10-02'; # DATE
our $VERSION = '0.091'; # VERSION

use 5.010001;
use strict;
use warnings;

use CPAN::Info::FromURL qw(extract_cpan_info_from_url);

use Exporter qw(import);
our @EXPORT_OK = qw(extract_cpan_module_from_url);

our %SPEC;

$SPEC{extract_cpan_module_from_url} = {
    v => 1.1,
    summary => 'Extract/guess CPAN module from a URL',
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
            result => 'Foo::Bar',
        },
        {
            name => 'mcpan/release/DIST',
            args => {url=>'https://metacpan.org/release/Foo-Bar'},
            result => 'Foo::Bar',
        },
        {
            name => "sco/search?module",
            args => {url=>'http://search.cpan.org/search?module=ToolSet'},
            result => 'ToolSet',
        },
        {
            name => "mojo",
            args => {url=>'https://mojolicious.org/perldoc/Mojo/DOM/CSS'},
            result => 'Mojo::DOM::CSS',
        },
        {
            name => 'unknown',
            args => {url=>'https://www.google.com/'},
            result => undef,
        },

    ],
};
sub extract_cpan_module_from_url {
    my $url = shift;

    my $ecires = extract_cpan_info_from_url($url);
    return undef unless $ecires;
    return $ecires->{module} if defined $ecires->{module};
    if (defined(my $mod = $ecires->{dist})) {
        $mod =~ s/-/::/g;
        return $mod;
    }
    undef;
}

1;
# ABSTRACT: Extract/guess CPAN module from a URL

__END__

=pod

=encoding UTF-8

=head1 NAME

CPAN::Module::FromURL - Extract/guess CPAN module from a URL

=head1 VERSION

This document describes version 0.091 of CPAN::Module::FromURL (from Perl distribution CPAN-Info-FromURL), released on 2020-10-02.

=head1 FUNCTIONS


=head2 extract_cpan_module_from_url

Usage:

 extract_cpan_module_from_url($url) -> str

ExtractE<sol>guess CPAN module from a URL.

Examples:

=over

=item * Example #1 (mcpanE<sol>podE<sol>MOD):

 extract_cpan_module_from_url("https://metacpan.org/pod/Foo::Bar"); # -> "Foo::Bar"

=item * Example #2 (mcpanE<sol>releaseE<sol>DIST):

 extract_cpan_module_from_url("https://metacpan.org/release/Foo-Bar"); # -> "Foo::Bar"

=item * Example #3 (scoE<sol>search?module):

 extract_cpan_module_from_url("http://search.cpan.org/search?module=ToolSet"); # -> "ToolSet"

=item * Example #4 (mojo):

 extract_cpan_module_from_url("https://mojolicious.org/perldoc/Mojo/DOM/CSS"); # -> "Mojo::DOM::CSS"

=item * Example #5 (unknown):

 extract_cpan_module_from_url("https://www.google.com/"); # -> undef

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

L<CPAN::Dist::FromURL>

L<CPAN::Release::FromURL>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020, 2018, 2017, 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
