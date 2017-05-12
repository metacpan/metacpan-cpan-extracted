package App::Pocosi;
BEGIN {
  $App::Pocosi::AUTHORITY = 'cpan:HINRIK';
}
BEGIN {
  $App::Pocosi::VERSION = '0.03';
}

use strict;
use warnings FATAL => 'all';

# we want instant child process reaping
sub POE::Kernel::USE_SIGCHLD () { return 1 }

use App::Pocosi::Status;
use Class::Load qw(try_load_class);
use Fcntl qw(O_CREAT O_EXCL O_WRONLY);
use File::Glob ':glob';
use File::Spec::Functions 'rel2abs';
use IO::Handle;
use IRC::Utils qw(decode_irc);
use Net::Netmask;
use POE;
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
            search_path => 'POE::Component::Server::IRC::Plugin',
        );
        for my $plugin (sort $self->_available_plugins()) {
            $plugin =~ s/^POE::Component::Server::IRC::Plugin:://;
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
            or die "Can't create pid file or it already exists. Pocosi already running?\n";
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
                ircd_plugin_add
                ircd_plugin_del
                ircd_plugin_error
                ircd_plugin_status
                ircd_shutdown
            )],
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
    my $cfg = $self->{cfg};

    for my $plug_spec (@{ $cfg->{plugins} || [] }) {
        $self->_load_plugin($plug_spec);
    }

    if (!defined $cfg->{config}) {
        die "No 'config' parameter found in config file\n";
    }

    if (defined $cfg->{class}) {
        $cfg->{class} = _load_either_class(
            "POE::Component::Server::IRC::$cfg->{class}",
            $cfg->{class},
        );
    }
    else {
        $cfg->{class} = 'POE::Component::Server::IRC';
        my ($success, $error) = try_load_class($cfg->{class});
        chomp $error if defined $error;
        die "Can't load class $cfg->{class}: $error\n" if !$success;
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
        "POE::Component::Server::IRC::Plugin::$class",
        $class,
    );

    $plug_spec->[1] = $args;
    $plug_spec->[2] = $canonclass;
    return;
}

# create plugins, spawn components, and connect to IRC
sub _start {
    my ($kernel, $session, $self) = @_[KERNEL, SESSION, OBJECT];

    $kernel->sig(DIE => 'sig_die');
    $kernel->sig(INT => 'sig_int');
    $kernel->sig(TERM => 'sig_term');
    $self->_status('normal', "Started (pid $$)");

    $self->_status('normal', "Constructing plugins");
    my ($own_plugs, $plugins) = $self->_construct_plugins();

    $self->_status('normal', "Spawning IRCd component ($self->{cfg}{class})");
    my $ircd = $self->_spawn_ircd();

    $self->_status('normal', 'Registering plugins');
    $self->_register_plugins($ircd, $session->ID(), [@$own_plugs, @$plugins]);

    $self->{own_plugins} = $own_plugs;
    $self->{ircd} = $ircd;

    $self->_add_auths();
    $self->_add_operators();
    $self->_add_denials();
    $self->_add_exemptions();
    $self->_add_peers();
    $self->_add_listeners();

    return;
}

sub _construct_plugins {
    my ($self) = @_;

    my $plug_specs = $self->{cfg}{plugins};
    my @plugins;
    for my $plug_spec (@$plug_specs) {
        my ($class, $args, $canonclass) = @$plug_spec;
        my $obj = $canonclass->new(%$args);
        my $isa = eval { $obj->isa($canonclass) };
        die "isa() test failed for plugin of class $canonclass\n" if !$isa;
        push @plugins, [$class, $obj];
    }

    my @own_plugs = (
        [
            'PocosiStatus',
            App::Pocosi::Status->new(
                Pocosi  => $self,
                Trace   => $self->{trace},
                Verbose => $self->{verbose},
            ),
        ],
    );

    if ($self->{interactive}) {
        require App::Pocosi::ReadLine;
        push @own_plugs, [
            'PocosiReadLine',
            App::Pocosi::ReadLine->new(
                Pocosi => $self,
            ),
        ];
    }

    return \@own_plugs, \@plugins;
}

