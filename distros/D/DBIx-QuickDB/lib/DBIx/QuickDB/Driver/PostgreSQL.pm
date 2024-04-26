package DBIx::QuickDB::Driver::PostgreSQL;
use strict;
use warnings;

our $VERSION = '0.000028';

use IPC::Cmd qw/can_run/;
use DBIx::QuickDB::Util qw/strip_hash_defaults/;
use Time::HiRes qw/sleep/;
use Scalar::Util qw/reftype/;

use parent 'DBIx::QuickDB::Driver';

use DBIx::QuickDB::Util::HashBase qw{
    -data_dir

    -initdb -createdb -postgres -psql

    -config
    -socket
    -port
};

my ($INITDB, $CREATEDB, $POSTGRES, $PSQL, $DBDPG);

BEGIN {
    local $@;

    $INITDB   = can_run('initdb');
    $CREATEDB = can_run('createdb');
    $POSTGRES = can_run('postgres');
    $PSQL     = can_run('psql');
    $DBDPG    = eval { require DBD::Pg; 'DBD::Pg'};
}

sub version_string {
    my $binary;

    # Go in reverse order assuming the last param hash provided is most important
    for my $arg (reverse @_) {
        my $type = reftype($arg) or next;    # skip if not a ref
        next if $type eq 'HASH';             # We have a hashref, possibly blessed

        # If we find a launcher we are done looping, we want to use this binary.
        $binary = $arg->{+POSTGRES} and last;
    }

    # If no args provided one to use we fallback to the default from $PATH
    $binary ||= $POSTGRES;

    # Call the binary with '-V', capturing and returning the output using backticks.
    return `$binary -V`;
}

sub list_env_vars {
    my $self = shift;
    return (
        $self->SUPER::list_env_vars(),
        qw{
            PGAPPNAME PGCLIENTENCODING PGCONNECT_TIMEOUT PGDATABASE PGDATESTYLE
            PGGEQO PGGSSLIB PGHOST PGHOSTADDR PGKRBSRVNAME PGLOCALEDIR
            PGOPTIONS PGPASSFILE PGPASSWORD PGPORT PGREQUIREPEER PGREQUIRESSL
            PGSERVICE PGSERVICEFILE PGSSLCERT PGSSLCOMPRESSION PGSSLCRL
            PGSSLKEY PGSSLMODE PGSSLROOTCERT PGSYSCONFDIR PGTARGETSESSIONATTRS
            PGTZ PGUSER
        }
    );
}

sub _default_paths {
    return (
        initdb   => $INITDB,
        createdb => $CREATEDB,
        postgres => $POSTGRES,
        psql     => $PSQL,
    );
}

sub _default_config {
    my $self = shift;

    return (
        datestyle                  => "'iso, mdy'",
        default_text_search_config => "'pg_catalog.english'",
        lc_messages                => "'en_US.UTF-8'",
        lc_monetary                => "'en_US.UTF-8'",
        lc_numeric                 => "'en_US.UTF-8'",
        lc_time                    => "'en_US.UTF-8'",
        listen_addresses           => "''",
        max_connections            => "100",
        shared_buffers             => "128MB",
        unix_socket_directories    => "'$self->{+DIR}'",
        port                       => $self->{+PORT},

        #dynamic_shared_memory_type => "posix",
        #log_timezone               => "'US/Pacific'",
        #timezone                   => "'US/Pacific'",
    );
}

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;

    push @bad => "'DBD::Pg' module could not be loaded, needed for everything" unless $DBDPG;

    if ($spec->{bootstrap}) {
        push @bad => "'initdb' command is missing, needed for bootstrap"   unless $check{initdb}   && -x $check{initdb};
        push @bad => "'createdb' command is missing, needed for bootstrap" unless $check{createdb} && -x $check{createdb};
    }

    if ($spec->{autostart}) {
        push @bad => "'postgres' command is missing, needed for autostart" unless $check{postgres} && -x $check{postgres};
    }

    if ($spec->{load_sql}) {
        push @bad => "'psql' command is missing, needed for load_sql" unless $check{psql} && -x $check{psql};
    }

    return (1, undef) unless @bad;
    return (0, join "\n" => @bad);
}

