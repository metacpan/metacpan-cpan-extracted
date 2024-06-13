package DBIx::QuickDB::Driver::Percona;
use strict;
use warnings;

our $VERSION = '0.000034';

use IPC::Cmd qw/can_run/;
use Capture::Tiny qw/capture/;

use parent 'DBIx::QuickDB::Driver::MySQL::Base';
use DBIx::QuickDB::Util::HashBase;

sub provider { 'percona' }

sub verify_provider {
    my $class = shift;
    my ($bin, $provider) = @_;

    $provider //= $class->provider;

    my ($v1, $v2) = capture { system($bin, '--help', '--verbose') };
    my $v = $v1 . "\n" . $v2;
    return 1 if $v =~ m/$provider/i;
    return 0;
}

my $NOT_PERCONA;
{
    my %found;

    my $viable = 0;
    if (my $mysqld = can_run('mysqld')) {
        if (__PACKAGE__->verify_provider($mysqld)) {
            $found{server_bin} = $mysqld;
        }
        else {
            $NOT_PERCONA = 1;
        }
    }

    if (my $mysql = can_run('mysql')) {
        if (__PACKAGE__->verify_provider($mysql)) {
            $found{client_bin} = $mysql;
        }
        else {
            $NOT_PERCONA = 1;
        }
    }

    if (my $install = can_run('mysql_install_db')) {
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

sub dbd_driver_order { grep { $_ } $ENV{QDB_PERCONA_DBD}, $ENV{QDB_MYSQLD_DBD}, 'DBD::mysql', 'DBD::Percona' }

sub viable {
    my $this = shift;
    my ($spec) = @_;

    my %check = (ref($this) ? %$this : (), $this->_default_paths, %$spec);

    my @bad;

    push @bad => "Could not load either 'DBD::mysql' or 'DBD::Percona', needed for everything"
        unless $this->dbd_driver;

    if ($NOT_PERCONA) {
        push @bad => "Installed MySQL is not Percona";
    }
    else {
        if ($spec->{bootstrap}) {
            push @bad => "'mysqld' command is missing, needed for bootstrap" unless $check{server} && -x $check{server};
        }
        elsif ($spec->{autostart}) {
            push @bad => "'mysqld' command is missing, needed for autostart" unless $check{server} && -x $check{server};
        }

        if ($spec->{load_sql}) {
            push @bad => "'mysql' command is missing, needed for load_sql" unless $check{client} && -x $check{client};
        }
    }

    if ($check{server}) {
        my $version = $this->version_string;
        if ($version && $version =~ m/(\d+)\.(\d+)\.(\d+)/) {
            my ($a, $b, $c) = ($1, $2, $3);
            push @bad => "'mysqld' is too old ($a.$b.$c), need at least 5.6.0"
                if $a < 5 || ($a == 5 && $b < 6);
        }
    }

    return (1, undef) unless @bad;
    return (0, join "\n" => @bad);
}

sub init {
    my $self = shift;

    my $binary = $self->server_bin;
    my ($help) = capture { system($binary. '--help', '--verbose') };

    if ($help =~ m/--initialize/) {
        $self->{+USE_BOOTSTRAP} = 0;
    }
    elsif ($help =~ m/--bootstrap/) {
        $self->{+USE_BOOTSTRAP} = 1;

        $self->{+USE_INSTALLDB} = $self->install_bin ? 1 : 0;
    }

    $self->SUPER::init();
}

sub bootstrap {
    my $self = shift;

    my $init_file = $self->SUPER::bootstrap(@_);
    my $data_dir  = $self->{+DATA_DIR};

    if ($self->{+USE_BOOTSTRAP}) {
        if ($self->{+USE_INSTALLDB}) {
            local $ENV{PERL5LIB} = "";
            $self->run_command([$self->install_bin, '--datadir=' . $data_dir]);
        }
        $self->write_config();
        $self->run_command([$self->start_command, '--bootstrap'], {stdin => $init_file});
    }
    else {
        $self->write_config();
        $self->run_command([$self->start_command, '--initialize']);
        $self->start;
        $self->load_sql("", $init_file);
    }

    return;
}

sub _default_config {
    my $self = shift;

    my %config = $self->SUPER::_default_config(@_);

    $config{mysql}->{'no-auto-rehash'} = '';

    return %config;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickDB::Driver::Percona - Percona MySQL driver for DBIx::QuickDB.

=head1 DESCRIPTION

Percona MySQL driver for L<DBIx::QuickDB>.

=head1 SYNOPSIS

See L<DBIx::QuickDB>.

=head1 MYSQL SPECIFIC OPTIONS

=over 4

=item dbd_driver => $DRIVER

Should be either L<DBD::mysql> or L<DBD::MariaDB>. If not specified then
DBD::mysql is preferred with a fallback to DBD::MariaDB.

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
