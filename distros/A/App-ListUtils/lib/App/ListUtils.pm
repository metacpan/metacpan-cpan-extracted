package App::ListUtils;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-01'; # DATE
our $DIST = 'App-ListUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

our %argspec0_input = (
    input => {
        schema => 'str*',
        #req => 1,
        pos => 0,
        cmdline_src => 'stdin_or_files',
    },
);

$SPEC{get_common_prefix} = {
    v => 1.1,
    summary => 'Get common prefix from lines of text',
    args => {
        %argspec0_input,
    },
    result_naked => 1,
};
sub get_common_prefix {
    my %args = @_;

    chomp(my @lines = split /^/m, $args{input});

    require String::CommonPrefix;
    String::CommonPrefix::common_prefix(@lines);
}

$SPEC{get_common_suffix} = {
    v => 1.1,
    summary => 'Get common suffix from lines of text',
    args => {
        %argspec0_input,
    },
    result_naked => 1,
};
sub get_common_suffix {
    my %args = @_;

    chomp(my @lines = split /^/m, $args{input});

    require String::CommonSuffix;
    String::CommonSuffix::common_suffix(@lines);
}

$SPEC{bullet2ordered} = {
    v => 1.1,
    summary => 'Convert a bulleted list into an ordered list',
    args => {
        %argspec0_input,
    },
    result_naked => 1,
};
sub bullet2ordered {
    my %args = @_;

    [501];
}

$SPEC{ordered2bullet} = {
    v => 1.1,
    summary => 'Convert an ordered list into a bulleted list',
    args => {
        %argspec0_input,
    },
    result_naked => 1,
};
sub oredered2bullet {
    my %args = @_;

    [501];
}

$SPEC{bullet2comma} = {
    v => 1.1,
    summary => 'Convert a bulleted list into comma-separated',
    args => {
        %argspec0_input,
    },
    result_naked => 1,
};
sub bullet2comma {
    my %args = @_;

    chomp(my @lines = split /^/m, $args{input});

    require String::CommonPrefix;
    my $common_prefix = String::CommonPrefix::common_prefix(@lines);

    s/\A\Q$common_prefix// for @lines;
    join(", ", @lines) . "\n";
}

1;
# ABSTRACT: Command-line utilities related to lists in files

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ListUtils - Command-line utilities related to lists in files

=head1 VERSION

This document describes version 0.001 of App::ListUtils (from Perl distribution App-ListUtils), released on 2022-09-01.

=head1 SYNOPSIS

This distribution provides the following command-line utilities:

=over

=item * L<bullet2comma>

=item * L<get-common-prefix>

=item * L<get-common-suffix>

=back

=head1 DESCRIPTION

=head1 FUNCTIONS


=head2 bullet2comma

Usage:

 bullet2comma(%args) -> any

Convert a bulleted list into comma-separated.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>


=back

Return value:  (any)



=head2 bullet2ordered

Usage:

 bullet2ordered(%args) -> any

Convert a bulleted list into an ordered list.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>


=back

Return value:  (any)



=head2 get_common_prefix

Usage:

 get_common_prefix(%args) -> any

Get common prefix from lines of text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>


=back

Return value:  (any)



=head2 get_common_suffix

Usage:

 get_common_suffix(%args) -> any

Get common suffix from lines of text.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>


=back

Return value:  (any)



=head2 ordered2bullet

Usage:

 ordered2bullet(%args) -> any

Convert an ordered list into a bulleted list.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<input> => I<str>


=back

Return value:  (any)

=for Pod::Coverage .+

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ListUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ListUtils>.

=head1 SEE ALSO

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

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ListUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
