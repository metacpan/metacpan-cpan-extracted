package Data::Sah::Filter::js::Str::upcase;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-24'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.013'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Convert string to uppercase',
        target_type => 'str',
        examples => [
            {value=>'foo', filtered_value=>'FOO'},
            {value=>'Foo', filtered_value=>'FOO'},
            {value=>'fOO', filtered_value=>'FOO'},
            {value=>'FOO'},
        ],
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{expr_filter} = "$dt.toUpperCase()";

    $res;
}

1;
# ABSTRACT: Convert string to uppercase

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::js::Str::upcase - Convert string to uppercase

=head1 VERSION

This document describes version 0.013 of Data::Sah::Filter::js::Str::upcase (from Perl distribution Data-Sah-Filter), released on 2022-07-24.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::upcase"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::upcase"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::upcase"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 "foo" # valid, becomes "FOO"
 "Foo" # valid, becomes "FOO"
 "fOO" # valid, becomes "FOO"
 "FOO" # valid, unchanged

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

Related filters: L<downcase|Data::Sah::Filter::js::Str::downcase>.

Synonym: L<uc|Data::Sah::Filter::js::Str::uc>,
L<uppercase|Data::Sah::Filter::js::Str::uppercase>.

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
