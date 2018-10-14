package TestBot;

use strict;
use warnings;

use autodie;
use Cwd qw(abs_path getcwd);
use File::Remove 'remove';
use File::Spec;
use POSIX qw(SIGTERM);
use Socket;
use Symbol;

use base 'Class::Accessor::Fast';
__PACKAGE__->mk_accessors(
    qw( dir pid_file output_file addr port client_config_file )
);

my @info = getpwnam( $ENV{USER} = getpwuid($>) );

our $USER = $info[0];

( our $USER_NAME = $info[6] ) =~ s/,.*//;

our $COMMIT_USER
    = $USER_NAME
    ? "06${USER_NAME} (06${USER})"
    : "06${USER} (06${USER})";

sub start {
    my $class = shift;
    my $self  = $class->new();

    my $dir = abs_path( File::Spec->catdir( 't', 'bot' ) );
    $self->pid_file( File::Spec->catfile( $dir, 'kgb-bot.pid' ) );
    $self->output_file( File::Spec->catfile( $dir, 'output' ) );
    unlink $self->output_file if -e $self->output_file;

    my $proto = getprotobyname('tcp');
    my $srv = gensym;

    socket( $srv, PF_INET, SOCK_STREAM, $proto ) or die "socket: $!";
    setsockopt( $srv, SOL_SOCKET, SO_REUSEADDR, pack( "l", 1 ) )
        or die "setsockopt: $!";

    #use Carp;
    #local $SIG{__WARN__} = \&Carp::cluck;
    #local $SIG{__DIE__} = \&Carp::confess;

    my $addr = INADDR_LOOPBACK;
    my $port = 5392;
    my $tries = 1;

    while(1) {
        warn "# trying port $port\n";
        warn("# port $port is available\n"), last
            if eval { bind( $srv, pack_sockaddr_in( $port, $addr ) ) };

        warn "# port $port is busy\n";

        $port++;
        $tries++;
        die "Unable to find free port" if $tries > 1000;
    }

    close($srv);

    mkdir $dir unless -d $dir;

    $addr = inet_ntoa($addr);

    my $conf_file   = File::Spec->catfile( $dir, 'test-bot.conf' );
    open( my $fh, '>', $conf_file);
    print $fh <<EOF;
---
soap:
  server_addr: $addr
  server_port: $port
  service_name: KGB
pid_dir: t/bot
debug: 0
repositories:
 test:
   password: "truely secret"
networks:
 dummy:
  nick: KGBOO
  server: nonexisting
channels:
 - name: '#test'
   network: dummy
   repos:
    - test
log_file: $dir/kgb-bot.log
webhook:
 enabled: 1
 allowed_networks:
  - $addr
short_url_service: DummyShortener
EOF
    chmod 0600, $fh;
    close($fh);

    my $bot_script =
        $ENV{KGB_BOT_SCRIPT} || File::Spec->catfile( 'script', 'kgb-bot' );

    my $t_dir = File::Spec->catdir(getcwd, 't');
    my $dirs = $ENV{PERL5LIB};
    if ($dir) { $dirs .= ":$t_dir" }
    else      { $dirs = $t_dir }
    $ENV{PERL5LIB} = $dirs;

    system( $bot_script,
        '--config', $conf_file, '--simulate', $self->output_file,
        '--simulate-color' ) == 0
        or die "bot exec error";

    # wait for the PID file to appear and to have content
    while ( ( not -e $self->pid_file ) or ( not -s _ ) ) {
        sleep 0.1;
    }
    my $pid = do {
        open( my $fh, $self->pid_file );
        my $pid = <$fh>;
        chomp($pid);
        close $fh;
        $pid;
    };

    $self->addr($addr);
    $self->port($port);

    warn "# test bot listening on $addr:$port, pid: $pid ";

    my $client_config_file = File::Spec->catfile($dir, 'client.conf');
    $self->client_config_file($client_config_file);

    open( $fh, '>', $client_config_file );
    print $fh <<EOF;
---
repo-id: test
branch-and-module-re:
 - "/(trunk|tags|apps|attic)/([^/]+)"
 - "/branches/([^/]+)/([^/]+)"
web-link: "http://scm.host.org/\${module}/\${branch}/?commit=\${commit}"
use-irc-notices: 0
use-color: 1
password: "truely secret"
timeout: 15
servers:
 - uri: http://$addr:$port/
message-template: "\${{project}/}\${{module}}\${ {branch}}\${ {commit}}\${ {author-name}}\${ ({author-login})}\${ {changes}}\${ {log-first-line}}\${ * {web-link}}"
status-dir: $dir
batch-messages: 1
EOF

    close $fh;

    $self->dir($dir);

    return $self;
}

sub get_output {
    my $self = shift;

    my $fh;
    eval { open( $fh, $self->output_file ); 1 } or return '';
    binmode( $fh, ':utf8' );
    local $/ = undef;
    return <$fh>;
}

sub stop {
    my $self = shift;

    if ( not -e $self->pid_file ) {
        warn "# " . $self->pid_file . " doesn't exist\n";
        return;
    }

    open my $fh, $self->pid_file;
    my $pid = <$fh>;
    chomp($pid);
    close($fh);

    warn "# stopping test bot, pid $pid\n";
    kill SIGTERM, $pid;

    while ( -e $self->pid_file ) {
        sleep 0.1;
    }
}

sub clean {
    my $self = shift;

    if( my $dir = $self->dir ) {
        warn "# Removing directory $dir\n";
        remove \1, $dir;
    }
}

sub DESTROY {
    my $self = shift;

    $self->stop;
    $self->clean;
}

my $expected = '';

sub expect {
    my $class = shift;
    $expected .= shift . "\n";
}

sub expected_output {
    return $expected;
}

1;
