package Data::Sah::Filter::perl::Regexp::replace;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-09-23'; # DATE
our $DIST = 'Data-Sah-FilterBundle-Regexp'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Replace a regexp pattern with a simple string',
        might_fail => 0,
        args => {
            from_pat => {schema=>'re*', req=>1},
            to_str => {schema=>'str*', req=>1},
        },
        examples => [
            {value=>'0812000000', filter_args=>{from_pat=>qr/\A0/, to_str=>'+62'}, filtered_value=>'+62812000000'},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do { ", (
            "my \$tmp = $dt; my \$from_pat = ", dmp($gen_args->{from_pat}), "; my \$to_str = ", dmp($gen_args->{to_str}), "; ",
            "\$tmp =~ s/\$from_pat/\$to_str/g; ",
            "\$tmp ",
        ), "}",
    );

    $res;
}

1;
# ABSTRACT: Replace a regexp pattern with a simple string

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Regexp::replace - Replace a regexp pattern with a simple string

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::Regexp::replace (from Perl distribution Data-Sah-FilterBundle-Regexp), released on 2022-09-23.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Regexp::replace"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Regexp::replace"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Regexp::replace"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 "0812000000" # filtered with args {from_pat=>qr(\A0),to_str=>"+62"}, valid, becomes "+62812000000"

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-FilterBundle-Regexp>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-FilterBundle-Regexp>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-FilterBundle-Regexp>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
