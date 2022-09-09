package Data::Sah::Filter::perl::Str::try_decode_json;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2022-07-17'; # DATE
our $DIST = 'Data-Sah-Filter-perl-Str-try_decode_json'; # DIST
our $VERSION = '0.002'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'JSON-decode if we can, otherwise leave string as-is',
        examples => [
            {value=>undef, summary=>"Unfiltered"},
            {value=>"foo", summary=>"Unquoted becomes as-is"},
            {value=>"[1,", summary=>"Misquoted becomes as-is"},
            {value=>q("foo"), filtered_value=>"foo", summary=>"Quoted string becomes string"},
            {value=>q([1,2]), filtered_value=>[1,2], summary=>"Quoted array becomes array"},
            {value=>"null", filtered_value=>undef, summary=>"Bare null keyword becomes undef"},
        ],
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};

    $res->{modules}{"JSON::PP"} //= 0;
    $res->{expr_filter} = join(
        "",
        "do { my \$decoded; eval { \$decoded = JSON::PP->new->allow_nonref->decode($dt); 1 }; \$@ ? $dt : \$decoded }",
    );

    $res;
}

1;
# ABSTRACT: JSON-decode if we can, otherwise leave string as-is

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::try_decode_json - JSON-decode if we can, otherwise leave string as-is

=head1 VERSION

This document describes version 0.002 of Data::Sah::Filter::perl::Str::try_decode_json (from Perl distribution Data-Sah-Filter-perl-Str-try_decode_json), released on 2022-07-17.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::try_decode_json"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::try_decode_json"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::try_decode_json"]]);
 my $filtered_value = $filter->($some_data);

=head2 Sample data and filtering results

 undef # valid, unchanged
 "foo" # valid, unchanged
 "[1," # valid, unchanged
 "\"foo\"" # valid, becomes "foo"
 "[1,2]" # valid, becomes [1,2]
 "null" # valid, becomes undef

=head1 DESCRIPTION

This rule is sometimes convenient if you want to accept unquoted string or a
data structure (encoded in JSON). This means, compared to just decoding from
JSON, you don't have to always quote your string. But beware of traps like the
bare values C<null>, C<true>, C<false> becoming undef/1/0 in Perl instead of
string literals, because they can be JSON-decoded.

=for Pod::Coverage ^(meta|filter)$

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter-perl-Str-try_decode_json>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter-perl-Str-try_decode_json>.

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

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=Data-Sah-Filter-perl-Str-try_decode_json>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
