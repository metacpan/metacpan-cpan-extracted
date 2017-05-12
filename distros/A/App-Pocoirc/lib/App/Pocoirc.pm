package App::Pocoirc;
BEGIN {
  $App::Pocoirc::AUTHORITY = 'cpan:HINRIK';
}
{
  $App::Pocoirc::VERSION = '0.47';
}

use strict;
use warnings FATAL => 'all';

use App::Pocoirc::Status;
use Class::Load qw(try_load_class);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Glob ':glob';
use File::Spec::Functions 'rel2abs';
use IO::Handle;
use IRC::Utils qw(decode_irc);
use POE;
use POE::Component::Client::DNS;
use POSIX 'strftime';
use Scalar::Util 'looks_like_number';

sub new {
    my ($package, %args) = @_;
    return bless \%args, $package;
}

sub run {
    my ($self) = @_;

    # we print IRC output, which will be UTF-8
    binmode $_, ':utf8' for (*STDOUT, *STDERR);

    if ($self->{list_plugins}) {
        require Module::Pluggable;
        Module::Pluggable->import(
            sub_name    => '_available_plugins',
            search_path => 'POE::Component::IRC::Plugin',
        );
        for my $plugin (sort $self->_available_plugins()) {
            $plugin =~ s/^POE::Component::IRC::Plugin:://;
            print $plugin, "\n";
        }
        return;
    }

    $self->_setup();

    if ($self->{check_cfg}) {
        print "The configuration is valid and all modules could be compiled.\n";
        return;
    }

    if ($self->{daemonize}) {
        require Proc::Daemon;
        eval {
            Proc::Daemon::Init->();
            if (defined $self->{log_file}) {
                open STDOUT, '>>:encoding(utf8)', $self->{log_file}
                    or die "Can't open $self->{log_file}: $!\n";
                open STDERR, '>>&STDOUT' or die "Can't redirect STDERR: $!\n";
                STDOUT->autoflush(1);
            }
            $poe_kernel->has_forked();
        };
        chomp $@;
        die "Can't daemonize: $@\n" if $@;
    }

    if (defined $self->{pid_file}) {
        sysopen my $fh, $self->{pid_file}, O_CREAT|O_EXCL|O_WRONLY
            or die "Can't create pid file or it already exists. Pocoirc already running?\n";
        print $fh "$$\n";
        close $fh;
    }

    POE::Session->create(
        object_states => [
            $self => [qw(
                _start
                sig_die
                sig_int
                sig_term
                irc_plugin_add
                irc_plugin_del
                irc_plugin_error
                irc_plugin_status
                irc_network
                irc_shutdown
            )],
            $self => {
                irc_432 => 'irc_432_or_433',
                irc_433 => 'irc_432_or_433',
            },
        ],
    );

    $poe_kernel->run();
    unlink $self->{pid_file} if defined $self->{pid_file};
    return;
}

sub _setup {
    my ($self) = @_;

    if (defined $self->{cfg}{pid_file}) {
        $self->{pid_file} = rel2abs(bsd_glob(delete $self->{cfg}{pid_file}));
    }

    if (defined $self->{cfg}{log_file}) {
        my $log = rel2abs(bsd_glob(delete $self->{cfg}{log_file}));
        open my $fh, '>>', $log or die "Can't open $log: $!\n";
        close $fh;
        $self->{log_file} = $log;
    }

    if (!$self->{no_color}) {
        require Term::ANSIColor;
        Term::ANSIColor->import();
    }

    if (defined $self->{cfg}{lib}) {
        if (ref $self->{cfg}{lib} eq 'ARRAY' && @{ $self->{cfg}{lib} }) {
            unshift @INC, map { rel2abs(bsd_glob($_)) } @{ delete $self->{cfg}{lib} };
        }
        else {
            unshift @INC, rel2abs(bsd_glob(delete $self->{cfg}{lib}));
        }
    }

    $self->_load_classes();
    return;
}

