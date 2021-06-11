package App::tabledata;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-06-11'; # DATE
our $DIST = 'App-tabledata'; # DIST
our $VERSION = '0.001'; # VERSION

use 5.010001;
use strict;
use warnings;
use Log::ger;

our %SPEC;

our %argspecopt_module = (
    module => {
        schema => 'perl::tabledata::modname_with_optional_args*',
        cmdline_aliases => {m=>{}},
        pos => 0,
    },
);

#our %argspecopt_modules = (
#    modules => {
#        schema => 'perl::tabledata::modnames_with_optional_args*',
#    },
#);

sub _list_installed {
    require Module::List::More;
    my $mods = Module::List::More::list_modules(
        "TableData::",
        {
            list_modules  => 1,
            list_pod      => 0,
            recurse       => 1,
            return_path   => 1,
        });
    my @res;
    for my $mod0 (sort keys %$mods) {
        (my $mod = $mod0) =~ s/\ATableData:://;

        push @res, {
            name => $mod,
            path => $mods->{$mod0}{module_path},
        };
     }
    \@res;
}

$SPEC{tabledata} = {
    v => 1.1,
    summary => 'Show content of TableData modules (plus a few other things)',
    args => {
        %argspecopt_module,
        action => {
            schema  => ['str*', {in=>[
                'list_actions',
                'list_installed',
                #'list_cpan',
                'dump_as_aoaos',
                'dump_as_aohos',
                'dump_as_csv',
                'list_columns',
                'count_rows',
                'pick_rows',
                #'stat',
            ]}],
            default => 'dump_as_aoaos',
            cmdline_aliases => {
                L => {
                    summary=>'List installed TableData::*',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'list_installed' },
                },
                #C => {
                #    summary=>'List TableData::* on CPAN',
                #    is_flag => 1,
                #    code => sub { my $args=shift; $args->{action} = 'list_cpan' },
                #},
                R => {
                    summary=>'Pick random rows from an TableData module',
                    is_flag => 1,
                    code => sub { my $args=shift; $args->{action} = 'pick_rows' },
                },
                #S => {
                #    summary=>'Show statistics contained in the TableData module',
                #    is_flag => 1,
                #    code => sub { my $args=shift; $args->{action} = 'stat' },
                #},
            },
        },
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
        num => {
            summary => 'Number of rows to pick (for -R)',
            schema => 'posint*',
            default => 1,
            cmdline_aliases => {n=>{}},
        },
        #lcpan => {
        #    schema => 'bool',
        #    summary => 'Use local CPAN mirror first when available (for -C)',
        #},
    },
    examples => [
    ],
};
sub tabledata {
    my %args = @_;
    my $action = $args{action} // 'dump';

    if ($action eq 'list_actions') {
        return [200, "OK", $SPEC{tabledata}{args}{action}{schema}[1]{in}];
    }

    if ($action eq 'list_installed') {
        my @rows;
        for my $row (@{ _list_installed() }) {
            push @rows, $args{detail} ? $row : $row->{name};
        }
        return [200, "OK", \@rows];
    }

    return [400, "Please specify module"] unless defined $args{module};

    require Module::Load::Util;
    my $obj = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"TableData"}, $args{module});

    if ($action eq 'pick_rows') {
        return [200, "OK", [$obj->pick_items(n=>$args{num})]];
    }

    if ($action eq 'list_columns') {
        return [200, "OK", [$obj->get_column_names]];
    }

    if ($action eq 'count_columns') {
        return [200, "OK", scalar $obj->get_column_count];
    }

    if ($action eq 'count_rows') {
        return [200, "OK", scalar $obj->get_row_count];
    }

    if ($action eq 'dump_as_csv') {
        return [200, "OK", scalar $obj->as_csv];
    }

    if ($action eq 'dump_as_aohos') {
        return [200, "OK", [$obj->get_all_rows_hashref],
                {'table.fields'=>[$obj->get_column_names]}];
    }

    # dump_as_aoaos
    return [200, "OK", [$obj->get_all_rows_arrayref],
            {'table.fields'=>[$obj->get_column_names]}];
}

1;
# ABSTRACT: Show content of TableData modules (plus a few other things)

__END__

=pod

=encoding UTF-8

=head1 NAME

App::tabledata - Show content of TableData modules (plus a few other things)

=head1 VERSION

This document describes version 0.001 of App::tabledata (from Perl distribution App-tabledata), released on 2021-06-11.

=head1 SYNOPSIS

See the included script L<arraydata>.

=head1 FUNCTIONS


=head2 tabledata

Usage:

 tabledata(%args) -> [$status_code, $reason, $payload, \%result_meta]

Show content of TableData modules (plus a few other things).

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<action> => I<str> (default: "dump_as_aoaos")

=item * B<detail> => I<bool>

=item * B<module> => I<perl::tabledata::modname_with_optional_args>

=item * B<num> => I<posint> (default: 1)

Number of rows to pick (for -R).


=back

Returns an enveloped result (an array).

First element ($status_code) is an integer containing HTTP-like status code
(200 means OK, 4xx caller error, 5xx function error). Second element
($reason) is a string containing error message, or something like "OK" if status is
200. Third element ($payload) is the actual result, but usually not present when enveloped result is an error response ($status_code is not 2xx). Fourth
element (%result_meta) is called result metadata and is optional, a hash
that contains extra information, much like how HTTP response headers provide additional metadata.

Return value:  (any)

=head1 ENVIRONMENT

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-tabledata>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-tabledata>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-tabledata>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<ArrayData> and C<ArrayData::*> modules.

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
