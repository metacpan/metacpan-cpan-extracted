package Daemonise;

use Modern::Perl;
use Mouse;
use File::Basename;
use FindBin qw($Bin);
use lib "$Bin/../lib";

# ABSTRACT: Daemonise - a general daemoniser for anything...

our $VERSION = '2.13'; # VERSION

use Config::Any;
use POSIX qw(strftime SIGTERM SIG_BLOCK SIG_UNBLOCK);


has 'name' => (
    is        => 'rw',
    default   => sub { (my $name = basename($0)) =~ s/\.[^.]+$//; $name },
    predicate => 'has_name',
);


has 'hostname' => (
    is      => 'ro',
    isa     => 'Str',
    lazy    => 1,
    builder => 'build_hostname',
);


has 'config_file' => (
    is        => 'rw',
    isa       => "Str",
    predicate => 'has_config_file',
);


has 'config' => (
    is      => 'rw',
    isa     => 'HashRef',
    lazy    => 1,
    default => sub { {} },
);


has 'debug' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 0 },
);


has 'start_time' => (
    is      => 'rw',
    isa     => 'Int',
    default => sub { time },
);


has 'is_cron' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 0 },
);


has 'cache_plugin' => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'KyotoTycoon' },
);


has 'print_log' => (
    is      => 'rw',
    isa     => 'Bool',
    lazy    => 1,
    default => sub { 1 },
);


after 'new' => sub {
    my ($class, %args) = @_;

    # backwards compatibility
    with('Daemonise::Plugin::Daemon')
        unless ($args{no_daemon} or $args{is_cron});
    with('Daemonise::Plugin::Syslog')
        unless ($args{no_syslog});

    # load cache plugin required for cron locking
    if ($args{is_cron}) {
        my $cache = ($args{cache_plugin} || 'KyotoTycoon');

        return if %Daemonise::Plugin::KyotoTycoon:: and $cache eq 'KyotoTycoon';
        return if %Daemonise::Plugin::Redis::       and $cache eq 'Redis';

        my $cache_plugin = "Daemonise::Plugin::" . $cache;
        with($cache_plugin);
    }

    return;
};


sub load_plugin {
    my ($self, $plugin) = @_;

    my $plug = 'Daemonise::Plugin::' . $plugin;
    $self->log("loading $plugin plugin") if $self->debug;
    with($plug);

    return;
}


sub configure {
    my ($self, $reconfig) = @_;

    ### install a signal handler as anchor for clean shutdowns in plugins
    $SIG{QUIT} = sub { $self->stop };    ## no critic
    $SIG{TERM} = sub { $self->stop };    ## no critic
    $SIG{INT}  = sub { $self->stop };    ## no critic

    unless ($self->has_config_file) {
        $self->log("config_file unset, nothing to configure");
        return;
    }

    unless (-e $self->config_file) {
        $self->log(
            "ERROR: config file '" . $self->config_file . "' does not exist!");
        return;
    }

    my $conf = Config::Any->load_files({
        files       => [ $self->config_file ],
        use_ext     => 1,
        driver_args => { General => { -InterPolateEnv => 1 } },
    });
    $conf = $conf->[0]->{ $self->config_file } if $conf;

    $self->config($conf);

    return;
}


sub async {
    my ($self) = @_;

    ### block signal for fork
    my $sigset = POSIX::SigSet->new(SIGTERM);
    POSIX::sigprocmask(SIG_BLOCK, $sigset)
        or die "Can't block SIGTERM for fork: [$!]\n";

    ### fork off a child
    my $pid = fork;
    unless (defined $pid) {
        die "Couldn't fork: [$!]\n";
    }

    ### make SIGTERM kill us as it did before
    local $SIG{TERM} = 'DEFAULT';

    ### put back to normal
    POSIX::sigprocmask(SIG_UNBLOCK, $sigset)
        or die "Can't unblock SIGTERM for fork: [$!]\n";

    return $pid;
}


sub log {    ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $msg) = @_;

    return unless $self->print_log;

    chomp($msg);
    my $now = strftime "%F %T", localtime;
    say("${now} " . $self->hostname . ' ' . $self->name . "[$$]: $msg");

    return;
}


sub notify {
    my ($self, $msg, $room, $severity, $notify_users, $message_format) = @_;

    $self->log($msg);

    return;
}


sub start {
    my ($self) = @_;

    $self->log("rabbit starting");

    return;
}


sub stop {
    my ($self) = @_;

    $self->log("good bye cruel world!");
    $self->graph('hase.' . $self->name, 'stopped', 1) if $self->can('graph');

    exit;
}


