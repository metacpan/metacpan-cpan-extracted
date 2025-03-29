package DBIx::QuickDB::Driver::MySQL;
use strict;
use warnings;

our $VERSION = '0.000038';

use Capture::Tiny qw/capture/;
use Carp qw/confess croak/;
use DBIx::QuickDB::Util qw/strip_hash_defaults/;
use IPC::Cmd qw/can_run/;
use Scalar::Util qw/reftype blessed/;

use parent 'DBIx::QuickDB::Driver';
use DBIx::QuickDB::Util::HashBase qw{
    <data_dir <temp_dir <socket <pid_file <cfg_file

    +dbd_driver
    <mysqld_provider
    <use_bootstrap
    <use_installdb

    <character_set_server

    <config
};

sub provider        { croak "'$_[0]' does not implement provider" }
sub verify_provider { croak "'$_[0]' does not implement verify_provider" }

sub dbd_driver_order { shift; grep { $_ } @_, 'DBD::MariaDB', 'DBD::mysql' }

sub server_bin_list  { qw/mysqld/ }
sub client_bin_list  { qw/mysql/ }
sub install_bin_list { qw/mysql_install_db/ }
sub server_bin       { $_[0]->provider_info->{server_bin}  }
sub client_bin       { $_[0]->provider_info->{client_bin}  }
sub install_bin      { $_[0]->provider_info->{install_bin} }

my %PROVIDER_CACHE;
sub provider_info {
    my $this = shift;

    my $class = blessed($this) || $this;
    return $PROVIDER_CACHE{$class} if $PROVIDER_CACHE{$class};

    my %found;

    my $viable = 0;
    for my $bin ($this->server_bin_list) {
        if (my $mysqld = can_run($bin)) {
            $found{server_bin} = $mysqld if $this->verify_provider($mysqld);
        }
    }

    return $PROVIDER_CACHE{$class} = {} unless $found{server_bin};

    for my $bin ($this->client_bin_list) {
        if (my $mysql = can_run('mysql')) {
            $found{client_bin} = $mysql if $this->verify_provider($mysql);
        }
    }

    return $PROVIDER_CACHE{$class} = {} unless $found{client_bin};

    if (my $install = can_run('mysql_install_db')) {
        my ($stdout, $stderr) = capture { system($install) };
        my $output = $stdout . "\n" .  $stderr;
        unless ($output =~ m/is deprecated/) {
            $found{install_bin} = $install if $this->verify_provider($install);
        }
    }

    return $PROVIDER_CACHE{$class} = \%found;
}

sub choose {
    my $this = shift;

    my $spec = { bootstrap => 1, load_sql => 1 };

    require DBIx::QuickDB::Driver::MariaDB;
    my ($ok, $why) = DBIx::QuickDB::Driver::MariaDB->viable($spec);
    return 'DBIx::QuickDB::Driver::MariaDB' if $ok;

    require DBIx::QuickDB::Driver::MySQLCom;
    ($ok, $why) = DBIx::QuickDB::Driver::MySQLCom->viable($spec);
    return 'DBIx::QuickDB::Driver::MySQLCom' if $ok;

    require DBIx::QuickDB::Driver::Percona;
    ($ok, $why) = DBIx::QuickDB::Driver::Percona->viable($spec);
    return 'DBIx::QuickDB::Driver::Percona' if $ok;

    return undef;
}

sub viable {
    my $this = shift;
    my ($spec) = @_;

    require DBIx::QuickDB::Driver::MariaDB;
    require DBIx::QuickDB::Driver::MySQLCom;
    require DBIx::QuickDB::Driver::Percona;

    my ($ok1, $why1) = DBIx::QuickDB::Driver::MariaDB->viable($spec);
    my ($ok2, $why2) = DBIx::QuickDB::Driver::MySQLCom->viable($spec);
    my ($ok3, $why3) = DBIx::QuickDB::Driver::Percona->viable($spec);

    return (1, undef) if $ok1 || $ok2 || $ok3;

    return (0, join("\n" => $why1, $why2, $why3));
}

sub new {
    my $class = shift;

    if ($class eq __PACKAGE__) {
        my $real_class = $class->choose or croak("Neither MariaDB, MySQL (Oracle/Community), or Percona are viable");
        return $real_class->new(@_);
    }

    my $self = @_ == 1 ? $_[0] : {@_};
    bless($self, $class);
    $self->init();

    return $self;
}

sub version_string {
    my ($class_or_self, @other) = @_;

    my $binary;

    # Go in reverse order assuming the last param hash provided is most important
    for my $arg (reverse @_) {
        my $type = reftype($arg) or next;    # skip if not a ref
        next unless $type eq 'HASH';         # We have a hashref, possibly blessed

        # If we find a launcher we are done looping, we want to use this binary.
        if (blessed($arg) && $arg->can('server_bin')) {
            $binary = $arg->server_bin and last;
        }

        for my $l (qw/server_bin mysqld mariadbd/) {
            $binary = $arg->{$l} and last;
        }

        last if $binary;
    }

    unless ($binary) {
        if ($class_or_self eq __PACKAGE__) {
            if (my $sel = $class_or_self->choose) {
                $binary = $sel->server_bin;
            }
        }
        else {
            $binary = $class_or_self->server_bin;
        }
    }

    croak "Could not find a viable server binary" unless $binary;

    # Call the binary with '-V', capturing and returning the output using backticks.
    my ($v) = capture { system($binary, '-V') };

    return $v;
}

