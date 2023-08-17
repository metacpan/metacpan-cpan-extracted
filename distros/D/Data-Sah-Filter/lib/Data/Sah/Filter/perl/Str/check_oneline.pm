package Data::Sah::Filter::perl::Str::check_oneline;

use 5.010001;
use strict;
use warnings;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-06-21'; # DATE
our $DIST = 'Data-Sah-Filter'; # DIST
our $VERSION = '0.021'; # VERSION

sub meta {
    +{
        v => 1,
        summary => 'Check that string does not contain more than one line',
        description => <<'_',

You can also use the <pm:Sah> clause C<match> to achieve the same:

    # a schema, using 'match' clause and regex to match string that does not contain a newline
    ["str", {"match" => qr/\A(?!.*\R).*\z/}]

    # a schema, using reversed 'match' clause and regex to match newline
    ["str", {"!match" => '\\R'}]

_
        might_fail => 1,
        examples => [
            {value=>'', valid=>1},
            {value=>"foo", valid=>1},
            {value=>("foo bar\tbaz" x 10), valid=>1, summary=>"Long line, spaces and tabs are okay as long as it does not contain newline"},
            {value=>"foo\n", valid=>0, summary=>"Containing newline at the end counts as having more than oneline; use the Str::rtrim or Str::rtrim_newline if you want to remove trailing newline"},
            {value=>"foo\nbar", valid=>0},
            {value=>"\n", valid=>0},
        ],
    };
}

sub filter {
    my %args = @_;

    my $dt = $args{data_term};

    my $res = {};
    $res->{expr_filter} = join(
        "",
        "do { my \$tmp = $dt; \$tmp !~ /\\R/ ? [undef,\$tmp] : [\"String contains newline\"] }",
    );

    $res;
}

1;
# ABSTRACT: Check that string does not contain more than one line

__END__

=pod

=encoding UTF-8

=head1 NAME

Data::Sah::Filter::perl::Str::check_oneline - Check that string does not contain more than one line

=head1 VERSION

This document describes version 0.021 of Data::Sah::Filter::perl::Str::check_oneline (from Perl distribution Data-Sah-Filter), released on 2023-06-21.

=head1 SYNOPSIS

=head2 Using in Sah schema's C<prefilters> (or C<postfilters>) clause

 ["str","prefilters",[["Str::check_oneline"]]]

=head2 Using with L<Data::Sah>:

 use Data::Sah qw(gen_validator);
 
 my $schema = ["str","prefilters",[["Str::check_oneline"]]];
 my $validator = gen_validator($schema);
 if ($validator->($some_data)) { print 'Valid!' }

=head2 Using with L<Data::Sah:Filter> directly:

 use Data::Sah::Filter qw(gen_filter);

 my $filter = gen_filter([["Str::check_oneline"]]);
 # $errmsg will be empty/undef when filtering succeeds
 my ($errmsg, $filtered_value) = $filter->($some_data);

=head2 Sample data and filtering results

 "" # valid, unchanged
 "foo" # valid, unchanged
 "foo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbazfoo bar\tbaz" # valid, unchanged (Long line, spaces and tabs are okay as long as it does not contain newline)
 "foo\n" # INVALID (String contains newline), becomes undef (Containing newline at the end counts as having more than oneline; use the Str::rtrim or Str::rtrim_newline if you want to remove trailing newline)
 "foo\nbar" # INVALID (String contains newline), becomes undef
 "\n" # INVALID (String contains newline), becomes undef

=for Pod::Coverage ^(meta|filter)$

=head1 DESCRIPTION

You can also use the L<Sah> clause C<match> to achieve the same:

 # a schema, using 'match' clause and regex to match string that does not contain a newline
 ["str", {"match" => qr/\A(?!.*\R).*\z/}]
 
 # a schema, using reversed 'match' clause and regex to match newline
 ["str", {"!match" => '\\R'}]

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/Data-Sah-Filter>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-Data-Sah-Filter>.

=head1 SEE ALSO

=head2 Related filters

L<check_lowercase|Data::Sah::Filter::perl::Str::check_lowercase>.

L<uppercase|Data::Sah::Filter::perl::Str::uppercase> to convert string to
uppercase.

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
