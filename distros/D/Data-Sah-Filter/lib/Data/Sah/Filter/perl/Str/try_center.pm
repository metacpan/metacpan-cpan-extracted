package Data::Sah::Filter::perl::Str::try_center;

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-04-25'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.016'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Try to center string in a width, fail if string is too long',
        might_fail => 1,
        args => {
            width => {
                schema => 'uint*',
                req => 1,
            },
        },
        examples => [
            {value=>"12", filter_args=>{width=>4}, filtered_value=>" 12 "},
            {value=>"12", filter_args=>{width=>3}, filtered_value=>"12 "},
            {value=>"12", filter_args=>{width=>2}, filtered_value=>"12"},
            {value=>"12", filter_args=>{width=>1}, valid=>0},
        ],
        description => <<'_',

This filter is mainly for testing.

_
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    my $gen_args = $fargs{args} // {};
    my $width = int($gen_args->{width});

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do {\n",
        "  my \$tmp = $dt;\n",
        "  my \$l = $width - length(\$tmp);\n",
        "  if (\$l < 0) { ['String is too wide for width', \$tmp] }\n",
        "  else { my \$l1 = int(\$l/2); my \$l2 = \$l - \$l1; [undef, (' ' x \$l1) . \$tmp . (' ' x \$l2)] }\n",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Try to center string in a width, fail if string is too long

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::try_center - Try to center string in a width, fail if string is too long

=head1 VERSION

This document describes version 0.016 of Data::Sah::Filter::perl::Str::try_center (from Perl distribution Data-Sah-Filter), released on 2023-04-25.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::try_center"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::try_center"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::try_center"]]);
 # $errmsg will be empty/undef when filtering succeeds
 my ($errmsg, $filtered_value) = $filter->($some_data);

=head2 Sample data and filtering results

 12 # filtered with args {width=>4}, valid, becomes " 12 "
 12 # filtered with args {width=>3}, valid, becomes "12 "
 12 # filtered with args {width=>2}, valid, unchanged
 12 # filtered with args {width=>1}, INVALID (String is too wide for width), unchanged

=for Pod::Coverage ^(meta|filter)$

=head1 DESCRIPTION

This filter is mainly for testing.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

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
