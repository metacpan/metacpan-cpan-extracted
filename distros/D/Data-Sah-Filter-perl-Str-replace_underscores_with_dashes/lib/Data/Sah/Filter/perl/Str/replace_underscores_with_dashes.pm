package Data::Sah::Filter::perl::Str::replace_underscores_with_dashes;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-17'; # DATE
our $DIST = 'Data-Sah-Filter-perl-Str-replace_underscores_with_dashes'; # DIST
our $VERSION = '0.003'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Replace underscores in string with dashes',
        examples => [
            {value=>'foo'},
            {value=>'foo_bar', filtered_value=>'foo-bar'},
        ],
        description => <<'_',

This is mostly created as a counterpart for the replace_dashes_with_underscores
filter (<pm:Data::Sah::Filter::perl::Str::replace_dashes_with_underscores>). So
far I haven't got a practical use for this.

_
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; \$tmp =~ s/_/-/g; \$tmp }",
    );

    $res;
}

1;
# ABSTRACT: Replace underscores in string with dashes

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::replace_underscores_with_dashes - Replace underscores in string with dashes

=head1 VERSION

This document describes version 0.003 of Data::Sah::Filter::perl::Str::replace_underscores_with_dashes (from Perl distribution Data-Sah-Filter-perl-Str-replace_underscores_with_dashes), released on 2022-07-17.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::replace_underscores_with_dashes"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::replace_underscores_with_dashes"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::replace_underscores_with_dashes"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 "foo" # valid, unchanged
 "foo_bar" # valid, becomes "foo-bar"

=for Pod::Coverage ^(meta|filter)$

=head1 DESCRIPTION

This is mostly created as a counterpart for the replace_dashes_with_underscores
filter (L<Data::Sah::Filter::perl::Str::replace_dashes_with_underscores>). So
far I haven't got a practical use for this.

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter-perl-Str-replace_underscores_with_dashes>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter-perl-Str-replace_underscores_with_dashes>.

=head1 SEE ALSO

L<Data::Sah::Filter::perl::Str::replace_dashes_with_underscores>

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter-perl-Str-replace_underscores_with_dashes>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
