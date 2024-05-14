package DBIx::QuickDB::Driver::MariaDB;
use strict;
use warnings;

our $VERSION = '0.000033';

use IPC::Cmd qw/can_run/;
use Capture::Tiny qw/capture/;

use parent 'DBIx::QuickDB::Driver::MySQL::Base';
use DBIx::QuickDB::Util::HashBase;

sub provider { 'mariadb' }

sub verify_provider {
    my $class = shift;
    my ($bin, $provider) = @_;

    $provider //= $class->provider;

    my ($v) = capture { system($bin, '-V') };
    return 1 if $v =~ m/$provider/i;
    return 0;
}

my $NOT_MARIADB;
{
    my %found;

    my $viable = 0;
    if (my $mysqld = can_run('mariadbd') || can_run('mysqld')) {
        if (__PACKAGE__->verify_provider($mysqld)) {
            $found{server_bin} = $mysqld;
        }
        else {
            $NOT_MARIADB = 1;
        }
    }

    if (my $mysql = can_run('mariadb') || can_run('mysql')) {
        if (__PACKAGE__->verify_provider($mysql)) {
            $found{client_bin} = $mysql;
        }
        else {
            $NOT_MARIADB = 1;
        }
    }

    if (my $install = can_run('mariadb-install-db') || can_run('mysql_install_db')) {
        my ($stdout, $stderr) = capture { system($install) };
        my $output = $stdout . "\n" .  $stderr;
        unless ($output =~ m/is deprecated/) {
            $found{install_bin} = $install if __PACKAGE__->verify_provider($install);
        }
    }

    for my $key (qw/server_bin client_bin install_bin/) {
        my $val = $found{$key};
        no strict 'refs';
        *$key = sub() { $val };
    }
}

sub dbd_driver_order { grep { $_ } $ENV{QDB_MARIADB_DBD}, $ENV{QDB_MYSQLD_DBD}, 'DBD::MariaDB', 'DBD::mysql' }

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

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;

    push @bad => "Could not load either 'DBD::mysql' or 'DBD::MariaDB', needed for everything"
        unless $this->dbd_driver;

    if ($NOT_MARIADB) {
        push @bad => "Installed MySQL is not MariaDB";
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

=head1 ENVIRONMENT VARIABLES

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