sub _load_classes {
    my ($self) = @_;

    for my $plug_spec (@{ $self->{cfg}{global_plugins} || [] }) {
        $self->_load_plugin($plug_spec);
    }

    while (my ($network, $opts) = each %{ $self->{cfg}{networks} }) {
        while (my ($opt, $value) = each %{ $self->{cfg} }) {
            next if $opt =~ /^(?:networks|global_plugins|local_plugins)$/;
            $opts->{$opt} = $value if !defined $opts->{$opt};
        }

        for my $plug_spec (@{ $opts->{local_plugins} || [] }) {
            $self->_load_plugin($plug_spec);
        }

        if (!defined $opts->{server}) {
            die "Server for network '$network' not specified\n";
        }

        if (defined $opts->{class}) {
            $opts->{class} = _load_either_class(
                "POE::Component::IRC::$opts->{class}",
                $opts->{class},
            );
        }
        else {
            $opts->{class} = 'POE::Component::IRC::State';
            my ($success, $error) = try_load_class($opts->{class});
            chomp $error if defined $error;
            die "Can't load class $opts->{class}: $error\n" if !$success;
        }
    }

    return;
}

# create plugins, spawn components, and connect to IRC
sub _start {
    my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];

    $kernel->sig(DIE => 'sig_die');
    $kernel->sig(INT => 'sig_int');
    $kernel->sig(TERM => 'sig_term');

    $self->_status(undef, 'normal', "Started (pid $$)");
    my ($own, $global, $local) = $self->_construct_objects();
    $self->_register_plugins($session->ID(), $own, $global, $local);
    $self->{own_plugins} = $own;

    for my $entry (@{ $self->{ircs} }) {
        my ($network, $irc) = @$entry;
        $self->_status($network, 'normal', 'Connecting to IRC ('.$irc->server.')');
        $irc->yield('connect');
    }

    return;
}

sub _construct_objects {
    my ($self) = @_;

    # create the shared DNS resolver
    $self->{resolver} = POE::Component::Client::DNS->spawn();

    # construct global plugins
    $self->_status(undef, 'normal', "Constructing global plugins");

    my $global_plugs = $self->_create_plugins(delete $self->{cfg}{global_plugins});

    my $own_plugs = [
        [
            'PocoircStatus',
            App::Pocoirc::Status->new(
                Pocoirc => $self,
                Trace   => $self->{trace},
                Verbose => $self->{verbose},
                Dynamic => (defined $self->{cfg_file} ? 1 : 0),
            ),
        ],
    ];

    if ($self->{interactive}) {
        require App::Pocoirc::ReadLine;
        push @$own_plugs, [
            'PocoircReadLine',
            App::Pocoirc::ReadLine->new(
                Pocoirc  => $self,
            ),
        ];
    }

    my $local_plugs;
    # construct IRC components
    while (my ($network, $opts) = each %{ $self->{cfg}{networks} }) {
        my $class = delete $opts->{class};

        # construct network-specific plugins
        $self->_status($network, 'normal', 'Constructing local plugins');
        $local_plugs->{$network} = $self->_create_plugins(delete $opts->{local_plugins});

        $self->_status($network, 'normal', "Spawning IRC component ($class)");
        my $irc = $class->spawn(
            %$opts,
            Resolver => $self->{resolver},
        );
        my $isa = eval { $irc->isa($class) };
        die "isa() test failed for component of class $class\n" if !$isa;
        push @{ $self->{ircs} }, [$network, $irc];
    }

    return $own_plugs, $global_plugs, $local_plugs;
}

sub _load_either_class {
    my ($primary, $secondary) = @_;

    my ($success, $error, @err);
    ($success, $error) = try_load_class($primary);
    return $primary if $success;

    push @err, $error;
    ($success, $error) = try_load_class($secondary);
    return $secondary if $success;

    chomp $error if defined $error;
    push @err, $error;

    my $class = "$primary or $secondary";
    if (@err == 2) {
        if ($err[0] =~ /^Can't locate / && $err[1] !~ /^Can't locate /) {
            $class = $secondary;
            shift @err;
        }
        elsif ($err[1] =~ /^Can't locate / && $err[0] !~ /^Can't locate /) {
            $class = $primary;
            pop @err;
        }
    }
    my $reason = join "\n", map { "  $_" } @err;
    die "Failed to load class $class:\n$reason\n";
}