sub _spawn_ircd {
    my ($self) = @_;

    my $class = $self->{cfg}{class};
    my $ircd = $class->spawn(
        plugin_debug => 1,
        config       => $self->{cfg}{config},
        ($self->{cfg}{flood} ? (antiflood => 0) : ()),
        (defined $self->{cfg}{auth} ? (auth => $self->{cfg}{auth}) : ()),
    );
    my $isa = eval { $ircd->isa($class) };
    die "isa() test failed for component of class $class\n" if !$isa;

    return $ircd;
}

sub _load_either_class {
    my ($primary, $secondary) = @_;

    my ($success, $error, $errors);
    ($success, $error) = try_load_class($primary);
    return $primary if $success;

    $errors .= $error;
    ($success, $error) = try_load_class($secondary);
    return $secondary if $success;

    chomp $error if defined $error;
    $errors .= $error;
    die "Failed to load class $primary or $secondary: $errors\n";
}

sub _register_plugins {
    my ($self, $ircd, $session_id, $plugins) = @_;

    for my $plugin (@$plugins) {
        my ($name, $object) = @$plugin;
        $ircd->plugin_add("${name}_$session_id", $object);
    }

    return;
}

sub _add_denials {
    my ($self) = @_;
    my $ircd = $self->{ircd};
    my $denials = $self->{cfg}{denials};
    return if !defined $denials;

    for my $denial (@$denials) {
        my ($mask, $reason) = @$denial;
        my $netmask = Net::Netmask->new2($mask);
        if (!defined $netmask) {
            die "Invalid denial: $mask\n";
        }
        $ircd->add_denial($netmask, $reason);
    }
    return;
}

sub _add_exemptions {
    my ($self) = @_;
    my $ircd = $self->{ircd};
    my $exemptions = $self->{cfg}{exemptions};
    return if !defined $exemptions;

    for my $mask (@$exemptions) {
        my $netmask = Net::Netmask->new2($mask);
        if (!defined $netmask) {
            die "Invalid exemption: $mask\n";
        }
        $ircd->add_exemption($netmask);
    }
    return;
}

sub _add_operators {
    my ($self) = @_;
    my $ircd = $self->{ircd};
    my $opers = $self->{cfg}{operators};
    return if !defined $opers;

    for my $oper (@$opers) {
        die "No username supplier for operator\n" if !defined $oper->{username};
        if (ref $oper->{ipmask} eq 'ARRAY') {
            my @netmasks;
            for my $mask (@{ $oper->{ipmask} }) {
                my $netmask = Net::Netmask->new2($mask);
                if (!defined $netmask) {
                    die "Invalid netmask for oper $oper->{username}: $mask\n";
                }
                push @netmasks, $netmask;
            }
            $oper->{ipmask} = \@netmasks;
        }

        $ircd->add_operator(%$oper);
    }
    return;
}

sub _add_peers {
    my ($self) = @_;
    my $ircd = $self->{ircd};
    my $peers = $self->{cfg}{peers};
    return if !defined $peers;
    $ircd->add_peer(%$_) for @$peers;
    return;
}

sub _add_auths {
    my ($self) = @_;
    my $ircd = $self->{ircd};
    my $auths = $self->{cfg}{auths};
    return if !defined $auths;
    $ircd->add_auth(%$_) for @$auths;
    return;
}

sub _add_listeners {
    my ($self) = @_;
    my $ircd = $self->{ircd};
    my $listeners = $self->{cfg}{listeners};
    return if !defined $listeners;
    $ircd->yield('add_listener', %$_) for @$listeners;
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
    my ($self, $args, $event) = @_;

    if (!defined $event) {
        $event = (caller(1))[3];
        $event =~ s/.*:://;
    }

    my @output;
    for my $i (0..$#{ $args }) {
        push @output, "ARG$i: " . _dump($args->[$i]);
    }
    $self->_status('debug', "$event: ".join(', ', @output));
    return;
}

