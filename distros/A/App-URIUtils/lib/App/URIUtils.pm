package App::URIUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-10-30'; # DATE
our $DIST = 'App-URIUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Utilities related to URI/URL',
};

$SPEC{parse_url} = {
    v => 1.1,
    summary => 'Parse URL string into a hash of information',
    args => {
        url => {schema => 'str*', req=>1, pos=>0},
        base => {schema => 'str*', pos=>1},
    },
    result_naked => 1,
};
sub parse_url {
    require URI::URL;

    my %args = @_;
    my $url = URI::URL->new($args{url}, $args{base});
    +{
        orig => $args{url},
        base => $args{base},

        scheme => $url->scheme,
        has_recognized_scheme => $url->has_recognized_scheme,
        opaque => $url->opaque,
        path => $url->path, # unescaped string
        fragment => $url->fragment,
        canonical => $url->canonical . "",
        authority => $url->authority,
        query => $url->query, # escaped

        # server/host methods
        host => $url->host,
        port => $url->port,
        default_port => $url->default_port,

        #abs_path  => $url->abs_path,
        full_path => $url->full_path, # abs_path || "/"

    };
}

1;
# ABSTRACT: Utilities related to URI/URL

__END__

=pod

=encoding UTF-8

=head1 NAME

App::URIUtils - Utilities related to URI/URL

=head1 VERSION

This document describes version 0.001 of App::URIUtils (from Perl distribution App-URIUtils), released on 2020-10-30.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<parse-url>

=back

=head1 FUNCTIONS


=head2 parse_url

Usage:

 parse_url(%args) -> any

Parse URL string into a hash of information.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<base> => I<str>

=item * B<url>* => I<str>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-URIUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-URIUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-URIUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
