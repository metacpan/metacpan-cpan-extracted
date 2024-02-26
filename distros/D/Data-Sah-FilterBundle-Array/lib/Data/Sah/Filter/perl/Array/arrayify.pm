package Data::Sah::Filter::perl::Array::arrayify;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2024-02-06'; # DATE
our $DIST = 'Data-Sah-FilterBundle-Array'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Wrap non-array X to become [X]',
        args => {
        },
        examples => [
            {value=>[], filtered_value=>[]},
            {value=>[1,[]], filtered_value=>[1,[]]},
            {value=>"foo", filtered_value=>["foo"]},
            {value=>[{}], filtered_value=>[{}]},
        ],
    };
}

sub filter {
    my %fargs = @_;

    my $dt = $fargs{data_term};
    #my $gen_args = $fargs{args} // {};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; ref \$tmp eq 'ARRAY' ? \$tmp : [\$tmp] }",
    );

    $res;
}

1;
# ABSTRACT: Wrap non-array X to become [X]

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Array::arrayify - Wrap non-array X to become [X]

=head1 VERSION

This document describes version 0.002 of Data::Sah::Filter::perl::Array::arrayify (from Perl distribution Data-Sah-FilterBundle-Array), released on 2024-02-06.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Array::arrayify"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Array::arrayify"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Array::arrayify"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 [] # valid, unchanged
 [1,[]] # valid, unchanged
 "foo" # valid, becomes ["foo"]
 [{}] # valid, unchanged

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-FilterBundle-Array>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-FilterBundle-Array>.

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

This software is copyright (c) 2024 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-FilterBundle-Array>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
