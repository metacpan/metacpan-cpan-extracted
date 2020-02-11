package Data::Sah::Filter::perl::Str::replace_map;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-02-11'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.004'; # VERSION

use 5.010001;
use strict;
use warnings;

use Data::Dmp;

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

This document describes version 0.004 of Data::Sah::Filter::perl::Str::replace_map (from Perl distribution Data-Sah-Filter), released on 2020-02-11.

=head1 SYNOPSIS

Use in Sah schema's C<prefilters> (or C<postfilters>) clause:

 ["str","prefilters",["Str::replace_map"]]

=head1 DESCRIPTION

This filter rule can be used to replace some (e.g. old) values to other (e.g.
new) values. For example, with this rule:

 [replace_map => {burma => "myanmar", siam => "thailand"}]

then "indonesia" or "myanmar" will be unchanged, but "burma" will be changed to
"myanmar" and "siam" will be changed to "thailand".

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Complete::Util>'s L<complete_array_elem|Complete::Util/complete_array_elem>
also has a C<replace_map> option.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
