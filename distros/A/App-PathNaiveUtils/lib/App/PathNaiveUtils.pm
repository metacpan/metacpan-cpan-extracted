package App::PathNaiveUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-12'; # DATE
our $DIST = 'App-PathNaiveUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;

use Path::Naive;

our %SPEC;

$SPEC{abs_path} = {
    v => 1.1,
    args_as => 'array',
    args => {
        path     => { schema=>['pathname::unix*'], req=>1, pos=>0 },
        basepath => { schema=>['pathname::unix*'], req=>1, pos=>1 },
    },
    result_naked => 1,
};
sub abs_path {
    Path::Naive::abs_path(@_);
}

$SPEC{concat_path} = {
    v => 1.1,
    args_as => 'array',
    args => {
        paths => { schema=>['array*', of=>'pathname::unix*'], req=>1, pos=>0, slurpy=>1 },
    },
    result_naked => 1,
};
sub concat_path {
    Path::Naive::concat_path(@_);
}

$SPEC{concat_and_normalize_path} = {
    v => 1.1,
    args_as => 'array',
    args => {
        paths => { schema=>['array*', of=>'pathname::unix*'], req=>1, pos=>0, slurpy=>1 },
    },
    result_naked => 1,
};
sub concat_and_normalize_path {
    Path::Naive::concat_and_normalize_path(@_);
}

$SPEC{is_abs_path} = {
    v => 1.1,
    args => {
        path     => { schema=>['pathname::unix*'], req=>1, pos=>0 },
        quiet    => { schema=>'true*', cmdline_aliases=>{q=>{}} },
    },
};
sub is_abs_path {
    my %args = @_;
    my $is_abs = Path::Naive::is_abs_path($args{path});
    [200,
     "OK",
     ($args{quiet} ? "" : "Path $args{path} is ".($is_abs ? "" : "NOT ")."absolute"),
     {'cmdline.exit_code' => $is_abs ? 0:1}];
}

$SPEC{normalize_path} = {
    v => 1.1,
    args_as => 'array',
    args => {
        path => { schema=>['pathname::unix*'], req=>1, pos=>0 },
    },
    result_naked => 1,
};
sub normalize_path {
    Path::Naive::normalize_path(@_);
}

$SPEC{split_path} = {
    v => 1.1,
    args_as => 'array',
    args => {
        path => { schema=>['pathname::unix*'], req=>1, pos=>0 },
    },
    result_naked => 1,
};
sub split_path {
    [Path::Naive::split_path(@_)];
}

1;
# ABSTRACT: Utilities related to Path::Naive

__END__

=pod

=encoding UTF-8

=head1 NAME

App::PathNaiveUtils - Utilities related to Path::Naive

=head1 VERSION

This document describes version 0.001 of App::PathNaiveUtils (from Perl distribution App-PathNaiveUtils), released on 2020-02-12.

=head1 DESCRIPTION

This distributions provides the following command-line utilities:

=over

=item * L<pn-abs-path>

=item * L<pn-concat-and-normalize-path>

=item * L<pn-concat-path>

=item * L<pn-is-abs-path>

=item * L<pn-normalize-path>

=item * L<pn-split-path>

=back

=head1 FUNCTIONS


=head2 abs_path

Usage:

 abs_path($path, $basepath) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$basepath>* => I<pathname::unix>

=item * B<$path>* => I<pathname::unix>


=back

Return value:  (any)



=head2 concat_and_normalize_path

Usage:

 concat_and_normalize_path($paths, ...) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$paths>* => I<array[pathname::unix]>


=back

Return value:  (any)



=head2 concat_path

Usage:

 concat_path($paths, ...) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$paths>* => I<array[pathname::unix]>


=back

Return value:  (any)



=head2 is_abs_path

Usage:

 is_abs_path(%args) -> [status, msg, payload, meta]

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<path>* => I<pathname::unix>

=item * B<quiet> => I<true>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 normalize_path

Usage:

 normalize_path($path) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$path>* => I<pathname::unix>


=back

Return value:  (any)



=head2 split_path

Usage:

 split_path($path) -> any

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<$path>* => I<pathname::unix>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-PathNaiveUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-PathNaiveUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-PathNaiveUtils>

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