sub round {
    my ($self, $float) = @_;

    # some stupid perl versions on some platforms can't round correctly and i
    # don't want to use more modules
    $float += 0.001 if ($float =~ m/\.[0-9]{2}5/);

    return sprintf('%.2f', sprintf('%.10f', $float + 0)) + 0;
}


sub dump {    ## no critic (ProhibitBuiltinHomonyms)
    my ($self, $obj, $nocolor_multiline) = @_;

    my %options;
    if ($self->debug) {
        $options{colored} = $nocolor_multiline ? 0 : 1;
    }
    else {
        $options{colored} = 0;
        $options{multiline} = $nocolor_multiline ? 1 : 0;
    }

    require Data::Printer;
    Data::Printer->import(%options) unless __PACKAGE__->can('np');

    my $dump;
    if (ref $obj) {
        $dump = np($obj, %options);
    }
    else {
        $dump = np(\$obj, %options);
    }

    return $dump;
}


sub stdout_redirect { }


sub build_hostname {
    my ($self) = @_;

    my $hostname = `hostname -s`;
    chomp $hostname;

    # support freebsd jails with custom rc.conf variable
    if ($^O eq 'freebsd' and -x '/usr/sbin/sysrc') {
        my $h = `/usr/sbin/sysrc -n jail_host`;
        $hostname = "$hostname\@$h" unless $h =~ m/unknown variable/;
        chomp $hostname;
    }

    return $hostname;
}


1;    # End of Daemonise

__END__

=pod

=encoding UTF-8

=head1 NAME

Daemonise - Daemonise - a general daemoniser for anything...

=head1 VERSION

version 2.13

=head1 SYNOPSIS

    use Daemonise;
    use File::Basename;

    my $d = Daemonise->new();
    $d->name(basename($0));

    # log/print more debug info
    $d->debug(1);

    # stay in foreground, don't actually fork when calling $d->start
    $d->foreground(1) if $d->debug;

    # config file style can be whatever Config::Any supports
    $d->config_file('/path/to/some.conf');

    # where to store/look for PID file
    $d->pid_file("/var/run/${name}.pid");

    # configure everything so far
    $d->configure;

    # fork and redirect STDERR/STDOUT to syslog per default
    $d->start;

    # load some plugins (refer to plugin documentation for provided methods)
    $d->load_plugin('RabbitMQ');
    $d->load_plugin('CouchDB');
    $d->load_plugin('JobQueue');
    $d->load_plugin('Event');
    $d->load_plugin('Redis');
    $d->load_plugin('HipChat');
    $d->load_plugin('Riemann');
    $d->load_plugin('PagerDuty');
    $d->load_plugin('KyotoTycoon');
    $d->load_plugin('Graphite');

    # reconfigure after loading plugins if necessary
    $d->configure;

    # do stuff

=head1 ATTRIBUTES

=head2 name

=head2 hostname

=head2 config_file

=head2 config

=head2 debug

=head2 start_time

=head2 is_cron

=head2 cache_plugin

=head2 print_log

=head1 SUBROUTINES/METHODS

=head2 new

=head2 load_plugin

=head2 configure

=head2 async

=head2 log

=head2 notify

This is a stub that can be extended by plugins like HipChat and Slack

=head2 start

stub method to hook into by plugins

=head2 stop

=head2 round

=head2 dump

=head2 stdout_redirect

method hook for redirecting STDOUT/STDERR in plugins
most recent loaded plugin takes precedence using C<around> modifier only

=head2 build_hostname

=head1 DEPLOY PROCESS

This module uses Dist::Zilla for the release process. To get it up and running
do the following:

    cpanm Dist::Zilla
    git clone https://github.com/ideegeo/Daemonise
    cd Daemonise
    dzil authordeps --missing | cpanm
    dzil listdeps --author --develop | cpanm

At this point all required plugins for Dist::Zilla and modules to run tests
should be installed. Daemonise uses PGP signed github releases, so make sure your
git config user and email are setup correctly as well as a PGP key that matches
your git(hub) account email. Try Config::Identity for a PGP encrypted file of
your github account credentials in ~/.github for convenience.
Finally run:

    dzil release

which will do all the work (build, test, sign, tag, update github, upload).

=head1 BUGS

Please report any bugs or feature requests on GitHub's issue tracker L<https://github.com/ideegeo/Daemonise/issues>.

=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Daemonise

You can also look for information at:

=over 4

=item * GitHub repository

L<https://github.com/ideegeo/Daemonise>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Daemonise>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Daemonise>

=back

=head1 ACKNOWLEDGEMENTS

=head1 AUTHOR

Lenz Gschwendtner <norbu09@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2013 by Lenz Gschwendtner.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
