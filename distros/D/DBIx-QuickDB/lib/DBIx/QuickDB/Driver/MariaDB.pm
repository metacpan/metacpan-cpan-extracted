package DBIx::QuickDB::Driver::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000052';

use IPC::Cmd qw/can_run/;
use Capture::Tiny qw/capture/;

use parent 'DBIx::QuickDB::Driver::MySQL';
use DBIx::QuickDB::Util::HashBase;

sub provider { 'MariaDB' }

sub verify_provider {
    my $class = shift;
    my ($bin, $provider) = @_;

    $provider //= $class->provider;

    my ($v, $stderr) = capture { system($bin, '-V') };
    return 1 if $v =~ m/$provider/i;
    return 0;
}

sub server_bin_list  { qw/mariadbd mysqld/ }
sub client_bin_list  { qw/mariadb mysql/ }
sub install_bin_list { qw/mariadb-install-db mysql_install_db/ }

sub dbd_driver_order { my $class = shift; $class->SUPER::dbd_driver_order($ENV{QDB_MARIADB_DBD}, $ENV{QDB_MYSQLD_DBD}) }

sub list_env_vars {
    my $self = shift;

    my @list = $self->SUPER::list_env_vars();

    return (
        @list,
        map { my $x = "$_"; $x =~ s/MYSQL/MARIADB/g; $x } @list,
    );
}

sub _default_config {
    my $self = shift;

    my %config = $self->SUPER::_default_config(@_);

    if (defined($ENV{QDB_MARIADB_SSL_FIPS})) {
        $config{mysqld}->{'ssl_fips_mode'} = "$ENV{QDB_MARIADB_SSL_FIPS}";
    }

    $config{mysqld}->{'query_cache_limit'} = '1M';
    $config{mysqld}->{'query_cache_size'}  = '20M';

    $config{mariadbd}     = $config{mysqld};
    $config{mariadb}      = $config{mysql};
    $config{mariadb_safe} = $config{mysql_safe};

    return %config;
}

# Releases where an information_schema 'table_constraints' or
# 'referential_constraints' scan that reaches information_schema's own tables
# locks a never-initialized ACL mutex under --skip-grant-tables and blocks
# forever: immune to KILL, and it prevents graceful server shutdown. QuickDB
# always starts the server with --skip-grant-tables, so these releases are not
# safe to use. Broken by upstream MDEV-38209, fixed by MDEV-38811.
my %BROKEN_IS_ACL_VERSIONS = (
    '10.11.16' => 'fixed in 10.11.17',
    '11.4.10'  => 'fixed in 11.4.11',
    '11.8.6'   => 'fixed in 11.8.7',
    '12.2.2'   => 'never fixed, 12.2.2 is the final 12.2 release; use another series',
    '12.3.1'   => 'fixed in 12.3.2',
);

sub broken_version_check {
    my $this = shift;
    my ($bin) = @_;

    return undef if $ENV{QDB_MARIADB_IGNORE_BROKEN};
    return undef unless $bin && -x $bin;

    my ($out) = capture { system($bin, '-V') };
    return undef unless $out && $out =~ m/\bVer\s+(\d+\.\d+\.\d+)-MariaDB\b/;

    my $version = $1;
    my $fix = $BROKEN_IS_ACL_VERSIONS{$version} or return undef;

    return "MariaDB $version hangs unkillably on information_schema"
        . " 'table_constraints' and 'referential_constraints' scans under"
        . " --skip-grant-tables, which DBIx::QuickDB always uses (upstream bug"
        . " MDEV-38811; $fix). Set QDB_MARIADB_IGNORE_BROKEN=1 to use this"
        . " server anyway.";
}

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;

    push @bad => "Could not load either 'DBD::MariaDB' or 'DBD::mysql', needed for everything"
        unless $this->dbd_driver;

    if (!keys %{$this->provider_info}) {
        push @bad => "Installed MySQL is not " . $this->provider;
    }
    else {
        if ($spec->{bootstrap}) {
            push @bad => "'mysqld' and 'mariadbd' commands are missing, needed for bootstrap" unless $check{server} && -x $check{server};
        }
        elsif ($spec->{autostart}) {
            push @bad => "'mysqld' and 'mariadbd' commands are missing, needed for autostart" unless $check{server} && -x $check{server};
        }

        if ($spec->{load_sql}) {
            push @bad => "'mysql' and 'mariadb' commands are missing, needed for load_sql" unless $check{client} && -x $check{client};
        }

        if (($spec->{bootstrap} || $spec->{autostart}) && $check{server} && -x $check{server}) {
            if (my $broken = $this->broken_version_check($check{server})) {
                push @bad => $broken;
            }
        }
    }

    return (1, undef) unless @bad;
    return (0, join "\n" => @bad);
}

