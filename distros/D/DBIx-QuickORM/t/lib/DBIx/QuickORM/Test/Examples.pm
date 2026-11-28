package DBIx::QuickORM::Test::Examples;
use strict;
use warnings;

use Test2::Tools::Basic qw/skip_all/;

use DBIx::QuickORM::Test qw/do_for_all_dbs db_sets on_execute/;

use Exporter qw/import/;
our @EXPORT = qw/do_for_pg on_execute $SCHEMA/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test::Examples - The schema and databases the documentation examples run on.

=head1 DESCRIPTION

The tests under F<t/acceptance/examples/> and F<t/acceptance/Manual/> copy
the code examples from the documentation and run them. The examples use
PostgreSQL and the schema the Quickstart shows, which lives here once.

=head1 SYNOPSIS

    use Test2::V0;
    use lib 't/lib';
    use DBIx::QuickORM::Test::Examples;

    do_for_pg {
        my ($db) = @_;
        $db->connect->do($SCHEMA);
        ...
    };

    done_testing;

=head1 EXPORTS

=over 4

=item $SCHEMA

The Quickstart's schema, as SQL for PostgreSQL.

=cut

our $SCHEMA = <<'SQL';
CREATE TABLE users (
    id          SERIAL PRIMARY KEY,
    name        TEXT NOT NULL,
    email       TEXT UNIQUE,
    prefs       JSON,
    referred_by INTEGER REFERENCES users (id),
    created     TIMESTAMP NOT NULL DEFAULT now()
);

CREATE TABLE posts (
    id      SERIAL PRIMARY KEY,
    user_id INTEGER NOT NULL REFERENCES users (id),
    title   TEXT NOT NULL,
    views   INTEGER NOT NULL DEFAULT 0
);
SQL

=pod

=item do_for_pg { my ($db, $set) = @_; ... }

C<do_for_all_dbs> from L<DBIx::QuickORM::Test>, on the PostgreSQL sets only.
Skips the whole test when there are none.

=item $guard = on_execute { ... }

Re-exported from L<DBIx::QuickORM::Test>.

=back

=cut

sub do_for_pg(&) {
    my ($code) = @_;

    my @names = map { $_->{name} } grep { $_->{family} eq 'PostgreSQL' } db_sets();
    skip_all "No PostgreSQL database set to run the examples on" unless @names;

    local $ENV{QORM_TEST_SETS} = join ',' => @names;
    return &do_for_all_dbs($code);
}

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
