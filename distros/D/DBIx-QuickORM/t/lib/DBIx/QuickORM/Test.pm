package DBIx::QuickORM::Test;
use strict;
use warnings;

use Config qw/%Config/;
use Test2::IPC qw/cull/;
use Test2::Tools::Basic qw/fail skip_all/;
use Test2::Tools::Mock qw/mock/;
use Test2::Tools::Subtest qw/subtest_buffered/;

use Exporter qw/import/;
our @EXPORT    = qw/do_for_all_dbs/;
our @EXPORT_OK = qw/db_sets on_execute/;

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Test - Run a test block against every available database.

=head1 DESCRIPTION

Runs a block once per database set, each set in its own child process and
its own buffered subtest. The sets are SQLite and DuckDB (database files in a
temporary directory), the PostgreSQL, MariaDB, MySQL, and Percona servers
found on C<$PATH>, and every install under
F<~/dbs/E<lt>engineE<gt>-E<lt>versionE<gt>/bin> for the engines
C<postgresql>, C<mariadb>, C<mysql>, and C<percona>. A set that cannot run
here is skipped.

Every database comes from L<Test2::Tools::QuickDB>, loaded only in the child
after the install's F<bin> is put first in C<$PATH>, because QuickDB finds
its server programs when it loads. Test files must not load L<DBIx::QuickDB>
themselves. MySQL-family sets connect through L<DBD::MariaDB>.

=head1 SYNOPSIS

    use Test2::V0;
    use lib 't/lib';
    use DBIx::QuickORM::Test;

    do_for_all_dbs {
        my ($db, $set) = @_;
        my $dbh = $db->connect;
        ok($dbh->do('SELECT 1'), "works on $set->{name}");
    };

    done_testing;

=head1 EXPORTS

=over 4

=item do_for_all_dbs { my ($db, $set) = @_; ... }

Runs the block for every set from C<db_sets>, at most
C<QORM_TEST_CONCURRENCY> (default 4) at a time, and returns when all are
done. C<$db> is a started L<DBIx::QuickDB> driver instance. A child that
exits abnormally is a failure. Skips the whole test where C<fork> is only
emulated.

=cut

sub do_for_all_dbs(&) {
    my ($code) = @_;

    skip_all "database sets each need a real child process" if $Config{d_pseudofork};

    my $max = $ENV{QORM_TEST_CONCURRENCY} || 4;
    my %running;
    for my $set (db_sets()) {
        _reap(\%running, $max - 1);
        my $pid = fork // die "Could not fork: $!";
        _run_set($code, $set) unless $pid;
        $running{$pid} = $set->{name};
    }
    _reap(\%running, 0);

    return;
}

=pod

=item @sets = db_sets()

Every set, as hashrefs with C<name>, C<driver> (the QuickDB driver),
C<family> (C<PostgreSQL>, C<MariaDB>, C<MySQL>, C<SQLite>, or C<DuckDB>), and
C<bin> (undef for the C<$PATH> sets). C<QORM_TEST_SETS>, a comma-separated
list of names or families, narrows them.

=cut

my %FAMILY = (
    SQLite     => 'SQLite',
    DuckDB     => 'DuckDB',
    PostgreSQL => 'PostgreSQL',
    MariaDB    => 'MariaDB',
    MySQLCom   => 'MySQL',
    Percona    => 'MySQL',
);

my %ENGINE = (postgresql => 'PostgreSQL', mariadb => 'MariaDB', mysql => 'MySQLCom', percona => 'Percona');

sub db_sets {
    my @sets = map { {name => lc($_), driver => $_, family => $FAMILY{$_}, bin => undef} } qw/SQLite DuckDB PostgreSQL MariaDB MySQLCom Percona/;

    for my $bin (glob("$ENV{HOME}/dbs/*/bin")) {
        my ($name, $engine) = $bin =~ m{/(([a-z]+)-[\d.]+)/bin$} or next;
        my $driver = $ENGINE{$engine} or next;
        push @sets => {name => $name, driver => $driver, family => $FAMILY{$driver}, bin => $bin};
    }

    my %want = map { lc($_) => 1 } split m/\s*,\s*/, $ENV{QORM_TEST_SETS} // '';
    return @sets unless %want;
    return grep { $want{lc $_->{name}} || $want{lc $_->{family}} } @sets;
}

=pod

=item $guard = on_execute { my ($sql) = @_; ... }

Calls the block with the SQL of every statement just before it executes,
prepared or cached, until C<$guard> is freed.

=back

=cut

sub on_execute(&) {
    my ($code) = @_;
    return mock 'DBI::st' => (
        around => [
            execute => sub {
                my $orig = shift;
                $code->($_[0]->{Statement});
                return $orig->(@_);
            },
        ],
    );
}

sub _reap {
    my ($running, $limit) = @_;

    while (keys %$running > $limit) {
        my $pid = waitpid(-1, 0);
        if ($pid < 0) {
            fail("$_: database child was lost") for values %$running;
            %$running = ();
            last;
        }
        my $name = delete $running->{$pid} // next;
        fail("$name: database child exited with wait status $?") if $?;
    }

    cull();
}

sub _run_set {
    my ($code, $set) = @_;

    # Children inherit the parent's random seed, and temporary names would collide.
    srand();
    $ENV{PATH} = "$set->{bin}:$ENV{PATH}" if $set->{bin};

    my %spec = (driver => $set->{driver}, fast_destroy => 1);
    $spec{dbd_driver} = 'DBD::MariaDB' if $set->{family} =~ m/^(?:MariaDB|MySQL)$/;

    my $ok = eval {
        require Test2::Tools::QuickDB;
        subtest_buffered $set->{name} => sub {
            my $db = Test2::Tools::QuickDB::get_db_or_skipall(\%spec);
            $code->($db, {%$set});
        };
        1;
    };
    warn $@ unless $ok;
    exit($ok ? 0 : 255);
}

1;

__END__

=head1 ENVIRONMENT

=over 4

=item QORM_TEST_SETS

Comma-separated set names or families to run, such as
C<sqlite,postgresql-17> or C<MySQL>. Unset runs every set.

=item QORM_TEST_CONCURRENCY

The most database children one test file runs at once. Defaults to 4.

=back

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
