package DBIx::QuickDB::Driver::MySQL;
use strict;
use warnings;

our $VERSION = '0.000015';

use IPC::Cmd qw/can_run/;
use DBIx::QuickDB::Util qw/strip_hash_defaults/;
use Scalar::Util qw/reftype/;
use Carp qw/confess/;

use parent 'DBIx::QuickDB::Driver';

use DBIx::QuickDB::Util::HashBase qw{
    -data_dir -temp_dir -socket -pid_file -cfg_file

    -mysqld -mysql

    -dbd_driver
    -mysqld_provider

    -config
};

my ($MYSQLD, $MYSQL, $DBDMYSQL, $DBDMARIA);

BEGIN {
    local $@;

    $MYSQLD = can_run('mysqld');
    $MYSQL  = can_run('mysql');

    $DBDMYSQL = eval { require DBD::mysql;   'DBD::mysql' };
    $DBDMARIA = eval { require DBD::MariaDB; 'DBD::MariaDB' };
}

sub version_string {
    my $binary;

    # Go in reverse order assuming the last param hash provided is most important
    for my $arg (reverse @_) {
        my $type = reftype($arg) or next;    # skip if not a ref
        next unless $type eq 'HASH';         # We have a hashref, possibly blessed

        # If we find a launcher we are done looping, we want to use this binary.
        $binary = $arg->{+MYSQLD} and last;
    }

    # If no args provided one to use we fallback to the default from $PATH
    $binary ||= $MYSQLD;

    # Call the binary with '-V', capturing and returning the output using backticks.
    return `$binary -V`;
}

sub list_env_vars {
    my $self = shift;
    return (
        $self->SUPER::list_env_vars(),
        qw{
            LIBMYSQL_ENABLE_CLEARTEXT_PLUGIN LIBMYSQL_PLUGINS
            LIBMYSQL_PLUGIN_DIR MYSQLX_TCP_PORT MYSQLX_UNIX_PORT MYSQL_DEBUG
            MYSQL_GROUP_SUFFIX MYSQL_HISTFILE MYSQL_HISTIGNORE MYSQL_HOME
            MYSQL_HOST MYSQL_OPENSSL_UDF_DH_BITS_THRESHOLD
            MYSQL_OPENSSL_UDF_DSA_BITS_THRESHOLD
            MYSQL_OPENSSL_UDF_RSA_BITS_THRESHOLD MYSQL_PS1 MYSQL_PWD
            MYSQL_SERVER_PREPARE MYSQL_TCP_PORT MYSQL_TEST_LOGIN_FILE
            MYSQL_TEST_TRACE_CRASH MYSQL_TEST_TRACE_DEBUG MYSQL_UNIX_PORT
        }
    );
}

sub _default_paths {
    return (
        mysqld => $MYSQLD,
        mysql  => $MYSQL,
    );
}

