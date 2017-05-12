package Complete::Env;

our $DATE = '2016-10-18'; # DATE
our $VERSION = '0.39'; # VERSION

use 5.010001;
use strict;
use warnings;

use Complete::Common qw(:all);

require Exporter;
our @ISA = qw(Exporter);
our @EXPORT_OK = qw(
                       complete_env
                       complete_env_elem
                       complete_path_env_elem
               );

our %SPEC;

$SPEC{':package'} = {
    v => 1.1,
    summary => 'Completion routines related to environment variables',
};

$SPEC{complete_env} = {
    v => 1.1,
    summary => 'Complete from environment variables',
    description => <<'_',

On Windows, environment variable names are all converted to uppercase. You can
use case-insensitive option (`ci`) to match against original casing.

_
    args => {
        word     => { schema=>[str=>{default=>''}], pos=>0, req=>1 },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_env {
    require Complete::Util;

    my %args  = @_;
    my $word     = $args{word} // "";
    if ($word =~ /^\$/) {
        Complete::Util::complete_array_elem(
            word=>$word, array=>[map {"\$$_"} keys %ENV],
        );
    } else {
        Complete::Util::complete_array_elem(
            word=>$word, array=>[keys %ENV],
        );
    }
}

$SPEC{complete_env_elem} = {
    v => 1.1,
    summary => 'Complete from elements of an environment variable',
    description => <<'_',

An environment variable like PATH contains colon- (or, on Windows, semicolon-)
separated elements. This routine complete from the elements of such variable.

_
    args => {
        word     => { schema=>[str=>{default=>''}], pos=>0, req=>1 },
        env      => {
            summary => 'Name of environment variable to use',
            schema  => 'str*',
            req => 1,
            pos => 1,
        },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_env_elem {
    require Complete::Util;

    my %args  = @_;
    my $word  = $args{word} // "";
    my $env   = $args{env};
    my @elems;
    if ($^O eq 'MSWin32') {
        @elems = split /;/, ($ENV{$env} // '');
    } else {
        @elems = split /:/, ($ENV{$env} // '');
    }
    Complete::Util::complete_array_elem(
        word=>$word, array=>\@elems,
    );
}

$SPEC{complete_path_env_elem} = {
    v => 1.1,
    summary => 'Complete from elements of PATH environment variable',
    description => <<'_',

PATH environment variable contains colon- (or, on Windows, semicolon-) separated
elements. This routine complete from those elements.

_
    args => {
        word     => { schema=>[str=>{default=>''}], pos=>0, req=>1 },
    },
    result_naked => 1,
    result => {
        schema => 'array',
    },
};
sub complete_path_env_elem {
    my %args  = @_;
    complete_env_elem(word => $args{word}, env => 'PATH');
}

1;
# ABSTRACT: Completion routines related to environment variables

__END__

=pod

=encoding UTF-8

=head1 NAME

Complete::Env - Completion routines related to environment variables

=head1 VERSION

This document describes version 0.39 of Complete::Env (from Perl distribution Complete-Env), released on 2016-10-18.

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 complete_env(%args) -> array

Complete from environment variables.

On Windows, environment variable names are all converted to uppercase. You can
use case-insensitive option (C<ci>) to match against original casing.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

=back

Return value:  (array)


=head2 complete_env_elem(%args) -> array

Complete from elements of an environment variable.

An environment variable like PATH contains colon- (or, on Windows, semicolon-)
separated elements. This routine complete from the elements of such variable.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<env>* => I<str>

Name of environment variable to use.

=item * B<word>* => I<str> (default: "")

=back

Return value:  (array)


=head2 complete_path_env_elem(%args) -> array

Complete from elements of PATH environment variable.

PATH environment variable contains colon- (or, on Windows, semicolon-) separated
elements. This routine complete from those elements.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<word>* => I<str> (default: "")

=back

Return value:  (array)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Complete-Env>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Complete-Env>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Complete-Env>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete>

Other C<Complete::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
