package Data::Sah::Filter::perl::Phone::format_idn;

use 5.010001;
use strict;
use warnings;

#use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-17'; # DATE
our $DIST = 'Data-Sah-FilterBundle-Phone'; # DIST
our $VERSION = '0.001'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Format Indonesian phone number with E.123 international standard using Number::Phone::StubCountry::ID module',
        might_fail => 1,
        args => {
        },
        examples => [
            {value=>'+62812000000', filtered_value=>'+62 812 000 000'},
            {value=>'+62 555 1234567', valid=>0},
            {value=>'0812000000', filtered_value=>'+62 812 000 000'},
            {value=>'0812 000 000', filtered_value=>'+62 812 000 000'},
            {value=>'0812-000-000', filtered_value=>'+62 812 000 000'},
            {value=>'(022) 555-1234', filtered_value=>'+62 22 5551234'},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    #my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{modules}{'Number::Phone::StubCountry::ID'} //= 0;
    $res->{expr_filter} = join(
        "",
        "do { ", (
            "my \$tmp = $dt; my \$ph = Number::Phone::StubCountry::ID->new(\$tmp); ",
            "\$ph ? [undef, \$ph->format] : ['Invalid phone number '.\$tmp, \$tmp] ",
        ), "}",
    );

    $res;
}

1;
# ABSTRACT: Format Indonesian phone number with E.123 international standard using Number::Phone::StubCountry::ID module

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Phone::format_idn - Format Indonesian phone number with E.123 international standard using Number::Phone::StubCountry::ID module

=head1 VERSION

This document describes version 0.001 of Data::Sah::Filter::perl::Phone::format_idn (from Perl distribution Data-Sah-FilterBundle-Phone), released on 2022-07-17.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Phone::format_idn"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Phone::format_idn"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Phone::format_idn"]]);
 # $errmsg will be empty/undef when filtering succeeds
 my ($errmsg, $filtered_value) = $filter->($some_data);

=head2 Sample data and filtering results

 "+62812000000" # valid, becomes "+62 812 000 000"
 "+62 555 1234567" # INVALID (Invalid phone number +62 555 1234567), unchanged
 "0812000000" # valid, becomes "+62 812 000 000"
 "0812 000 000" # valid, becomes "+62 812 000 000"
 "0812-000-000" # valid, becomes "+62 812 000 000"
 "(022) 555-1234" # valid, becomes "+62 22 5551234"

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-FilterBundle-Phone>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-FilterBundle-Phone>.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla plugin and/or Pod::Weaver::Plugin. Any additional steps required
beyond that are considered a bug and can be reported to me.

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2022 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-FilterBundle-Phone>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