sub _default_config {
    my $self = shift;

    my $dir = $self->dir;
    my $data_dir = $self->data_dir;
    my $temp_dir = $self->temp_dir;
    my $pid_file = $self->pid_file;
    my $socket   = $self->socket;

    my $provider = $self->{+MYSQLD_PROVIDER};

    return (
        client => {
            'socket' => $socket,
        },

        mysql_safe => {
            'socket' => $socket,
        },

        mysqld => {
            'datadir'  => $data_dir,
            'pid-file' => $pid_file,
            'socket'   => $socket,
            'tmpdir'   => $temp_dir,

            'default_storage_engine'         => 'InnoDB',
            'innodb_buffer_pool_size'        => '20M',
            'key_buffer_size'                => '20M',
            'max_connections'                => '100',
            'server-id'                      => '1',
            'skip_grant_tables'              => '1',
            'skip_external_locking'          => '',
            'skip_networking'                => '1',
            'skip_name_resolve'              => '1',
            'max_allowed_packet'             => '1M',
            'max_binlog_size'                => '20M',
            'myisam_sort_buffer_size'        => '8M',
            'net_buffer_length'              => '8K',
            'read_buffer_size'               => '256K',
            'read_rnd_buffer_size'           => '512K',
            'sort_buffer_size'               => '512K',
            'table_open_cache'               => '64',
            'thread_cache_size'              => '8',
            'thread_stack'                   => '192K',
            'innodb_io_capacity'             => '2000',
            'innodb_max_dirty_pages_pct'     => '0',
            'innodb_max_dirty_pages_pct_lwm' => '0',

            $provider eq 'percona'
            ? (
                'character_set_server' => 'UTF8MB4',
              )
            : (
                'character_set_server' => 'UTF8MB4',
                'query_cache_limit'    => '1M',
                'query_cache_size'     => '20M',
            ),
        },

        mysql => {
            'socket'         => $socket,
            'no-auto-rehash' => '',
        },
    );
}

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;

    push @bad => "Could not load either 'DBD::mysql' or 'DBD::MariaDB', needed for everything"
        unless $DBDMYSQL || $DBDMARIA;

    if ($spec->{bootstrap}) {
        push @bad => "'mysqld' command is missing, needed for bootstrap" unless $check{mysqld} && -x $check{mysqld};
    }
    elsif ($spec->{autostart}) {
        push @bad => "'mysqld' command is missing, needed for autostart" unless $check{mysqld} && -x $check{mysqld};
    }

    if ($spec->{load_sql}) {
        push @bad => "'mysql' command is missing, needed for load_sql" unless $check{mysql} && -x $check{mysql};
    }

    return (1, undef) unless @bad;
    return (0, join "\n" => @bad);
}

sub init {
    my $self = shift;
    $self->SUPER::init();

    # Percona is the more restrictive, so fallback to mariadb behavior for
    # now. Add patches for more variants if needed.
    unless ($self->{+MYSQLD_PROVIDER}) {
        if ($self->version_string =~ m/(mariadb|percona)/i) {
            $self->{+MYSQLD_PROVIDER} = lc($1);
        }
        else {
            my $binary = $self->{+MYSQLD} || $MYSQLD;
            my $help = `$binary --help --verbose`;

            if ($help =~ m/(mariadb|percona)/i) {
                $self->{+MYSQLD_PROVIDER} = lc($1);
            }
            elsif ($help =~ m/--bootstrap/) {
                $self->{+MYSQLD_PROVIDER} = 'mariadb';
            }
            elsif ($help =~ m/--initialize/) {
                $self->{+MYSQLD_PROVIDER} = 'percona';
            }
        }
    }

    confess "Could not determine mysqld provider (" . ($self->{+MYSQLD} || $MYSQLD)  . ") please specify mysqld_prover => mariadb|percona"
        unless $self->{+MYSQLD_PROVIDER};

    $self->{+DBD_DRIVER} //= $DBDMARIA || $DBDMYSQL;

    $self->{+DATA_DIR} = $self->{+DIR} . '/data';
    $self->{+TEMP_DIR} = $self->{+DIR} . '/temp';
    $self->{+PID_FILE} = $self->{+DIR} . '/mysql.pid';
    $self->{+CFG_FILE} = $self->{+DIR} . '/my.cfg';

    $self->{+SOCKET} ||= $self->{+DIR} . '/mysql.sock';

    $self->{+USERNAME} ||= 'root';

    my %defaults = $self->_default_paths;
    $self->{$_} ||= $defaults{$_} for keys %defaults;

    my %cfg_defs = $self->_default_config;
    my $cfg = $self->{+CONFIG} ||= {};

    for my $key (keys %cfg_defs) {
        if (defined $cfg->{$key}) {
            my $subdft = $cfg_defs{$key};
            my $subcfg = $cfg->{$key};

            for my $skey (%$subdft) {
                next if defined $subcfg->{$skey};
                $subcfg->{$skey} = $subdft->{$skey};
            }
        }
        else {
            $cfg->{$key} = $cfg_defs{$key};
        }
    }
}

sub clone_data {
    my $self = shift;

    my $config = strip_hash_defaults(
        $self->{+CONFIG},
        { $self->_default_config },
    );

    return (
        $self->SUPER::clone_data(),

        CONFIG()          => $config,
        MYSQLD()          => $self->{+MYSQLD},
        MYSQL()           => $self->{+MYSQL},
        DBD_DRIVER()      => $self->{+DBD_DRIVER},
        MYSQLD_PROVIDER() => $self->{+MYSQLD_PROVIDER},
    );
}