sub init {
    my $self = shift;
    $self->SUPER::init();

    my $port = $self->{+PORT} ||= '5432';

    my $dir = $self->{+DIR};
    $self->{+DATA_DIR} = "$dir/data";
    $self->{+SOCKET} ||= "$dir/.s.PGSQL.$port";

    $self->{+ENV_VARS} ||= {};
    $self->{+ENV_VARS}->{PGPORT} = $port unless defined $self->{+ENV_VARS}->{PGPORT};

    my %defaults = $self->_default_paths;
    $self->{$_} ||= $defaults{$_} for keys %defaults;

    my %cfg_defs = $self->_default_config;
    my $cfg = $self->{+CONFIG} ||= {};

    for my $key (keys %cfg_defs) {
        next if defined $cfg->{$key};
        $cfg->{$key} = $cfg_defs{$key};
    }
}

sub clone_data {
    my $self = shift;

    my $vars = $self->env_vars || {};
    delete $vars->{PGPORT} if $vars->{PGPORT} && $vars->{PGPORT} eq $self->port;

    my $config = strip_hash_defaults(
        $self->{+CONFIG},
        { $self->_default_config },
    );

    return (
        $self->SUPER::clone_data(),
        ENV_VARS() => $vars,
        CONFIG()   => $config,
    );
}

sub write_config {
    my $self = shift;

    my $db_dir = $self->{+DATA_DIR};
    open(my $cf, '>', "$db_dir/postgresql.conf") or die "Could not open config file: $!";
    for my $key (sort keys %{$self->{+CONFIG}}) {
        my $val = $self->{+CONFIG}->{$key};
        next unless length($val);

        print $cf "$key = $val\n";
    }
    close($cf);
}

sub bootstrap {
    my $self = shift;

    my $dir = $self->{+DIR};
    my $db_dir = $self->{+DATA_DIR};
    mkdir($db_dir) or die "Could not create data dir: $!";
    $self->run_command([$self->{+INITDB}, '-E', 'UTF8', '-D', $db_dir]);

    $self->write_config;
    $self->start;

    for my $try (1 .. 10) {
        my ($ok, $err);
        {
            local $@;
            $ok = eval {
                $self->catch_startup(sub {
                    $self->run_command([$self->{+CREATEDB}, '-T', 'template0', '-E', 'UTF8', '-h', $dir, 'quickdb']);
                });

                1;
            };
            $err = $@;
        }

        last if $ok;

        die $@ if $try == 5;

        sleep 0.5;
    }

    $self->stop unless $self->{+AUTOSTART};

    return;
}

sub connect {
    my $self = shift;
    my ($db_name, %params) = @_;

    my $dbh;
    $self->catch_startup(sub {
        $dbh = $self->SUPER::connect($db_name, %params);
    });

    return $dbh;
}

sub connect_string {
    my $self = shift;
    my ($db_name) = @_;
    $db_name = 'quickdb' unless defined $db_name;

    my $dir = $self->{+DIR};

    require DBD::Pg;
    return "dbi:Pg:dbname=$db_name;host=$dir"
}

sub load_sql {
    my $self = shift;
    my ($dbname, $file) = @_;

    my $dir = $self->{+DIR};

    $self->catch_startup(sub {
        $self->run_command([
            $self->{+PSQL},
            '-h' => $dir,
            '-v' => 'ON_ERROR_STOP=1',
            '-f' => $file,
            $dbname,
        ]);
    });
}

sub shell_command {
    my $self = shift;
    my ($db_name) = @_;

    return ($self->{+PSQL}, '-h' => $self->{+DIR}, $db_name);
}

sub start_command {
    my $self = shift;
    return ($self->{+POSTGRES}, '-D' => $self->{+DATA_DIR}, '-p' => $self->{+PORT});
}

sub catch_startup {
    my $self = shift;
    my ($code) = @_;

    my $start = time;
    while (1) {
        my $waited = time - $start;
        die "Timeout waiting for server" if $waited > 10;

        my ($ok, $err, $out);
        {
            local $@;
            $ok = eval {
                $out = $code->($self);
                1;
            };

            $err = $@;
        }

        return $out if $ok;

        die $err unless $err =~ m/the database system is starting up/;

        sleep 0.01;
    }
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::PostgreSQL - PostgreSQL driver for DBIx::QuickDB.

=head1 DESCRIPTION

PostgreSQL driver for L<DBIx::QuickDB>.

=head1 SYNOPSIS

See L<DBIx::QuickDB>.

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