sub _register_plugins {
    my ($self, $session_id, $own, $global, $local) = @_;

    for my $entry (@{ $self->{ircs} }) {
        my ($network, $irc) = @$entry;
        $self->_status($network, 'normal', 'Registering plugins');

        for my $plugin (@$own, @$global, @{ $local->{$network} }) {
            my ($name, $object) = @$plugin;
            $irc->plugin_add("${name}_$session_id", $object,
                network => $network,
            );
        }
    }

    return;
}

sub _dump {
    my ($arg) = @_;

    if (ref $arg eq 'ARRAY') {
        my @elems;
        for my $elem (@$arg) {
            push @elems, _dump($elem);
        }
        return '['. join(', ', @elems) .']';
    }
    elsif (ref $arg eq 'HASH') {
        my @pairs;
        for my $key (keys %$arg) {
            push @pairs, [$key, _dump($arg->{$key})];
        }
        return '{'. join(', ', map { "$_->[0] => $_->[1]" } @pairs) .'}';
    }
    elsif (ref $arg) {
        require overload;
        return overload::StrVal($arg);
    }
    elsif (defined $arg) {
        return $arg if looks_like_number($arg);
        return "'".decode_irc($arg)."'";
    }
    else {
        return 'undef';
    }
}

sub _event_debug {
    my ($self, $irc, $args, $event) = @_;

    if (!defined $event) {
        $event = (caller(1))[3];
        $event =~ s/.*:://;
    }

    my @output;
    for my $i (0..$#{ $args }) {
        push @output, "ARG$i: " . _dump($args->[$i]);
    }
    $self->_status($irc, 'debug', "$event: ".join(', ', @output));
    return;
}

# let's log this if it's preventing us from logging in
sub irc_432_or_433 {
    my $self = $_[OBJECT];
    my $irc = $_[SENDER]->get_heap();
    my $reason = decode_irc($_[ARG2]->[1]);
    return if $irc->logged_in();
    my $nick = $irc->nick_name();
    $self->_status($irc, 'normal', "Login attempt failed: $reason");
    return;
}

# fetch the server name if we're not using a config file
sub irc_network {
    my ($self, $sender, $network) = @_[OBJECT, SENDER, ARG0];
    my $irc = $sender->get_heap();

    for my $idx (0..$#{ $self->{ircs} }) {
        if ($self->{ircs}[$idx][1] == $irc) {
            $self->{ircs}[$idx][0] = $network;
            last;
        }
    }
    return;
}

