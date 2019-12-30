package App::ScriptXUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2019-12-25'; # DATE
our $DIST = 'App-ScriptXUtils'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict 'subs', 'vars';
use warnings;

use Module::List::Tiny;
use Perinci::Sub::Gen::AccessTable qw(gen_read_table_func);

our %SPEC;

our %argopt_detail = (
    detail => {
        schema => 'bool*',
        cmdline_aliases => {l=>{}},
    },
);

my $res = gen_read_table_func(
    name => 'list_scriptx_plugins',
    summary => 'List locally installed ScriptX plugins',
    table_data => sub {
        my $mods = Module::List::Tiny::list_modules(
            'ScriptX::', {list_modules=>1, recurse=>1});

        my @rows;
        for my $mod (sort keys %$mods) {
            $mod =~ /\AScriptX::(.+)/ or next;
            my $plugin = $1;
            $plugin =~ /Base$/ and next; # by convention, this is base class only
            my $row = {plugin=>$plugin};
            (my $mod_pm = "$mod.pm") =~ s!::!/!g;
            require $mod_pm;
            my $meta = {}; eval { $meta = $mod->meta };
            $row->{summary} = $meta->{summary};
            $row->{dist} = ${"$mod\::DIST"};
            push @rows, $row;
        }
        return {data=>\@rows};
    },
    table_spec => {
        fields => {
            plugin => {
                schema => 'str*',
                pos => 0,
                sortable => 1,
            },
            summary => {
                schema => 'str*',
                pos => 1,
                sortable => 1,
            },
            dist => {
                schema => 'str*',
                pos => 2,
                sortable => 1,
            },
        },
        pk => 'plugin',
    },
);
die "Can't generate function: $res->[0] - $res->[1]" unless $res->[0] == 200;

1;
# ABSTRACT: Collection of CLI utilities for ScriptX

__END__

=pod

=encoding UTF-8

=head1 NAME

App::ScriptXUtils - Collection of CLI utilities for ScriptX

=head1 VERSION

This document describes version 0.001 of App::ScriptXUtils (from Perl distribution App-ScriptXUtils), released on 2019-12-25.

=head1 SYNOPSIS

This distribution provides the following command-line utilities related to
L<ScriptX>:

=over

=item * L<list-scriptx-plugins>

=back

=head1 FUNCTIONS


=head2 list_scriptx_plugins

Usage:

 list_scriptx_plugins(%args) -> [status, msg, payload, meta]

List locally installed ScriptX plugins.

REPLACE ME

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool> (default: 0)

Return array of full records instead of just ID fields.

By default, only the key (ID) field is returned per result entry.

=item * B<dist> => I<str>

Only return records where the 'dist' field equals specified value.

=item * B<dist.contains> => I<str>

Only return records where the 'dist' field contains specified text.

=item * B<dist.in> => I<array[str]>

Only return records where the 'dist' field is in the specified values.

=item * B<dist.is> => I<str>

Only return records where the 'dist' field equals specified value.

=item * B<dist.isnt> => I<str>

Only return records where the 'dist' field does not equal specified value.

=item * B<dist.max> => I<str>

Only return records where the 'dist' field is less than or equal to specified value.

=item * B<dist.min> => I<str>

Only return records where the 'dist' field is greater than or equal to specified value.

=item * B<dist.not_contains> => I<str>

Only return records where the 'dist' field does not contain specified text.

=item * B<dist.not_in> => I<array[str]>

Only return records where the 'dist' field is not in the specified values.

=item * B<dist.xmax> => I<str>

Only return records where the 'dist' field is less than specified value.

=item * B<dist.xmin> => I<str>

Only return records where the 'dist' field is greater than specified value.

=item * B<fields> => I<array[str]>

Select fields to return.

=item * B<plugin> => I<str>

Only return records where the 'plugin' field equals specified value.

=item * B<plugin.contains> => I<str>

Only return records where the 'plugin' field contains specified text.

=item * B<plugin.in> => I<array[str]>

Only return records where the 'plugin' field is in the specified values.

=item * B<plugin.is> => I<str>

Only return records where the 'plugin' field equals specified value.

=item * B<plugin.isnt> => I<str>

Only return records where the 'plugin' field does not equal specified value.

=item * B<plugin.max> => I<str>

Only return records where the 'plugin' field is less than or equal to specified value.

=item * B<plugin.min> => I<str>

Only return records where the 'plugin' field is greater than or equal to specified value.

=item * B<plugin.not_contains> => I<str>

Only return records where the 'plugin' field does not contain specified text.

=item * B<plugin.not_in> => I<array[str]>

Only return records where the 'plugin' field is not in the specified values.

=item * B<plugin.xmax> => I<str>

Only return records where the 'plugin' field is less than specified value.

=item * B<plugin.xmin> => I<str>

Only return records where the 'plugin' field is greater than specified value.

=item * B<query> => I<str>

Search.

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

=item * B<summary> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.contains> => I<str>

Only return records where the 'summary' field contains specified text.

=item * B<summary.in> => I<array[str]>

Only return records where the 'summary' field is in the specified values.

=item * B<summary.is> => I<str>

Only return records where the 'summary' field equals specified value.

=item * B<summary.isnt> => I<str>

Only return records where the 'summary' field does not equal specified value.

=item * B<summary.max> => I<str>

Only return records where the 'summary' field is less than or equal to specified value.

=item * B<summary.min> => I<str>

Only return records where the 'summary' field is greater than or equal to specified value.

=item * B<summary.not_contains> => I<str>

Only return records where the 'summary' field does not contain specified text.

=item * B<summary.not_in> => I<array[str]>

Only return records where the 'summary' field is not in the specified values.

=item * B<summary.xmax> => I<str>

Only return records where the 'summary' field is less than specified value.

=item * B<summary.xmin> => I<str>

Only return records where the 'summary' field is greater than specified value.

=item * B<with_field_names> => I<bool>

Return field names in each record (as hash/associative array).

When enabled, function will return each record as hash/associative array
(field name => value pairs). Otherwise, function will return each record
as list/array (field value, field value, ...).

=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-ScriptXUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-ScriptXUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-ScriptXUtils>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ScriptX>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2019 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