# we handle plugin status messages here because the status plugin won't
# see these for previously added plugins or plugin_del for itself, etc
sub ircd_plugin_add {
    my ($self, $alias) = @_[OBJECT, ARG0];
    $self->_event_debug([@_[ARG0..$#_]], 'IRCD_plugin_add') if $self->{trace};
    $self->_status('normal', "Added plugin $alias");
    return;
}

sub ircd_plugin_del {
    my ($self, $alias) = @_[OBJECT, ARG0];
    $self->_event_debug([@_[ARG0..$#_]], 'IRCD_plugin_del') if $self->{trace};
    $self->_status('normal', "Deleted plugin $alias");
    return;
}

sub ircd_plugin_error {
    my ($self, $error) = @_[OBJECT, ARG0];
    $self->_event_debug([@_[ARG0..$#_]], 'IRCD_plugin_error') if $self->{trace};
    $self->_status('error', $error);
    return;
}

sub ircd_plugin_status {
    my ($self, $plugin, $type, $status) = @_[OBJECT, ARG0..ARG2];
    my $ircd       = $_[SENDER]->get_heap();
    my $plugins    = $ircd->plugin_list();
    my %plug2alias = map { $plugins->{$_} => $_ } keys %$plugins;

    if (ref $plugin ne 'App::Pocosi::Status') {
        $status = "[$plug2alias{$plugin}] $status";
    }
    $self->_status($type, $status);
    return;
}

sub ircd_shutdown {
    my ($self) = $_[OBJECT];
    $self->_event_debug([@_[ARG0..$#_]], 'IRCD_shutdown') if $self->{trace};
    $self->_status('normal', 'IRCd component shut down');
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
    my ($self, $type, $message) = @_;

    my $stamp = strftime('%Y-%m-%d %H:%M:%S', localtime);
    if (defined $type && $type eq 'error') {
        $message = "!!! $message";
    }

    my $log_line = "$stamp $message";
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

sub sig_die {
    my ($kernel, $self, $ex) = @_[KERNEL, OBJECT, ARG1];
    $kernel->sig_handled();

    chomp $ex->{error_str};
    my $error = "Event $ex->{event} in session ".$ex->{dest_session}->ID
        ." raised exception:\n    $ex->{error_str}";

    $self->_status('error', $error);
    $self->shutdown('Exiting due to an exception') if !$self->{shutdown};
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
    return if $self->{shutdown};
    $self->_status('normal', $reason);
    $self->{ircd}->shutdown() if $self->{ircd};
    $self->{shutdown} = 1;
    return;
}

1;

=encoding utf8

=head1 NAME

App::Pocosi - A command line tool for launching a POE::Component::Server::IRC instance

=head1 DESCRIPTION

This distribution provides a generic way to launch a
L<POE::Component::Server::IRC|POE::Component::Server::IRC> instance.

=over 4

=item * Prints useful status information (to your terminal and/or a log file)

=item * Will daemonize if you so wish

=item * Supports a configuration file

=item * Offers a user friendly way to pass arguments to POE::Component::Server::IRC

=item * Has an interactive mode where you can issue issue commands and
call methods on the IRCd component.

=back

=head1 CONFIGURATION

 class:    POE::Component::Server::IRC
 log_file: /my/log.file
 pid_file: /my/pid.file
 lib:      /my/modules
 flood:    false
 auth:     true

 config:
   servername: myserver.com
   motd:
     - "Welcome to this great server"
     - ""
     - "Enjoy your stay"

 plugins:
   - [OperServ]

 listeners:
   - bindaddr: "127.0.0.1"
     port:     10023

 denials:
   - ["12.34.56.0/24", "I don't like this IP block"]

 exemptions:
   - "12.34.56.78"

 operators:
   - username: jack
     password: foo
     ipmask:   ["127.0.0.1", "1.2.3.4", "192.168.1.0/24"]
   - username: locke
     password: bar
     ipmask:   "10.0.0.*"

 auths:
   - mask:     "*@example.com"
     password: hlagh
     spoof:    jacob
     no_tilde: true

 peers:
   - name:     otherserver.com
     rpass:    hlaghpass
     pass:     hlaghpass
     type:     r
     raddress: "127.0.0.1"
     rport:    12345
     auto:     true

The configuration file is in L<YAML|YAML> or L<JSON|JSON> format. It consists
of a hash containing the options described in the above code example. Only
C<config> is required.

=head2 C<lib>

Either the name of a directory containing Perl modules (e.g. plugins), or an
array of such names. Kind of like Perl's I<-I>.

=head2 C<pid_file>

Path to a pid file, as used by most daemons. If is specified, App::Pocosi
will refuse to run if the file already exists.

=head2 C<log_file>

Path to a log file to which status messages will be written.

=head2 C<class>

The IRC server component class. Defaults to
L<POE::Component::Server::IRC::State|POE::Component::Server::IRC::State>.

=head2 C<config>

This is a hash of various configuration variables for the IRCd. See
PoCo-Server-IRC's L<C<configure>|POE::Component::Server::IRC/configure>
for a list of parameters.

=head2 C<plugins>

An array of arrays containing a short plugin class name (e.g. 'OperServ')
and optionally a hash of arguments to that plugin. When figuring out the
correct package name, App::Pocosi will first try to load
POE::Component::Server::IRC::Plugin::I<YourPlugin> before trying to load
I<YourPlugin>.

=head2 C<listeners>

An array of hashes. The keys should be any of the options listed in the docs
for PoCo-Server-IRC-Backend's
L<C<add_listener>|POE::Component::Server::IRC::Backend/add_listener> method.

=head2 C<auths>

An array of hashes. The keys are described in the docs for PoCo-Server-IRC's
L<C<add_auth>|POE::Component::Server::IRC/add_auth> method.

=head2 C<operators>

An array of hashes. The keys are described in the docs for PoCo-Server-IRC's
L<C<add_operator>|POE::Component::Server::IRC/add_operator> method. You
you can supply an array of netmasks (the kind accepted by
L<Net::Netmask|Net::Netmask>'s constructor) for the B<'ipmask'> key.

=head2 C<peers>

An array of hashes. The keys should be any of the options listed in the docs
for PoCo-Server-IRC's
L<C<add_peer>|POE::Component::Server::IRC/add_listener> method.

=head2 C<denials>

An array of arrays. The first element of the inner array should be a netmask
accepted by L<Net::Netmask|Net::Netmask>'s constructor. The second
(optional) element should be a reason for the denial.

=head2 C<exemptions>

An array of netmasks (the kind which L<Net::Netmask|Net::Netmask>'s
constructor accepts).

=head1 OUTPUT

Here is some example output from the program:

 $ pocosi -f example/config.yml
 2011-05-22 15:30:02 Started (pid 13191)
 2011-05-22 15:30:02 Constructing plugins
 2011-05-22 15:30:02 Spawning IRCd component (POE::Component::Server::IRC)
 2011-05-22 15:30:02 Registering plugins
 2011-05-22 15:30:02 Added plugin PocosiStatus_1
 2011-05-22 15:30:02 Added plugin OperServ_1
 2011-05-22 15:30:02 Started listening on 127.0.0.1:10023
 2011-05-22 15:30:02 Connected to peer otherserver.com on 127.0.0.1:12345
 2011-05-22 15:30:02 Server otherserver.com (hops: 1) introduced to the network by myserver.com
 ^C2011-05-22 15:30:18 Exiting due to SIGINT
 2011-05-22 15:30:18 Deleted plugin OperServ_1
 2011-05-22 15:30:18 Deleted plugin PocosiStatus_1
 2011-05-22 15:30:18 IRCd component shut down

=head1 AUTHOR

Hinrik E<Ouml>rn SigurE<eth>sson, hinrik.sig@gmail.com

=head1 LICENSE AND COPYRIGHT

Copyright 2011 Hinrik E<Ouml>rn SigurE<eth>sson

This program is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