# we handle plugin status messages here because the status plugin won't
# see these for previously added plugins or plugin_del for itself, etc
sub irc_plugin_add {
    my ($self, $alias) = @_[OBJECT, ARG0];
    my $irc = $_[SENDER]->get_heap();
    $self->_event_debug($irc, [@_[ARG0..$#_]], 'S_plugin_add') if $self->{trace};
    $self->_status($irc, 'normal', "Added plugin $alias");
    return;
}

sub irc_plugin_del {
    my ($self, $alias) = @_[OBJECT, ARG0];
    my $irc = $_[SENDER]->get_heap();
    $self->_event_debug($irc, [@_[ARG0..$#_]], 'S_plugin_del') if $self->{trace};
    $self->_status($irc, 'normal', "Deleted plugin $alias");
    return;
}

sub irc_plugin_error {
    my ($self, $error) = @_[OBJECT, ARG0];
    my $irc = $_[SENDER]->get_heap();
    $self->_event_debug($irc, [@_[ARG0..$#_]], 'S_plugin_error') if $self->{trace};
    $self->_status($irc, 'error', $error);
    return;
}

sub irc_plugin_status {
    my ($self, $plugin, @args) = @_[OBJECT, ARG0..$#_];
    my $irc        = $_[SENDER]->get_heap();
    my $plugins    = $irc->plugin_list();
    my %plug2alias = map { $plugins->{$_} => $_ } keys %$plugins;

    my $extension = ref $plugin eq 'App::Pocoirc::Status'
        ? ''
        : "/$plug2alias{$plugin}";
    $self->_status($self->_irc_to_network($irc).$extension, @args);
    return;
}

sub irc_shutdown {
    my ($self) = $_[OBJECT];
    my $irc = $_[SENDER]->get_heap();
    $self->_event_debug($irc, [@_[ARG0..$#_]], 'S_shutdown') if $self->{trace};
    $self->_status($irc, 'normal', 'IRC component shut down');
    return;
}

sub verbose {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{verbose} = $value;
        for my $plugin (@{ $self->{own_plugins} }) {
            $plugin->[1]->verbose($value) if $plugin->[1]->can('verbose');
        }
    }
    return $self->{verbose};
}

sub trace {
    my ($self, $value) = @_;
    if (defined $value) {
        $self->{trace} = $value;
        for my $plugin (@{ $self->{own_plugins} }) {
            $plugin->[1]->trace($value) if $plugin->[1]->can('trace');
        }
    }
    return $self->{trace};
}

sub _status {
    my ($self, $context, $type, $message) = @_;

    my $stamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    my $irc = eval { $context->isa('POE::Component::IRC') };
    $context = $self->_irc_to_network($context) if $irc;
    $context = defined $context ? " [$context]\t" : ' ';

    if (defined $type && $type eq 'error') {
        $message = "!!! $message";
    }

    my $log_line = "$stamp$context$message";
    my $term_line = $log_line;

    if (!$self->{no_color}) {
        if (defined $type && $type eq 'error') {
            $term_line = colored($term_line, 'red');
        }
        elsif (defined $type && $type eq 'debug') {
            $term_line = colored($term_line, 'yellow');
        }
        else {
            $term_line = colored($term_line, 'green');
        }
    }

    print $term_line, "\n" if !$self->{daemonize};
    if (defined $self->{log_file}) {
        if (open my $fh, '>>:encoding(utf8)', $self->{log_file}) {
            $fh->autoflush(1);
            print $fh $log_line, "\n";
            close $fh;
        }
        elsif (!$self->{daemonize}) {
            warn "Can't open $self->{log_file}: $!\n";
        }
    }
    return;
}

sub _irc_to_network {
    my ($self, $irc) = @_;

    for my $entry (@{ $self->{ircs} }) {
        my ($network, $object) = @$entry;
        return $network if $irc == $object;
    }

    return;
}

# find out the canonical class name for the plugin and load it
sub _load_plugin {
    my ($self, $plug_spec) = @_;

    return if defined $plug_spec->[2];
    my ($class, $args) = @$plug_spec;
    $args = {} if !defined $args;

    my $canonclass = _load_either_class(
        "POE::Component::IRC::Plugin::$class",
        $class,
    );

    $plug_spec->[1] = $args;
    $plug_spec->[2] = $canonclass;
    return;
}

sub _create_plugins {
    my ($self, $plugins) = @_;

    my @return;
    for my $plug_spec (@$plugins) {
        my ($class, $args, $canonclass) = @$plug_spec;
        my $obj = $canonclass->new(%$args);
        my $isa = eval { $obj->isa($canonclass) };
        die "isa() test failed for plugin of class $canonclass\n" if !$isa;
        push @return, [$class, $obj];
    }

    return \@return;
}

sub sig_die {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    chomp $ex->{error_str};

    my $error = "Event $ex->{event} in session ".$ex->{dest_session}->ID
        ." raised exception:\n    $ex->{error_str}";

    $self->_status(undef, 'error', $error);
    $self->shutdown('Exiting due to an exception') if !$self->{shutdown};
    $kernel->sig_handled();
    return;
}

sub sig_int {
    my ($kernel, $self) = @_[KERNEL, OBJECT];
    $self->shutdown('Exiting due to SIGINT') if !$self->{shutdown};
    $kernel->sig_handled();
    return;
}

sub sig_term {
    my ($kernel, $self) = @_[KERNEL, OBJECT];

    $self->shutdown('Exiting due to SIGTERM') if !$self->{shutdown};
    $kernel->sig_handled();
    return;
}

sub shutdown {
    my ($self, $reason) = @_;

    $self->_status(undef, 'normal', $reason);

    my $logged_in;
    for my $irc (@{ $self->{ircs} }) {
        my ($network, $obj) = @$irc;

        if (!$logged_in && $obj->logged_in()) {
            $logged_in = 1;
            $self->_status(undef, 'normal',
                'Waiting up to 5 seconds for IRC server(s) to disconnect us');
        }
        $obj->yield('shutdown', $reason, 5);
    }

    $self->{resolver}->shutdown() if $self->{resolver};
    $self->{shutdown} = 1;
    return;
}

1;

=encoding utf8

=head1 NAME

App::Pocoirc - A command line tool for launching POE::Component::IRC clients

=head1 DESCRIPTION

This distribution provides a generic way to launch IRC clients which use
L<POE::Component::IRC|POE::Component::IRC>. The main features are:

=over 4

=item * Prints useful status information (to your terminal and/or a log file)

=item * Will daemonize if you so wish

=item * Supports a configuration file

=item * Offers a user friendly way to pass arguments to POE::Component::IRC

=item * Supports multiple IRC components and lets you specify which plugins
to load locally (one object per component) or globally (single object)

=item * Has an interactive mode where you can issue issue commands and
call methods on the IRC component(s).

It can be used to launch IRC bots or proxies, loaded with plugins of your
choice. It is very useful for testing and debugging
L<POE::Component::IRC|POE::Component::IRC> plugins as well as IRC servers.

=back

=head1 CONFIGURATION

 nick:     foobar1234
 username: foobar
 log_file: /my/log.file
 lib:      /my/modules

 global_plugins:
   - [CTCP]

 local_plugins:
   - [BotTraffic]

 networks:
   freenode:
     server: irc.freenode.net
     local_plugins:
       - [AutoJoin, { Channels: ['#foodsfdsf'] } ]
   magnet:
     server: irc.perl.org
     nick:   hlagherf32fr

The configuration file is in L<YAML|YAML> or L<JSON|JSON> format. It consists
of a hash containing C<global_plugins>, C<local_plugins>, C<networks>, C<lib>,
C<log_file>, C<class>, and default parameters to
L<POE::Component::IRC|POE::Component::IRC/spawn>. Only C<networks> is
required.

C<lib> is either the name of a directory containing Perl modules (e.g.
plugins), or an array of such names. Kind of like Perl's I<-I>.

C<log_file> is the path to a log file to which status messages will be written.

C<class> is the IRC component class. Defaults to
L<POE::Component::IRC::State|POE::Component::IRC::State>.

=head2 Networks

The C<networks> option should be a hash of network hashes. The keys are the
names of the networks. A network hash can contain C<local_plugins> and
parameters to POE::Component::IRC. None are required, except C<server> if not
defined at the top level. The POE::Component::IRC parameters specified in this
hash will override the ones specified at the top level.

=head2 Plugins

The C<global_plugins> and C<local_plugins> options should consist of an array
containing the short plugin class name (e.g. 'AutoJoin') and optionally a hash
of arguments to that plugin. When figuring out the correct package name,
App::Pocoirc will first try to load POE::Component::IRC::Plugin::I<YourPlugin>
before trying to load I<YourPlugin>.

The plugins in C<global_plugins> will be instantiated once and then added to
all IRC components. B<Note:> not all plugins are designed to be used with
multiple IRC components simultaneously.

If you specify C<local_plugins> at the top level, it will serve as a default
list of local plugins, which can be overridden in a network hash.

=head1 OUTPUT

Here is some example output from the program:

 $ pocoirc -f example/config.yml
 2011-04-18 18:10:52 Started (pid 20105)
 2011-04-18 18:10:52 Constructing global plugins
 2011-04-18 18:10:52 [freenode]  Constructing local plugins
 2011-04-18 18:10:52 [freenode]  Spawning IRC component (POE::Component::IRC::State)
 2011-04-18 18:10:52 [magnet]    Constructing local plugins
 2011-04-18 18:10:52 [magnet]    Spawning IRC component (POE::Component::IRC::State)
 2011-04-18 18:10:52 [freenode]  Registering plugins
 2011-04-18 18:10:52 [magnet]    Registering plugins
 2011-04-18 18:10:52 [freenode]  Connecting to IRC (irc.freenode.net)
 2011-04-18 18:10:52 [magnet]    Connecting to IRC (irc.perl.org)
 2011-04-18 18:10:52 [freenode]  Added plugin Whois3
 2011-04-18 18:10:52 [freenode]  Added plugin ISupport3
 2011-04-18 18:10:52 [freenode]  Added plugin DCC3
 2011-04-18 18:10:52 [magnet]    Added plugin Whois5
 2011-04-18 18:10:52 [magnet]    Added plugin ISupport5
 2011-04-18 18:10:52 [magnet]    Added plugin DCC5
 2011-04-18 18:10:52 [freenode]  Added plugin CTCP1
 2011-04-18 18:10:52 [freenode]  Added plugin AutoJoin1
 2011-04-18 18:10:52 [freenode]  Added plugin PocoircStatus1
 2011-04-18 18:10:52 [magnet]    Added plugin CTCP1
 2011-04-18 18:10:52 [magnet]    Added plugin PocoircStatus1
 2011-04-18 18:10:52 [magnet]    Connected to server irc.perl.org
 2011-04-18 18:10:52 [magnet]    Server notice: *** Looking up your hostname...
 2011-04-18 18:10:52 [magnet]    Server notice: *** Checking Ident
 2011-04-18 18:10:52 [freenode]  Connected to server irc.freenode.net
 2011-04-18 18:10:53 [magnet]    Server notice: *** Found your hostname
 2011-04-18 18:10:53 [freenode]  Server notice: *** Looking up your hostname...
 2011-04-18 18:10:53 [freenode]  Server notice: *** Checking Ident
 2011-04-18 18:10:53 [freenode]  Server notice: *** Couldn't look up your hostname
 2011-04-18 18:11:03 [magnet]    Server notice: *** No Ident response
 2011-04-18 18:11:03 [magnet]    Logged in to server magnet.shadowcat.co.uk with nick hlagherf32fr
 2011-04-18 18:11:07 [freenode]  Server notice: *** No Ident response
 2011-04-18 18:11:07 [freenode]  Logged in to server niven.freenode.net with nick foobar1234
 2011-04-18 18:11:11 [freenode]  Joined channel #foodsfdsf
 ^C2011-04-18 18:11:22 Exiting due to SIGINT
 2011-04-18 18:11:22 Waiting up to 5 seconds for IRC server(s) to disconnect us
 2011-04-18 18:11:22 [magnet]    Error from IRC server: Closing Link: 212-30-192-157.static.simnet.is ()
 2011-04-18 18:11:22 [magnet]    Deleted plugin DCC5
 2011-04-18 18:11:22 [magnet]    Deleted plugin ISupport5
 2011-04-18 18:11:22 [magnet]    Deleted plugin CTCP1
 2011-04-18 18:11:22 [magnet]    Deleted plugin Whois5
 2011-04-18 18:11:22 [magnet]    Deleted plugin PocoircStatus1
 2011-04-18 18:11:22 [magnet]    IRC component shut down
 2011-04-18 18:11:22 [freenode]  Quit from IRC (Client Quit)
 2011-04-18 18:11:22 [freenode]  Error from IRC server: Closing Link: 212.30.192.157 (Client Quit)
 2011-04-18 18:11:22 [freenode]  Deleted plugin AutoJoin1
 2011-04-18 18:11:22 [freenode]  Deleted plugin CTCP1
 2011-04-18 18:11:22 [freenode]  Deleted plugin DCC3
 2011-04-18 18:11:22 [freenode]  Deleted plugin PocoircStatus1
 2011-04-18 18:11:22 [freenode]  Deleted plugin Whois3
 2011-04-18 18:11:22 [freenode]  Deleted plugin ISupport3
 2011-04-18 18:11:22 [freenode]  IRC component shut down

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2010 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