sub bootstrap {
    my $self = shift;

    my $init_file = $self->SUPER::bootstrap(@_);

    # Bootstrap is much faster without InnoDB, we will turn InnoDB back on later, and things will use it.
    $self->write_config(
        mariadbd => {
            skip => qr/innodb/i,
            add => {'default-storage-engine' => 'MyISAM'}
        },
        mysqld => {
            skip => qr/innodb/i,
            add => {'default-storage-engine' => 'MyISAM'}
        }
    );
    $self->run_command([$self->start_command, '--bootstrap'], {stdin => $init_file});

    # Turn InnoDB back on
    $self->write_config();

    return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::MariaDB - MariaDB MySQL driver for DBIx::QuickDB.

=head1 DESCRIPTION

MariaDB MySQL driver for L<DBIx::QuickDB>.

=head1 SYNOPSIS

See L<DBIx::QuickDB>.

=head1 MYSQL SPECIFIC OPTIONS

=over 4

=item dbd_driver => $DRIVER

Should be either L<DBD::mysql> or L<DBD::MariaDB>. If not specified then
DBD::MariaDB is preferred with a fallback to DBD::MySQL.

=back

=head1 KNOWN BROKEN SERVER VERSIONS

The following MariaDB releases are refused by C<viable()> (so driver selection
skips them and C<get_db>/C<build_db> will not silently use them):

=over 4

=item * 10.11.16 (fixed in 10.11.17)

=item * 11.4.10 (fixed in 11.4.11)

=item * 11.8.6 (fixed in 11.8.7)

=item * 12.2.2 (never fixed; 12.2.2 is the final 12.2 release)

=item * 12.3.1 (fixed in 12.3.2)

=back

On these releases any C<information_schema.table_constraints> or
C<information_schema.referential_constraints> query whose scan reaches
information_schema's own tables (for example a scan without an effective
C<WHERE table_schema = DATABASE()> filter, or a join whose plan defeats that
filter's pushdown) locks an ACL mutex that is never initialized when the
server runs with C<--skip-grant-tables> - which DBIx::QuickDB always uses.
The query thread then blocks forever: it burns no CPU, C<KILL QUERY> and
C<KILL CONNECTION> cannot terminate it, and a graceful server shutdown waits
on it forever (the QuickDB watcher's SIGKILL escalation still reclaims the
server at teardown). The client is stuck in a C-level read inside libmariadb,
so Perl-level C<alarm()> or C<%SIG> handlers in the calling process never
fire; only C<SIGKILL> (or killing the server) frees it.

This is upstream bug MDEV-38811 (introduced by MDEV-38209). If you accept the
risk - for example your code never queries those two information_schema
tables - you can set the C<QDB_MARIADB_IGNORE_BROKEN> environment variable to
use such a server anyway.

=head1 ENVIRONMENT VARIABLES

=head2 QDB_MARIADB_IGNORE_BROKEN

Set to a true value to let C<viable()> accept MariaDB releases listed under
L</"KNOWN BROKEN SERVER VERSIONS"> anyway.

=head2 QDB_MYSQL_SSL_FIPS

Set to 1 to enable, 0 to disable or enter any string accepted by the
C<ssl_fips_mode> mysqld config option. If this environment variable is not
defined then the C<ssl_fips_mode> option will not be included in the generated
config file at all by default.

This is mainly used to allow this dists test suite to pass on systems where
FIPS is required and enforced.

=head1 SOURCE

The source code repository for DBIx-QuickDB can be found at
F<https://github.com/exodist/DBIx-QuickDB/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright 2020 Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See F<http://dev.perl.org/licenses/>

=cut