sub dbd_driver {
    my $in = shift;

    return $in->{+DBD_DRIVER} if blessed($in) && $in->{+DBD_DRIVER};

    for my $driver ($in->dbd_driver_order) {
        my $file = $driver;
        $file =~ s{::}{/}g;
        $file .= ".pm";
        eval { require($file); 1 } or next;

        return $in->{+DBD_DRIVER} = $driver if blessed($in);
        return $driver;
    }

    return undef;
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
    my $class = shift;

    return (
        server => $class->server_bin,
        client => $class->client_bin,
    );
}

sub _default_config {
    my $self = shift;

    my $dir = $self->dir;
    my $data_dir = $self->data_dir;
    my $temp_dir = $self->temp_dir;
    my $pid_file = $self->pid_file;
    my $socket   = $self->socket;

    return (
        client => {
            'socket' => $socket,
        },

        mysql_safe => {
            'socket' => $socket,
        },

        mysql => {
            'socket'         => $socket,
        },

        mysqld => {
            'datadir'  => $data_dir,
            'pid-file' => $pid_file,
            'socket'   => $socket,
            'tmpdir'   => $temp_dir,

            'secure_file_priv'               => $dir,
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

            'character_set_server' => $self->{+CHARACTER_SET_SERVER},

            defined($ENV{QDB_MYSQL_SSL_FIPS}) ? ('ssl_fips_mode' => "$ENV{QDB_MYSQL_SSL_FIPS}") : (),
        },
    );
}

sub init {
    my $self = shift;
    $self->SUPER::init();

    $self->dbd_driver; # Vivify this

    $self->{+CHARACTER_SET_SERVER} //= 'UTF8MB4';

    $self->{+DATA_DIR} = $self->{+DIR} . '/data';
    $self->{+TEMP_DIR} = $self->{+DIR} . '/temp';
    $self->{+CFG_FILE} = $self->{+DIR} . '/my.cfg';
    $self->{+PID_FILE} = $self->{+DIR} . '/mysql.pid';
    $self->{+SOCKET} ||= $self->{+DIR} . '/mysql.sock';

    $self->{+USERNAME} ||= 'root';

    my %defaults = $self->_default_paths;
    $self->{$_} ||= $defaults{$_} for keys %defaults;

    my %cfg_defs = $self->_default_config;
    my $cfg = { %{$self->{+CONFIG} || {}} };
    $self->{+CONFIG} = $cfg;

    for my $key (keys %cfg_defs) {
        if (defined $cfg->{$key}) {
            my $subdft = $cfg_defs{$key};
            my $subcfg = { %{$cfg->{$key}} };
            $cfg->{$key} = $subcfg;

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
        {$self->_default_config},
    );

    return (
        $self->SUPER::clone_data(),

        CONFIG()     => $config,
        DBD_DRIVER() => $self->{+DBD_DRIVER},
    );
}

sub write_config {
    my $self = shift;
    my (%params) = @_;

    my $cfg_file = $self->{+CFG_FILE};
    open(my $cfh, '>', $cfg_file) or die "Could not open config file: $!";
    my $conf = $self->{+CONFIG};
    for my $section (sort keys %$conf) {
        my $override = $params{$section} // {};

        my $sconf = $conf->{$section} or next;

        $sconf = { %$sconf, %{$override->{add}} } if $override->{add};

        print $cfh "[$section]\n";
        for my $key (sort keys %$sconf) {
            my $val = $sconf->{$key};
            next unless defined $val;

            next if $override->{skip} && ($key =~ $override->{skip} || $val =~ $override->{skip});

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

    return $init_file;
}

sub load_sql {
    my $self = shift;
    my ($db_name, $file) = @_;

    my $cfg_file = $self->{+CFG_FILE};

    $self->run_command(
        [
            $self->client_bin,
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
    return ($self->client_bin, "--defaults-file=$cfg_file", $db_name);
}

sub start_command {
    my $self = shift;

    my $cfg_file = $self->{+CFG_FILE};
    return ($self->server_bin, "--defaults-file=$cfg_file", '--skip-grant-tables');
}

sub connect_string {
    my $self = shift;
    my ($db_name) = @_;
    $db_name = 'quickdb' unless defined $db_name;

    my $socket = $self->{+SOCKET};

    if ($self->dbd_driver eq 'DBD::MariaDB') {
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

DBIx::QuickDB::Driver::MySQL - Get ANY MySQL driver for DBIx::QuickDB.

=head1 DESCRIPTION

ANY MySQL driver for L<DBIx::QuickDB>.

This will automatically pick L<DBIx::QuickDB::Driver::MariaDB>,
L<DBIx::QuickDB::Driver::MySQLCom>, or L<DBIx::QuickDB::Driver::Percona>
depending on which provider your MySQL was built by.

This also serves as the base class for all 3 of the above drivers.

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
