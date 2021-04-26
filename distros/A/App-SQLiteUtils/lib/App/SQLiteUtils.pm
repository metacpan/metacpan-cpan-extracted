package App::SQLiteUtils;

our $AUTHORITY = 'cpan:PERLANCAR'; # AUTHORITY
our $DATE = '2021-01-21'; # DATE
our $DIST = 'App-SQLiteUtils'; # DIST
our $VERSION = '0.002'; # VERSION

use 5.010001;
use strict;
use warnings;

our %SPEC;

sub _connect {
    my $args = shift;
    DBI->connect("dbi:SQLite:dbname=$args->{db_file}", undef, undef, {RaiseError=>1});
}

our %args_common = (
    db_file => {
        schema => 'filename*',
        req => 1,
        pos => 0,
    },
);

our %arg1_table = (
    table => {
        schema => 'str*',
        req => 1,
        pos => 1,
    },
);

$SPEC{list_sqlite_tables} = {
    v => 1.1,
    description => <<'_',

See also the `.tables` meta-command of the `sqlite3` CLI.

_
    args => {
        %args_common,
    },
    result_naked => 1,
};
sub list_sqlite_tables {
    require DBI;
    require DBIx::Util::Schema;

    my %args = @_;
    my $dbh = _connect(\%args);
    [DBIx::Util::Schema::list_tables($dbh)];
}

$SPEC{list_sqlite_columns} = {
    v => 1.1,
    description => <<'_',

See also the `.schema` and `.fullschema` meta-command of the `sqlite3` CLI.

_
    args => {
        %args_common,
        %arg1_table,
    },
    result_naked => 1,
};
sub list_sqlite_columns {
    require DBI;
    require DBIx::Util::Schema;

    my %args = @_;
    my $dbh = _connect(\%args);
    [DBIx::Util::Schema::list_columns($dbh, $args{table})];
}

1;
# ABSTRACT: Utilities related to SQLite

__END__

=pod

=encoding UTF-8

=head1 NAME

App::SQLiteUtils - Utilities related to SQLite

=head1 VERSION

This document describes version 0.002 of App::SQLiteUtils (from Perl distribution App-SQLiteUtils), released on 2021-01-21.

=head1 DESCRIPTION

This distribution includes several utilities:

=over

=item * L<list-sqlite-columns>

=item * L<list-sqlite-tables>

=back

=head1 FUNCTIONS


=head2 list_sqlite_columns

Usage:

 list_sqlite_columns(%args) -> any

See also the C<.schema> and C<.fullschema> meta-command of the C<sqlite3> CLI.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_file>* => I<filename>

=item * B<table>* => I<str>


=back

Return value:  (any)



=head2 list_sqlite_tables

Usage:

 list_sqlite_tables(%args) -> any

See also the C<.tables> meta-command of the C<sqlite3> CLI.

This function is not exported.

Arguments ('*' denotes required arguments):

=over 4

=item * B<db_file>* => I<filename>


=back

Return value:  (any)

=head1 HOMEPAGE

Please visit the project's homepage at L<https://metacpan.org/release/App-SQLiteUtils>.

=head1 SOURCE

Source repository is at L<https://github.com/perlancar/perl-App-SQLiteUtils>.

=head1 BUGS

Please report any bugs or feature requests on the bugtracker website L<https://github.com/perlancar/perl-App-SQLiteUtils/issues>

When submitting a bug or request, please include a test-file or a
patch to an existing test-file that illustrates the bug or desired
feature.

=head1 SEE ALSO

L<App::DBIUtils>

=head1 AUTHOR

perlancar <perlancar@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2021 by perlancar@cpan.org.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
