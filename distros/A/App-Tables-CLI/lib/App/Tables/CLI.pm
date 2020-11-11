package App::Tables::CLI;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2020-11-11'; # DATE
our $DIST = 'App-Tables-CLI'; # DIST
our $VERSION = '0.003'; # VERSION

use 5.010001;
#IFUNBUILT
# use strict;
# use warnings;
#END IFUNBUILT

#use PerlX::Maybe;

our %SPEC;

our %arg0_table = (
    table => {
        summary => 'Tables::* module name without the prefix, e.g. Locale::US::States '.
            'for Tables::Locale::US::States',
        schema => 'perl::tables::modname_with_optional_args*',
        req => 1,
        pos => 0,
    },
);

#our %argopt_table_args = (
#    table_args => {
#        summary => 'Arguments to pass to Tables::* class constructor',
#        schema => [hash => of=>'str*'],
#        cmdline_aliases => {A=>{}},
#    },
#);

$SPEC{list_installed_tables_modules} = {
    v => 1.1,
    summary => 'List installed Tables::* modules',
    args => {
        detail => {
            schema => 'bool*',
            cmdline_aliases => {l=>{}},
        },
    },
};
sub list_installed_tables_modules {
    require Module::List::Tiny;

    my %args = @_;

    my $mods = Module::List::Tiny::list_modules(
        'Tables::', {list_modules=>1, recurse=>1});
    my @rows;
    for my $mod (sort keys %$mods) {
        (my $table = $mod) =~ s/^Tables:://;
        push @rows, {table=>$table};
    }

    @rows = map { $_->{table} } @rows unless $args{detail};

    [200, "OK", \@rows];
}

$SPEC{show_tables_module} = {
    v => 1.1,
    summary => 'Show contents of a Tables::* module',
    args => {
        %arg0_table,
        as => {
            schema => ['str*', in=>['aoaos', 'aohos', 'csv']],
            default => 'aoaos',
        },
    },
};
sub show_tables_module {
    require Module::Load::Util;

    my %args = @_;

    my $as = $args{as} // 'aoaos';

    my $table = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"Tables"}, $args{table});

    if ($as eq 'csv') {
        return [200, "OK", $table->as_csv, {'cmdline.skip_format'=>1}];
    }

    my @rows;
    while (1) {
        my $row = $as eq 'aohos' ? $table->get_row_hashref : $table->get_row_arrayref;
        last unless $row;
        push @rows, $row;
    }
    [200, "OK", \@rows, {'table.fields'=>scalar $table->get_column_names}];
}

$SPEC{get_tables_module_info} = {
    v => 1.1,
    summary => 'Show information about a Tables::* module',
    args => {
        %arg0_table,
    },
};
sub get_tables_module_info {
    require Module::Load::Util;

    my %args = @_;

    my $table = Module::Load::Util::instantiate_class_with_optional_args(
        {ns_prefix=>"Tables"}, $args{table});

    return [200, "OK", {
        table => $args{table},
        #module => $mod,
        column_count => $table->get_column_count,
        column_names => $table->get_column_names,
        row_count => $table->get_row_count,
    }];
}

1;
# ABSTRACT: Manipulate Tables::* modules

__END__

=pod

=encoding UTF-8

=head1 NAME

App::Tables::CLI - Manipulate Tables::* modules

=head1 VERSION

This document describes version 0.003 of App::Tables::CLI (from Perl distribution App-Tables-CLI), released on 2020-11-11.

=head1 FUNCTIONS


=head2 get_tables_module_info

Usage:

 get_tables_module_info(%args) -> [status, msg, payload, meta]

Show information about a Tables::* module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<table>* => I<perl::tables::modname_with_optional_args>

Tables::* module name without the prefix, e.g. Locale::US::States for Tables::Locale::US::States.


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 list_installed_tables_modules

Usage:

 list_installed_tables_modules(%args) -> [status, msg, payload, meta]

List installed Tables::* modules.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<detail> => I<bool>


=back

Returns an enveloped result (an array).

First element (status) is an integer containing HTTP status code
(200 means OK, 4xx caller error, 5xx function error). Second element
(msg) is a string containing error message, or 'OK' if status is
200. Third element (payload) is optional, the actual result. Fourth
element (meta) is called result metadata and is optional, a hash
that contains extra information.

Return value:  (any)



=head2 show_tables_module

Usage:

 show_tables_module(%args) -> [status, msg, payload, meta]

Show contents of a Tables::* module.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<as> => I<str> (default: "aoaos")

=item * B<table>* => I<perl::tables::modname_with_optional_args>

Tables::* module name without the prefix, e.g. Locale::US::States for Tables::Locale::US::States.


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

Please visit the project's homepage at L<https://metacpan.org/release/App-Tables-CLI>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-Tables-CLI>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://rt.cpan.org/Public/Dist/Display.html?Name=App-Tables-CLI>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<Tables>

L<td> from L<App::td>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2020 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
