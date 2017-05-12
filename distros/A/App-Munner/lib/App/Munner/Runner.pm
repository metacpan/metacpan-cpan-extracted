package App::Munner::Runner;
$App::Munner::Runner::VERSION = '1.01';
use Daemon::Control;
use Mo qw( builder );

has name => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

has base_dir => (
    is      => "ro",
    isa     => "Str",
    default => '.',
);

has app_config => (
    is  => "ro",
    isa => "HashRef",
);

has env => (
    is      => "ro",
    isa     => "HashRef",
    builder => "_build_env",
);

sub _build_env {
    my $self = shift;
    my $conf = $self->app_config;
    return {}
        if !$conf->{env};
    return {}
        if ref $conf->{env} ne "ARRAY";
    return { map { my ( $key, $value ) = %$_ } @{ $conf->{env} } };
}

has fork_mode => (
    is      => "ro",
    isa     => "Int",
    builder => "_build_fork_mode",
);

sub _build_fork_mode {
    my $self = shift;
    return ( $ENV{TERMINAL} // $self->env->{TERMINAL} )
        ? 1
        : ( $self->todo =~ /start|duck/ ? 2 : 1 );
}

has user => (
    is      => "ro",
    isa     => "Str",
    builder => "_build_user",
);

sub _build_user {
    my $self = shift;
    my $user = ( $self->env->{USER} || $ENV{USER} )
        or die "Environment USER is not set\n";
    return $user;
}

has sys_user_info => (
    is      => "ro",
    isa     => "HashRef",
    builder => "_build_sys_user_info",
);

sub _build_sys_user_info {
    my $self = shift;
    my $user = $self->user;
    my %info = ();
    @info{qw( username password uid gid )} = getpwnam( $self->user )
        or die "User ($user) is invalid\n";
    return \%info;
}

has sys_uid => (
    is      => "ro",
    isa     => "Int",
    builder => "_build_sys_uid",
);

sub _build_sys_uid {
    shift->sys_user_info->{uid};
}

has sys_gid => (
    is      => "ro",
    isa     => "Int",
    builder => "_build_sys_gid",
);

sub _build_sys_gid {
    shift->sys_user_info->{gid};
}

has log_dir => (
    is      => "ro",
    isa     => "Str",
    builder => "_build_log_dir",
);

sub _build_log_dir {
    my $self    = shift;
    my $env     = $self->env;
    my $log_dir = $ENV{LOG_DIR} || $env->{LOG_DIR}
        or return q{};
    if ( $log_dir !~ /^\// ) {
        my $base_dir = $self->base_dir || q{};
        $log_dir = "$base_dir/$log_dir";
    }
    die "LOG_DIR: $log_dir is not found\n"
        if !-d $log_dir;
    return $log_dir;
}

has pid_file => (
    is      => "ro",
    isa     => "Str",
    builder => "_build_pid_file",
);

sub _build_pid_file {
    my $self     = shift;
    my $base_dir = $self->log_dir || $self->base_dir || q{};
    my $app      = $self->name;
    my $file
        = $ENV{PID_FILE} || $self->env->{PID_FILE} || "$base_dir/$app.pid";
    return $self->_touch($file);
}

has error_log => (
    is      => "ro",
    isa     => "Str",
    builder => "_build_error_log",
);

sub _build_error_log {
    my $self     = shift;
    my $base_dir = $self->log_dir || $self->base_dir || q{};
    my $app      = $self->name;
    my $file
        = $ENV{ERROR_LOG}
        || $self->env->{ERROR_LOG}
        || "$base_dir/$app.error.log";
    return $self->_touch($file);
}

has access_log => (
    is      => "ro",
    isa     => "Str",
    builder => "_build_access_log",
);

sub _build_access_log {
    my $self     = shift;
    my $base_dir = $self->log_dir || $self->base_dir || q{};
    my $app      = $self->name;
    my $file
        = $ENV{ACCESS_LOG}
        || $self->env->{ACCESS_LOG}
        || "$base_dir/$app.access.log";
    return $self->_touch($file);
}

has command => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

has _daemon => (
    is      => "ro",
    isa     => "Daemon::Control",
    builder => "_build_daemon",
);

has todo => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

sub _build_daemon {
    my $self   = shift;
    my $config = $self->config_file;
    my $app    = $self->name;
    my $cmd    = $self->command;
    my $info   = $self->sys_user_info;

    $self->_touch($cmd)
        if -f $cmd;

    my $daemon = Daemon::Control->new(
        {   name        => $app,
            lsb_start   => q{$syslog $remote_fs},
            lsb_stop    => q{$syslog},
            lsb_sdesc   => $app,
            lsb_desc    => $app,
            directory   => $self->base_dir,
            program     => $cmd,
            pid_file    => $self->pid_file,
            stderr_file => $self->error_log,
            stdout_file => $self->access_log,
            fork        => $self->fork_mode,
            uid         => $info->{uid},
            gid         => $info->{gid},
        }
    );

    return $daemon;
}

sub run {
    my $self = shift;
    $self->_daemon->do_foreground;
}

sub run_at_bg {
    my $self   = shift;
    my $daemon = $self->_daemon;
    $daemon->do_start;
}

sub stop {
    my $self = shift;
    $self->_daemon->do_stop;
}

sub restart {
    my $self = shift;
    $self->_daemon->do_restart;
}

sub graceful {
    my $self = shift;
    $self->_daemon->do_reload;
}

has config_file => (
    is       => "ro",
    isa      => "Str",
    required => 1,
);

sub status {
    my $self = shift;
    $self->_daemon->do_status;
}

sub _set_file_permission {
    my $self = shift;
    my $file = shift
        or die "FIXME: Missing file name";
    die "FIXME: file is not found"
        if !-f $file;
    my $info = $self->sys_user_info;
    my $uid  = $info->{uid};
    my $gid  = $info->{gid};
    chown $uid, $gid, $file
        or die "Unable to chown $file\n";
    chmod 0700, $file
        or die "Unable to chown $file to 0700\n";
}

sub _touch {
    my $self = shift;
    my $file = shift;
    open my $FH, ">>", $file
        or die "Unable to touch file $file because $!\n";
    print $FH q{};
    close $FH;
    $self->_set_file_permission($file);
    my $app = $self->name;
    return $file;
}

1;
