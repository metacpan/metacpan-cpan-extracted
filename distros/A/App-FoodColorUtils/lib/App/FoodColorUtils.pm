package App::FoodColorUtils;

use 5.010001;
use strict;
use warnings;

use Exporter qw(import);
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2023-12-12'; # DATE
our $DIST = 'App-FoodColorUtils'; # DIST
our $VERSION = '0.001'; # VERSION

our %SPEC;

our @EXPORT_OK = qw(list_food_colors);

my $basic_colors = {
    black   => "000000",
    blue    => "0000ff",
    green   => "00ff00",
    red     => "ff0000",
    white   => "ffffff",
    yellow  => "ffff00",
};

sub _get_scheme_codes {
    my ($scheme) = @_;
    my $mod = "Graphics::ColorNames::$scheme";
    (my $modpm = "$mod.pm") =~ s!::!/!g;
    require $modpm;
    no strict 'refs'; ## no critic: TestingAndDebugging::ProhibitNoStrict
    my $res = &{"$mod\::NamesRgbTable"}();
    if (ref $res eq 'HASH') {
        for (keys %$res) {
            $res->{$_} = sprintf("%06s", $res->{$_});
        }
        return $res;
    } else {
        return {};
    }
}
our $data;
{
    require Color::RGB::Util;
    require Graphics::ColorNames;
    require Graphics::ColorNames::FoodColor;

    my $codes = _get_scheme_codes("FoodColor");

    my @data;
    for my $name (sort keys %$codes) {
        my $rgb = sprintf("%06x", $codes->{$name});
        push @data, [
            $name,
            $rgb,
            Color::RGB::Util::rgb_closest_to({colors=>$basic_colors}, $rgb),
        ];
    }
    @data = sort {
        $a->[2] cmp $b->[2] ||            # color
            $a->[1] cmp $b->[1] ||        # code
            $a->[0] cmp $b->[0]           # name
        } @data;

    $data = \@data;
}

my $res = gen_read_table_func(
    name => 'list_food_colors',
    summary => 'List food colors',
    table_data => $data,
    table_spec => {
        summary => 'List of food colors',
        fields => {
            name => {
                summary => 'Color name',
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            code => {
                summary => 'RGB code',
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
            color => {
                summary => 'The color of this food color',
                schema => 'str*',
                pos => 2,
                sortable => 1,
            },
        },
        pk => 'name',
    },
    description => <<'_',

Source data is generated from `Graphics::ColorNames::FoodColor`. so make sure
you have a relatively recent version of the module.

_
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: Command-line utilities related to food colors

__END__

=pod

=encoding UTF-8

=head1 NAME

App::FoodColorUtils - Command-line utilities related to food colors

=head1 VERSION

This document describes version 0.001 of App::FoodColorUtils (from Perl distribution App-FoodColorUtils), released on 2023-12-12.

=head1 SYNOPSIS

=head1 DESCRIPTION

This distribution contains the following command-line utilities:

# INSERT_EXECS_LIST

=head1 FUNCTIONS


=head2 list_food_colors

Usage:

 list_food_colors(%args) -> [$status_code, $reason, $payload, \%result_meta]

List food colors.

Source data is generated from C<Graphics::ColorNames::FoodColor>. so make sure
you have a relatively recent version of the module.

This function is not exported by default, but exportable.

Arguments ('*' denotes required arguments):

=over 4

=item * B<code> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.contains> => I<str>

Only return records where the 'code' field contains specified text.

=item * B<code.in> => I<array[str]>

Only return records where the 'code' field is in the specified values.

=item * B<code.is> => I<str>

Only return records where the 'code' field equals specified value.

=item * B<code.isnt> => I<str>

Only return records where the 'code' field does not equal specified value.

=item * B<code.max> => I<str>

Only return records where the 'code' field is less than or equal to specified value.

=item * B<code.min> => I<str>

Only return records where the 'code' field is greater than or equal to specified value.

=item * B<code.not_contains> => I<str>

Only return records where the 'code' field does not contain specified text.

=item * B<code.not_in> => I<array[str]>

Only return records where the 'code' field is not in the specified values.

=item * B<code.xmax> => I<str>

Only return records where the 'code' field is less than specified value.

=item * B<code.xmin> => I<str>

Only return records where the 'code' field is greater than specified value.

=item * B<color> => I<str>

Only return records where the 'color' field equals specified value.

=item * B<color.contains> => I<str>

Only return records where the 'color' field contains specified text.

=item * B<color.in> => I<array[str]>

Only return records where the 'color' field is in the specified values.

=item * B<color.is> => I<str>

Only return records where the 'color' field equals specified value.

=item * B<color.isnt> => I<str>

Only return records where the 'color' field does not equal specified value.

=item * B<color.max> => I<str>

Only return records where the 'color' field is less than or equal to specified value.

=item * B<color.min> => I<str>

Only return records where the 'color' field is greater than or equal to specified value.

=item * B<color.not_contains> => I<str>

Only return records where the 'color' field does not contain specified text.

=item * B<color.not_in> => I<array[str]>

Only return records where the 'color' field is not in the specified values.

=item * B<color.xmax> => I<str>

Only return records where the 'color' field is less than specified value.

=item * B<color.xmin> => I<str>

Only return records where the 'color' field is greater than specified value.

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<exclude_fields> => I<array[str]>

Select fields to return.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<name> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.contains> => I<str>

Only return records where the 'name' field contains specified text.

=item * B<name.in> => I<array[str]>

Only return records where the 'name' field is in the specified values.

=item * B<name.is> => I<str>

Only return records where the 'name' field equals specified value.

=item * B<name.isnt> => I<str>

Only return records where the 'name' field does not equal specified value.

=item * B<name.max> => I<str>

Only return records where the 'name' field is less than or equal to specified value.

=item * B<name.min> => I<str>

Only return records where the 'name' field is greater than or equal to specified value.

=item * B<name.not_contains> => I<str>

Only return records where the 'name' field does not contain specified text.

=item * B<name.not_in> => I<array[str]>

Only return records where the 'name' field is not in the specified values.

=item * B<name.xmax> => I<str>

Only return records where the 'name' field is less than specified value.

=item * B<name.xmin> => I<str>

Only return records where the 'name' field is greater than specified value.

=item * B<queries> => I<array[str]>

Search.

This will search all searchable fields with one or more specified queries. Each
query can be in the form of C<-FOO> (dash prefix notation) to require that the
fields do not contain specified string, or C</FOO/> to use regular expression.
All queries must match if the C<query_boolean> option is set to C<and>; only one
query should match if the C<query_boolean> option is set to C<or>.

=item * B<query_boolean> => I<str> (default: "and")

Whether records must match all search queries ('and') or just one ('or').

If set to C<and>, all queries must match; if set to C<or>, only one query should
match. See the C<queries> option for more details on searching.

=item * B<random> => I<bool> (default: 0)

Return records in random order.

=item * B<result_limit> => I<int>

Only return a certain number of records.

=item * B<result_start> => I<int> (default: 1)

Only return starting from the n'th record.

=item * B<sort> => I<array[str]>

Order records according to certain field(s).

A list of field names separated by comma. Each field can be prefixed with '-' to
specify descending order instead of the default ascending.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hashE<sol>associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-FoodColorUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-FoodColorUtils>.

=head1 SEE ALSO

L<App::FoodAdditivesUtils>

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

This software is copyright (c) 2023 by perlancar <perlancar@cpan.org>.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-FoodColorUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=cut
