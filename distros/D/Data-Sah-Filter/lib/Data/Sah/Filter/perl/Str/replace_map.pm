package Data::Sah::Filter::perl::Str::replace_map;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-17'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.012'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Replace (map) some values with (to) other values',
        args => {
            map => {
                schema => 'hash*',
                req => 1,
            },
        },
        examples => [
            {value=>"foo", filter_args=>{map=>{foo=>"bar", baz=>"qux"}}, filtered_value=>"bar"},
            {value=>"bar", filter_args=>{map=>{foo=>"bar", baz=>"qux"}}},
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
        "do {",
        "    my \$tmp = $dt; ",
        "    my \$map = ".dmp($gen_args->{map})."; ",
        "    defined \$map->{\$tmp} ? \$map->{\$tmp} : \$tmp; ",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Replace (map) some values with (to) other values

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::replace_map - Replace (map) some values with (to) other values

=head1 VERSION

This document describes version 0.012 of Data::Sah::Filter::perl::Str::replace_map (from Perl distribution Data-Sah-Filter), released on 2022-07-17.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::replace_map"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::replace_map"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::replace_map"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 "foo" # filtered with args {map=>{baz=>"qux",foo=>"bar"}}, valid, becomes "bar"
 "bar" # filtered with args {map=>{baz=>"qux",foo=>"bar"}}, valid, unchanged

=head1 DESCRIPTION

This filter rule can be used to replace some (e.g. old) values to other (e.g.
new) values. For example, with this rule:

 [replace_map => {map => {burma => "myanmar", siam => "thailand"}}]

then "indonesia" or "myanmar" will be unchanged, but "burma" will be changed to
"myanmar" and "siam" will be changed to "thailand".

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

L<Complete::Util>'s L<complete_array_elem|Complete::Util/complete_array_elem>
also has a C<replace_map> option.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
