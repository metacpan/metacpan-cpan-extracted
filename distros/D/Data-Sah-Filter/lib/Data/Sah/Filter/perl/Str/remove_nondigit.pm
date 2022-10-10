package Data::Sah::Filter::perl::Str::remove_nondigit;

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
        summary => 'Remove non-digit characters',
        examples => [
            {value=>"5551234567"},
            {value=>"555-123-4567", filtered_value=>"5551234567"},
            {value=>"(555) 123-4567", filtered_value=>"5551234567"},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do { ", (
            "my \$tmp = $dt; ",
            "\$tmp =~ s/\\D+//g; ",
            "\$tmp ",
        ), "}",
    );

    $res;
}

1;
# ABSTRACT: Remove non-digit characters

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::remove_nondigit - Remove non-digit characters

=head1 VERSION

This document describes version 0.013 of Data::Sah::Filter::perl::Str::remove_nondigit (from Perl distribution Data-Sah-Filter), released on 2022-07-24.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::remove_nondigit"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::remove_nondigit"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::remove_nondigit"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 5551234567 # valid, unchanged
 "555-123-4567" # valid, becomes 5551234567
 "(555) 123-4567" # valid, becomes 5551234567

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

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

This software is copyright (c) 2022, 2020 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
