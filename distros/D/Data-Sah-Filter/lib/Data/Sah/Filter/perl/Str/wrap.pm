package Data::Sah::Filter::perl::Str::wrap;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-21'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.021'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Wrap text',
        args => {
            columns => {
                schema => 'uint*',
                default => 72,
            },
        },
        examples => [
            {value=>"foo"},
            {value=>"foo foo foo foo"},
            {value=>"foo foo foo foo", filter_args=>{columns=>4}, filtered_value=>"foo\nfoo\nfoo\nfoo"},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{modules}{"Text::Wrap"} //= 0;

    $res->{expr_filter} = join(
        "",
        "do { ", (
            "local \$Text::Wrap::columns = ", (($gen_args->{columns} // 72)+0), "; ",
            "Text::Wrap::wrap('', '', $dt); ",
        ), "}",
    );

    $res;
}

1;
# ABSTRACT: Wrap text

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::wrap - Wrap text

=head1 VERSION

This document describes version 0.021 of Data::Sah::Filter::perl::Str::wrap (from Perl distribution Data-Sah-Filter), released on 2023-06-21.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::wrap"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::wrap"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::wrap"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 "foo" # valid, unchanged
 "foo foo foo foo" # valid, unchanged
 "foo foo foo foo" # filtered with args {columns=>4}, valid, becomes "foo\nfoo\nfoo\nfoo"

=head1 DESCRIPTION

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Str::oneline>

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

This software is copyright (c) 2023, 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