sub write_config {
    my $self = shift;
    my (%params) = @_;

    my $cfg_file = $self->{+CFG_FILE};
    open(my $cfh, '>', $cfg_file) or die "Could not open config file: $!";
    my $conf = $self->{+CONFIG};
    for my $section (sort keys %$conf) {
        my $sconf = $conf->{$section} or next;

        $sconf = { %$sconf, %{$params{add}} } if $params{add};

        print $cfh "[$section]\n";
        for my $key (sort keys %$sconf) {
            my $val = $sconf->{$key};
            next unless defined $val;

            next if $params{skip} && ($key =~ $params{skip} || $val =~ $params{skip});

            if (length($val)) {
                print $cfh "$key = $val\n";
            }
            else {
                print $cfh "$key\n";
            }
        }

        print $cfh "\n";
    }
    close($cfh);

    return;
}

sub bootstrap {
    my $self = shift;

    my $data_dir = $self->{+DATA_DIR};
    my $temp_dir = $self->{+TEMP_DIR};

    mkdir($data_dir) or die "Could not create data dir: $!";
    mkdir($temp_dir) or die "Could not create temp dir: $!";


    my $init_file = "$self->{+DIR}/init.sql";
    open(my $init, '>', $init_file) or die "Could not open init file: $!";
    print $init "CREATE DATABASE quickdb;\n";
    close($init);

    my $provider = $self->{+MYSQLD_PROVIDER};

    if ($provider eq 'percona') {
        $self->write_config();
        $self->run_command([$self->start_command, '--initialize']);

        $self->start;
        $self->load_sql("", $init_file);
    }
    else {
        # Bootstrap is much faster without InnoDB, we will turn InnoDB back on later, and things will use it.
        $self->write_config(skip => qr/innodb/i, add => {'default-storage-engine' => 'MyISAM'});
        $self->run_command([$self->start_command, '--bootstrap', '--innodb=off'], {stdin => $init_file});

        # Turn InnoDB back on
        $self->write_config();
    }

    return;
}

sub load_sql {
    my $self = shift;
    my ($db_name, $file) = @_;

    my $cfg_file = $self->{+CFG_FILE};

    $self->run_command(
        [
            $self->{+MYSQL},
            "--defaults-file=$cfg_file",
            '-u' => 'root',
            $db_name,
        ],
        {stdin => $file},
    );
}

sub shell_command {
    my $self = shift;
    my ($db_name) = @_;

    my $cfg_file = $self->{+CFG_FILE};
    return ($self->{+MYSQL}, "--defaults-file=$cfg_file", $db_name);
}

sub start_command {
    my $self = shift;

    my $cfg_file = $self->{+CFG_FILE};
    return ($self->{+MYSQLD}, "--defaults-file=$cfg_file", '--skip-grant-tables');
}

sub connect_string {
    my $self = shift;
    my ($db_name) = @_;
    $db_name = 'quickdb' unless defined $db_name;

    my $socket = $self->{+SOCKET};

    if ($self->{+DBD_DRIVER} eq 'DBD::MariaDB') {
        return "dbi:MariaDB:dbname=$db_name;mariadb_socket=$socket";
    }
    else {
        return "dbi:mysql:dbname=$db_name;mysql_socket=$socket";
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::MySQL - MySQL driver for DBIx::QuickDB.

=head1 DESCRIPTION

MySQL driver for L<DBIx::QuickDB>.

=head1 SYNOPSIS

See L<DBIx::QuickDB>.

=head1 MYSQL SPECIFIC OPTIONS

=over 4

=item dbd_driver => $DRIVER

Should be either L<DBD::mysql> or L<DBD::MariaDB>. If not specified then
DBD::MariaDB is preferred with a fallback to DBD::MySQL.

=item mysqld_provider => $PROVIDER

Should be either 'mariadb' or 'percona'. Will auto-detect when possible.

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
