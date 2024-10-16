package Data::Sah::Filter::perl::Phone::format;

use 5.010001;
use strict;
use warnings;

#use Data::Dmp;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-10-18'; # DATE
our $DIST = 'Data-Sah-FilterBundle-Phone'; # DIST
our $VERSION = '0.004'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Format international phone number with E.123 international standard using Number::Phone module',
        might_fail => 1,
        args => {
        },
        before_test_examples => sub { undef $ENV{SAH_FILTER_PHONE_FORMAT_COUNTRY} },
        examples => [
            {value=>'+62812000000', filtered_value=>'+62 812 000 000'},
            {value=>'+62 555 1234567', valid=>0},
            {value=>'0812000000', valid=>0},
            {
                value=>'0812000000',
                before_test=>sub { $ENV{SAH_FILTER_PHONE_FORMAT_COUNTRY} = 'ID' },
                summary=>'Valid if SAH_FILTER_PHONE_FORMAT_COUNTRY is set e.g. to ID',
                filtered_value=>'+62 812 000 000',
                after_test=>sub { undef $ENV{SAH_FILTER_PHONE_FORMAT_COUNTRY} },
            },
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    #my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{modules}{'Number::Phone'} //= 0;
    $res->{expr_filter} = join(
        "",
        "do {\n",
        "    my \$res;\n",
        "    my \$module = 'Number::Phone';\n",
        "    my \$c = \$ENV{SAH_FILTER_PHONE_FORMAT_COUNTRY};\n",
        "    if (defined \$c) {\n",
        "        if (\$c =~ /\\A[A-Z]{2}\\z/) {\n",
        "            \$module = 'Number::Phone::'.\$c; (my \$modulepm = \$module.'.pm') =~ s!::!/!g;\n",
        "            eval { require \$modulepm; 1 }; if (\$@) { \$module = 'Number::Phone::StubCountry::'.\$c }\n",
        "        } else { \$res = ['Configuration error: invalid syntax in environment variable SAH_FILTER_PHONE_FORMAT_COUNTRY']; goto L1 }\n",
        "    }\n",
        "    (my \$modulepm = \$module.'.pm') =~ s!::!/!g;\n",
        "    require \$modulepm;\n",
        "    my \$tmp = $dt; my \$ph = \$module->new(\$tmp); ",
        "    \$res = \$ph ? [undef, \$ph->format] : ['Invalid phone number '.\$tmp, \$tmp];\n",
        "    \$res;\n",
        "}",
    );

    $res;
}

1;
# ABSTRACT: Format international phone number with E.123 international standard using Number::Phone module

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Phone::format - Format international phone number with E.123 international standard using Number::Phone module

=head1 VERSION

This document describes version 0.004 of Data::Sah::Filter::perl::Phone::format (from Perl distribution Data-Sah-FilterBundle-Phone), released on 2022-10-18.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Phone::format"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Phone::format"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Phone::format"]]);
 # $errmsg will be empty/undef when filtering succeeds
 my ($errmsg, $filtered_value) = $filter->($some_data);

=head2 Sample data and filtering results

 "+62812000000" # valid, becomes "+62 812 000 000"
 "+62 555 1234567" # INVALID (Invalid phone number +62 555 1234567), unchanged
 "0812000000" # valid, becomes "+62 812 000 000"
 "0812000000" # valid, becomes "+62 812 000 000" (Valid if SAH_FILTER_PHONE_FORMAT_COUNTRY is set e.g. to ID)

=for Pod::Coverage ^(meta|filter)$

=head1 ENVIRONMENT

=head2 SAH_FILTER_PHONE_FORMAT_COUNTRY

String, 2-letter ISO code. Set country to use.

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
L<Dist::Zilla::PluginBundle::Author::PERLANCAR>,
L<Pod::Weaver::PluginBundle::Author::PERLANCAR>, and sometimes one or two other
Dist::Zilla- and/or Pod::Weaver plugins. Any additional steps required beyond
that are considered a bug and can be reported to me.

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
