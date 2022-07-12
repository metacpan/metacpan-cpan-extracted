#!/usr/bin/perl
# Media HTTP File Server

# load this conditionally as it will faile if syscall.ph doesn't exist
BEGIN {
use constant HAS_EventLoop_Poll_Linux_Timer => eval {
package MHFS::EventLoop::Poll::Linux::Timer {
    use strict; use warnings;
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use POSIX qw/floor/;
    use Devel::Peek;
    use feature 'say';
    use constant {
        _clock_REALTIME  => 0,
        _clock_MONOTONIC => 1,
        _clock_BOOTTIME  => 7,
        _clock_REALTIME_ALARM => 8,
        _clock_BOOTTIME_ALARM => 9,

        _ENOTTY => 25,  #constant for Linux?
    };
    # x86_64 numbers
    require 'syscall.ph';

    my $TFD_CLOEXEC = 0x80000;
    my $TFD_NONBLOCK = 0x800;

    sub new {
        my ($class, $evp) = @_;
        my $timerfd = syscall(SYS_timerfd_create(), _clock_MONOTONIC, $TFD_NONBLOCK | $TFD_CLOEXEC);
        $timerfd != -1 or die("failed to create timerfd: $!");
        my $timerhandle = IO::Handle->new_from_fd($timerfd, "r");
        $timerhandle or die("failed to turn timerfd into a file handle");
        my %self = ('timerfd' => $timerfd, 'timerhandle' => $timerhandle);
        bless \%self, $class;

        $evp->set($self{'timerhandle'}, \%self, POLLIN);
        $self{'evp'} = $evp;
        return \%self;
    }

    sub packitimerspec {
       my ($times) = @_;
       my $it_interval_sec  = int($times->{'it_interval'});
       my $it_interval_nsec = floor(($times->{'it_interval'} - $it_interval_sec) * 1000000000);
       my $it_value_sec = int($times->{'it_value'});
       my $it_value_nsec = floor(($times->{'it_value'} - $it_value_sec) * 1000000000);
       #say "packing $it_interval_sec, $it_interval_nsec, $it_value_sec, $it_value_nsec";
       return pack 'qqqq', $it_interval_sec, $it_interval_nsec, $it_value_sec, $it_value_nsec;
   }

    sub settime_linux {
        my ($self, $start, $interval) = @_;
        # assume start 0 is supposed to run immediately not try to cancel a timer
        $start = ($start > 0.000000001) ? $start : 0.000000001;
        my $new_value = packitimerspec({'it_interval' => $interval, 'it_value' => $start});
        my $settime_success = syscall(SYS_timerfd_settime(), $self->{'timerfd'}, 0, $new_value,0);
        ($settime_success == 0) or die("timerfd_settime failed: $!");
    }

    sub onReadReady {
        my ($self) = @_;
        my $nread;
        my $buf;
        while($nread = sysread($self->{'timerhandle'}, $buf, 8)) {
            if($nread < 8) {
                say "timer hit, ignoring $nread bytes";
                next;
            }
            my $expirations = unpack 'Q', $buf;
            say "Linux::Timer there were $expirations expirations";
        }
        if(! defined $nread) {
            if( ! $!{EAGAIN}) {
                say "sysread failed with $!";
            }

        }
        $self->{'evp'}->check_timers;
        return 1;
    };
1;
}  # package
}; # eval
}; # BEGIN

# You must provide event handlers for the events you are listening for
# return undef to have them removed from poll's structures
package MHFS::EventLoop::Poll::Base {
    use strict; use warnings;
    use feature 'say';
    use POSIX ":sys_wait_h";
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
    use Scalar::Util qw(looks_like_number);
    use Data::Dumper;
    use Devel::Peek;
    #use Devel::Refcount qw( refcount );

    use constant POLLRDHUP => 0;
    use constant ALWAYSMASK => (POLLRDHUP | POLLHUP);

    sub new {
        my ($class) = @_;
        my %self = ('poll' => IO::Poll->new(), 'fh_map' => {}, 'timers' => [], 'children' => {}, 'deadchildren' => []);
        bless \%self, $class;

        $SIG{CHLD} = sub {
            while((my $child = waitpid(-1, WNOHANG)) > 0) {
                my ($wstatus, $exitcode) = ($?, $?>> 8);
                if(defined $self{'children'}{$child}) {
                    say "PID $child reaped (func) $exitcode";
                    push @{$self{'deadchildren'}}, [$self{'children'}{$child}, $child, $exitcode];
                    $self{'children'}{$child} = undef;
                }
                else {
                    say "PID $child reaped (No func) $exitcode";
                }
            }
        };

        return \%self;
    }

    sub register_child {
        my ($self, $pid, $cb) = @_;
        $self->{'children'}{$pid} = $cb;
    }

    sub run_dead_children_callbacks {
        my ($self) = @_;
        while(my $chld = shift(@{$self->{'deadchildren'}})) {
            say "PID " . $chld->[1] . ' running SIGCHLD cb';
            $chld->[0]($chld->[2]);
        }
    }

    sub set {
        my ($self, $handle, $obj, $events) = @_;
        $self->{'poll'}->mask($handle, $events);
        $self->{'fh_map'}{$handle} = $obj;
    }

    sub getEvents {
        my ($self, $handle) = @_;
        return $self->{'poll'}->mask($handle);
    }

    sub remove {
        my ($self, $handle) = @_;
        $self->{'poll'}->remove($handle);
        $self->{'fh_map'}{$handle} = undef;
    }


   sub _insert_timer {
       my ($self, $timer) = @_;
       my $i;
       for($i = 0; defined($self->{'timers'}[$i]) && ($timer->{'desired'} >= $self->{'timers'}[$i]{'desired'}); $i++) { }
       splice @{$self->{'timers'}}, $i, 0, ($timer);
       return $i;
   }


    # all times are relative, is 0 is set as the interval, it will be run every main loop iteration
    # return undef in the callback to delete the timer
    sub add_timer {
        my ($self, $start, $interval, $callback, $id) = @_;
        my $current_time = clock_gettime(CLOCK_MONOTONIC);
        my $desired = $current_time + $start;
        my $timer = { 'desired' => $desired, 'interval' => $interval, 'callback' => $callback };
        $timer->{'id'} = $id if(defined $id);
        return _insert_timer($self, $timer);
    }

    sub remove_timer_by_id {
        my ($self, $id) = @_;
        my $lastindex = scalar(@{$self->{'timers'}}) - 1;
        for my $i (0 .. $lastindex) {
            next if(! defined $self->{'timers'}[$i]{'id'});
            if($self->{'timers'}[$i]{'id'} == $id) {
                #say "Removing timer with id: $id";
                splice(@{$self->{'timers'}}, $i, 1);
                return;
            }
        }
        say "unable to remove timer $id, not found";
    }

    sub requeue_timers {
        my ($self, $timers, $current_time) = @_;
        foreach my $timer (@$timers) {
            $timer->{'desired'} = $current_time + $timer->{'interval'};
            _insert_timer($self, $timer);
        }
    }

    sub check_timers {
        my ($self) = @_;
        my @requeue_timers;
        my $timerhit = 0;
        my $current_time =  clock_gettime(CLOCK_MONOTONIC);
        while(my $timer = shift (@{$self->{'timers'}})  ) {
            if($current_time >= $timer->{'desired'}) {
                $timerhit = 1;
                if(defined $timer->{'callback'}->($timer, $current_time, $self)) { # callback may change interval
                    push @requeue_timers, $timer;
                }
            }
            else {
                unshift @{$self->{'timers'}}, $timer;
                last;
            }
        }
        $self->requeue_timers(\@requeue_timers, $current_time);
    }

    sub do_poll {
        my ($self, $loop_interval, $poll) = @_;
        my $pollret = $poll->poll($loop_interval);
        if($pollret > 0){
            foreach my $handle ($poll->handles()) {
                my $revents = $poll->events($handle);
                my $obj = $self->{'fh_map'}{$handle};
                if($revents & POLLIN) {
                    #say "read Ready " .$$;
                    if(! defined($obj->onReadReady)) {
                        $self->remove($handle);
                        say "poll has " . scalar ( $self->{'poll'}->handles) . " handles";
                        next;
                    }
                }

                if($revents & POLLOUT) {
                    #say "writeReady";
                    if(! defined($obj->onWriteReady)) {
                        $self->remove($handle);
                         say "poll has " . scalar ( $self->{'poll'}->handles) . " handles";
                        next;
                    }
                }

                if($revents & (POLLHUP | POLLRDHUP )) {
                    say "Hangup $handle, before ". scalar ( $self->{'poll'}->handles);
                    $obj->onHangUp();
                    $self->remove($handle);
                    say "poll has " . scalar ( $self->{'poll'}->handles) . " handles";
                }
            }

        }
        elsif($pollret == 0) {
            #say "pollret == 0";
        }
        elsif(! $!{EINTR}){
            say "Poll ERROR $!";
            #return undef;
        }

        $self->run_dead_children_callbacks;
    }

    sub run {
        my ($self, $loop_interval) = @_;
        my $default_lp_interval = $loop_interval // -1;
        my $poll = $self->{'poll'};
        for(;;)
        {
            check_timers($self);
            print "do_poll $$";
            if($self->{'timers'}) {
                say " timers " . scalar(@{$self->{'timers'}}) . ' handles ' . scalar($self->{'poll'}->handles());
            }
            else {
                print "\n";
            }
            # we don't need to expire until a timer is expiring
            if(@{$self->{'timers'}}) {
                $loop_interval = $self->{'timers'}[0]{'desired'} - clock_gettime(CLOCK_MONOTONIC);
            }
            else {
                $loop_interval = $default_lp_interval;
            }
            do_poll($self, $loop_interval, $poll);
        }
    }

    1;
}

package MHFS::EventLoop::Poll::Linux {
    use strict; use warnings;
    use feature 'say';
    use parent -norequire, 'MHFS::EventLoop::Poll::Base';
    sub new {
        my $class = shift;
        my $self = $class->SUPER::new(@_);
        $self->{'evp_timer'} = MHFS::EventLoop::Poll::Linux::Timer->new($self);
        return $self;
    };

    sub add_timer {
        my ($self, $start) = @_;
        shift @_;
        if($self->SUPER::add_timer(@_) == 0) {
            say __PACKAGE__.": add_timer, updating linux timer to $start";
            $self->{'evp_timer'}->settime_linux($start, 0);
        }
    };

    sub requeue_timers {
        my $self = shift @_;
        $self->SUPER::requeue_timers(@_);
        my ($timers, $current_time) = @_;
        if(@{$self->{'timers'}}) {
            my $start = $self->{'timers'}[0]{'desired'} - $current_time;
            say __PACKAGE__.": requeue_timers, updating linux timer to $start";
            $self->{'evp_timer'}->settime_linux($start, 0);
        }
    };

    sub run {
        my ($self, $loop_interval) = @_;
        $loop_interval //= -1;
        my $poll = $self->{'poll'};
        for(;;)
        {
            print __PACKAGE__.": do_poll LINUX_X86_64 $$";
            if($self->{'timers'}) {
                say " timers " . scalar(@{$self->{'timers'}}) . ' handles ' . scalar($self->{'poll'}->handles());
            }
            else {
                print "\n";
            }

            $self->SUPER::do_poll($loop_interval, $poll);
        }
    };
    1;
}

package MHFS::EventLoop::Poll {
    use strict; use warnings;
    use feature 'say';
    BEGIN {
    use Config;
    my $isLoaded;
    if(index($Config{archname}, 'x86_64-linux') != -1) {
        if(! main::HAS_EventLoop_Poll_Linux_Timer) {
            warn "MHFS::EventLoop::Poll: Failed to load MHFS::EventLoop::Poll::Linux::Timer NOT enabling timerfd support!";
        }
        else {
            warn "MHFS::EventLoop::Poll: enabling timerfd support";
            $isLoaded = 1;
            eval "use parent -norequire, 'MHFS::EventLoop::Poll::Linux'";
        }
    }
    else {
        warn "MHFS::EventLoop::Poll no timerfd support for ".$Config{archname};
    }
    if(! $isLoaded) {
        eval "use parent -norequire, 'MHFS::EventLoop::Poll::Base'";
    }
    }
1;
}

package MHFS::HTTP::Server {
    use strict; use warnings;
    use feature 'say';
    use IO::Socket::INET;
    use Socket qw(IPPROTO_TCP TCP_KEEPALIVE TCP_NODELAY);
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Scalar::Util qw(weaken);
    use File::Path qw(make_path);
    use Data::Dumper;
    use Config;

    MHFS::Util->import();

    sub new {
        my ($class, $launchsettings, $plugins, $routes) = @_;

        $SIG{PIPE} = sub {
            print STDERR "SIGPIPE @_\n";
        };

        binmode(STDOUT, ":utf8");
        binmode(STDERR, ":utf8");

        # load settings
        say __PACKAGE__.": loading settings";
        my $settings = MHFS::Settings::load($launchsettings);
        if((exists $settings->{'flush'}) && ($settings->{'flush'})) {
            say __PACKAGE__.": setting autoflush on STDOUT and STDERR";
            STDOUT->autoflush(1);
            STDERR->autoflush(1);
        }

        # make the temp dirs
        make_path($settings->{'VIDEO_TMPDIR'}, $settings->{'MUSIC_TMPDIR'}, $settings->{'RUNTIME_DIR'}, $settings->{'GENERIC_TMPDIR'});
        make_path($settings->{'SECRET_TMPDIR'}, {chmod => 0600});
        make_path($settings->{'DATADIR'}, $settings->{'MHFS_TRACKER_TORRENT_DIR'});

        my $sock = IO::Socket::INET->new(Listen => 10000, LocalAddr => $settings->{'HOST'}, LocalPort => $settings->{'PORT'}, Proto => 'tcp', Reuse => 1, Blocking => 0);
        if(! $sock) {
            say "server: Cannot create self socket";
            return undef;
        }

        if(! $sock->setsockopt( SOL_SOCKET, SO_KEEPALIVE, 1)) {
            say "server: cannot setsockopt";
            return undef;
        }
        my $TCP_KEEPIDLE  = 4;
        my $TCP_KEEPINTVL   = 5;
        my $TCP_KEEPCNT   = 6;
        my $TCP_USER_TIMEOUT = 18;
        #$SERVER->setsockopt(IPPROTO_TCP, $TCP_KEEPIDLE, 1) or die;
        #$SERVER->setsockopt(IPPROTO_TCP, $TCP_KEEPINTVL, 1) or die;
        #$SERVER->setsockopt(IPPROTO_TCP, $TCP_KEEPCNT, 10) or die;
        #$SERVER->setsockopt(IPPROTO_TCP, $TCP_USER_TIMEOUT, 10000) or die; #doesn't work?
        #$SERVER->setsockopt(SOL_SOCKET, SO_LINGER, pack("II",1,0)) or die; #to stop last ack

        # leaving Nagle's algorithm enabled for now as sometimes headers are sent without data
        #$sock->setsockopt(IPPROTO_TCP, TCP_NODELAY, 1) or die("Failed to set TCP_NODELAY");

        # linux specific settings. Check in BEGIN?
        if(index($Config{osname}, 'linux') != -1) {
            use Socket qw(TCP_QUICKACK);
            $sock->setsockopt(IPPROTO_TCP, TCP_QUICKACK, 1) or die("Failed to set TCP_QUICKACK");
        }
        my $evp = MHFS::EventLoop::Poll->new;
        my %self = ( 'settings' => $settings, 'routes' => $routes, 'route_default' => sub { $_[0]->SendDirectory($settings->{'DOCUMENTROOT'}); }, 'plugins' => $plugins, 'sock' => $sock, 'evp' => $evp, 'uploaders' => [], 'sesh' =>
        { 'newindex' => 0, 'sessions' => {}}, 'resources' => {}, 'loaded_plugins' => {});
        bless \%self, $class;

        $evp->set($sock, \%self, POLLIN);

        my $fs = MHFS::FS->new($settings->{'SOURCES'});
        if(! $fs) {
            say "failed to open MHFS::FS";
            return undef;
        }
        $self{'fs'} = $fs;

        # load the plugins
        foreach my $pluginname (@{$plugins}) {

            next if(defined $settings->{$pluginname}{'enabled'} && (!$settings->{$pluginname}{'enabled'}));
            my $plugin = $pluginname->new($settings, \%self);
            next if(! $plugin);

            foreach my $timer (@{$plugin->{'timers'}}) {
                say __PACKAGE__.': adding '.ref($plugin).' timer';
                $self{'evp'}->add_timer(@{$timer});
            }
            if(my $func = $plugin->{'uploader'}) {
                say __PACKAGE__.': adding '. ref($plugin) .' uploader';
                push (@{$self{'uploaders'}}, $func);
            }
            foreach my $route (@{$plugin->{'routes'}}) {
                say __PACKAGE__.': adding ' . ref($plugin) . ' route ' . $route->[0];
                push @{$self{'routes'}}, $route;
            }
            $plugin->{'server'} = \%self;
            $self{'loaded_plugins'}{$pluginname} = $plugin;
        }

        $evp->run();

        return \%self;
    }

    sub GetResource {
        my ($self, $filename) = @_;
        $self->{'resources'}{$filename} //= MHFS::Util::read_file($filename);
        return \$self->{'resources'}{$filename};
    }

    sub onReadReady {
        my ($server) = @_;
        # accept the connection
        my $csock = $server->{'sock'}->accept();
        if(! $csock) {
            say "server: cannot accept client";
            return 1;
        }

        # gather connection details and verify client host is acceptable
        my $peerhost = $csock->peerhost();
        if(! $peerhost) {
            say "server: no peerhost";
            return 1;
        }
        my $peerip = MHFS::Util::ParseIPv4($peerhost);
        if(! defined $peerip) {
            say "server: error parsing ip";
            return 1;
        }
        my $ah;
        foreach my $allowedHost (@{$server->{'settings'}{'ARIPHOSTS_PARSED'}}) {
            if(($peerip & $allowedHost->{'subnetmask'}) == $allowedHost->{'ip'}) {
                $ah = $allowedHost;
                last;
            }
        }
        if(!$ah) {
            say "server: $peerhost not allowed";
            return 1;
        }
        my $peerport = $csock->peerport();
        if(! $peerport) {
            say "server: no peerport";
            return 1;
        }

        # finally create the client
        say "-------------------------------------------------";
        say "NEW CONN " . $peerhost . ':' . $peerport;
        my $cref = MHFS::HTTP::Server::Client->new($csock, $server, $ah, $peerip);
        return 1;
    }

    1;
}

package MHFS::Util {
    use strict; use warnings;
    use feature 'say';
    use Exporter 'import';
    use File::Find;
    use File::Basename;
    use POSIX ();
    use Cwd qw(abs_path getcwd);
    use Encode qw(decode encode);
    use URI::Escape qw(uri_escape);
    our @EXPORT = ('LOCK_GET_LOCKDATA', 'LOCK_WRITE', 'UNLOCK_WRITE', 'write_file', 'read_file', 'shellcmd_unlock', 'ASYNC', 'FindFile', 'space2us', 'escape_html', 'function_exists', 'shell_escape', 'pid_running', 'escape_html_noquote', 'output_dir_versatile', 'do_multiples', 'getMIME', 'get_printable_utf8', 'small_url_encode', 'uri_escape_path', 'round', 'ceil_div', 'get_SI_size');
    # single threaded locks
    sub LOCK_GET_LOCKDATA {
        my ($filename) = @_;
        my $lockname = "$filename.lock";
        my $bytes = read_file($lockname);
        if(! defined $bytes) {
            return undef;
        }
        return $bytes;
    }

    #sub LOCK_GET_FILESIZE {
    #    my ($filename) = @_;
    #    my $lockedfilesize = LOCK_GET_LOCKDATA($filename);
    #    if(defined $lockedfilesize) {
    #
    #    }
    #}

    sub LOCK_WRITE {
        my ($filename, $lockdata) = @_;
        my $lockname = "$filename.lock";
        if(-e $lockname) {
            return 0;
        }
        $lockdata //= "99999999999"; #99 Billion
        write_file($lockname, $lockdata);
        return 1;
    }

    sub UNLOCK_WRITE {
        my ($filename) = @_;
        my $lockname = "$filename.lock";
        unlink($lockname);
    }

    sub write_file {
        my ($filename, $text) = @_;
        open (my $fh, '>', $filename) or die("$! $filename");
        print $fh $text;
        close($fh);
    }


    sub read_file {
        my ($filename) = @_;
        return do {
            local $/ = undef;
            if(!(open my $fh, "<", $filename)) {
                #say "could not open $filename: $!";
                return undef;
            }
            else {
                <$fh>;
            }
        };
    }

    # This is not fast
    sub FindFile {
        my ($directories, $name_req, $path_req) = @_;
        my $curdir = getcwd();
        my $foundpath;
        eval {
            my $dir_matches = 1;
            my %options = ('wanted' => sub {
                return if(! $dir_matches);
                if(/$name_req/i) {
                    return if( -d );
                    $foundpath = $File::Find::name;
                    die;
                }
            });

            if(defined $path_req) {
                $options{'preprocess'} = sub {
                    $dir_matches = ($File::Find::dir =~ /$path_req/i);
                    return @_;
                };
            }


            find(\%options, @$directories);
        };
        chdir($curdir);
        return $foundpath;
    }

    sub shellcmd_unlock {
        my ($command_arr, $fullpath) = @_;
        system @$command_arr;
        UNLOCK_WRITE($fullpath);
    }

    sub ASYNC {
        my $func = shift;
        my $pid = fork();
        if($pid == 0) {
            $func->(@_);
            #exit 0;
            POSIX::_exit(0);
        }
        else {
            say "PID $pid ASYNC";
            return $pid;
        }
    }

    sub space2us {
        my ($string) = @_;
        $string =~ s/\s/_/g;
        return $string;
    }
    sub escape_html {
        my ($string) = @_;
        my %dangerchars = ( '"' => '&quot;', "'" => '&#x27;', '<' => '&lt;', '>' => '&gt;', '/' => '&#x2F;');
        $string =~ s/&/&amp;/g;
        foreach my $key(keys %dangerchars) {
            my $val = $dangerchars{$key};
            $string =~ s/$key/$val/g;
        }
        return \$string;
    }

    sub escape_html_noquote {
        my ($string) = @_;
        my %dangerchars = ('<' => '&lt;', '>' => '&gt;');
        $string =~ s/&/&amp;/g;
        foreach my $key(keys %dangerchars) {
            my $val = $dangerchars{$key};
            $string =~ s/$key/$val/g;
        }
        return \$string;
    }

    sub function_exists {
        no strict 'refs';
        my $funcname = shift;
        return \&{$funcname} if defined &{$funcname};
        return;
    }

    sub pid_running {
        return kill 0, shift;
    }

    sub shell_escape {
        my ($cmd) = @_;
        ($cmd) =~ s/'/'"'"'/g;
        return $cmd;
    }

    sub output_dir_versatile {
        my ($path, $options) = @_;
        # hide the root path if desired
        my $root = $options->{'root'};
        $options->{'min_file_size'} //= 0;

        my @files;
        ON_DIR:
        # get the list of files and sort
        my $dir;
        if(! opendir($dir, $path)) {
            warn "outputdir: Cannot open directory: $path $!";
            return;
        }
        my @newfiles = sort { uc($a) cmp uc($b)} (readdir $dir);
        closedir($dir);
        my @newpaths = ();
        foreach my $file (@newfiles) {
            next if($file =~ /^..?$/);
            push @newpaths,  "$path/$file";
        }
        @files = @files ? (@newpaths, undef, @files) : @newpaths;
        while(@files)
        {
            $path = shift @files;
            if(! defined $path) {
                $options->{'on_dir_end'}->() if($options->{'on_dir_end'});
                next;
            }
            my $file = basename($path);
            if(-d $path) {
                $options->{'on_dir_start'}->($path, $file) if($options->{'on_dir_start'});
                goto ON_DIR;
            }

            my $unsafePath = $path;
            if($root) {
                $unsafePath =~ s/^$root(\/)?//;
            }
            my $size = -s $path;
            if(! defined $size) {
                say "size not defined path $path file $file";
                next;
            }
            next if( $size < $options->{'min_file_size'});
            $options->{'on_file'}->($path, $unsafePath, $file) if($options->{'on_file'});
        }
        return;
    }

    # perform multiple async actions at the same time.
    # continue on with $result_func on failure or completion of all actions
    sub do_multiples {
        my ($multiples, $result_func) = @_;
        my %data;
        my @mkeys = keys %{$multiples};
        foreach my $multiple (@mkeys) {
            my $multiple_cb = sub {
                my ($res) = @_;
                $data{$multiple} = $res;
                # return failure if this multiple failed
                if(! defined $data{$multiple}) {
                    $result_func->(undef);
                    return;
                }
                # yield if not all the results in
                foreach my $m2 (@mkeys) {
                    return if(! defined $data{$m2});
                }
                # all results in we can continue
                $result_func->(\%data);
            };
            say "launching multiple key: $multiple";
            $multiples->{$multiple}->($multiple_cb);
        }
    }

    sub getMIME {
        my ($filename) = @_;

        my %combined = (
            # audio
            'mp3' => 'audio/mp3',
            'flac' => 'audio/flac',
            'opus' => 'audio',
            'ogg'  => 'audio/ogg',
            'wav'  => 'audio/wav',
            # video
            'mp4' => 'video/mp4',
            'ts'   => 'video/mp2t',
            'mkv'  => 'video/x-matroska',
            'webm' => 'video/webm',
            'flv'  => 'video/x-flv',
            # media
            'mpd' => 'application/dash+xml',
            'm3u8' => 'application/x-mpegURL',
            'm3u8_v' => 'application/x-mpegURL',
            # text
            'html' => 'text/html; charset=utf-8',
            'json' => 'application/json',
            'js'   => 'application/javascript',
            'txt' => 'text/plain',
            'css' => 'text/css',
            # images
            'jpg' => 'image/jpeg',
            'jpeg' => 'image/jpeg',
            'png' => 'image/png',
            'gif' => 'image/gif',
            'bmp' => 'image/bmp',
            # binary
            'pdf' => 'application/pdf',
            'tar' => 'application/x-tar',
            'wasm'  => 'application/wasm',
            'bin' => 'application/octet-stream'
        );

        my ($ext) = $filename =~ /\.([^.]+)$/;

        # default to binary
        return $combined{$ext} // $combined{'bin'};
    }

    sub ParseIPv4 {
        my ($ipstring) = @_;
        my @values = $ipstring =~ /^(\d{1,3})\.(\d{1,3})\.(\d{1,3})\.(\d{1,3})$/;
        if(scalar(@values) != 4) {
            return undef;
        }
        foreach my $i (0..3) {
            ($values[$i] <= 255) or return undef;
        }
        return ($values[0] << 24) | ($values[1] << 16) | ($values[2] << 8) | ($values[3]);
    }

    sub surrogatepairtochar {
        my ($hi, $low) = @_;
        my $codepoint = 0x10000 + (ord($hi) - 0xD800) * 0x400 + (ord($low) - 0xDC00);
        return pack('U', $codepoint);
    }

    sub surrogatecodepointpairtochar {
        my ($hi, $low) = @_;
        my $codepoint = 0x10000 + ($hi - 0xD800) * 0x400 + ($low - 0xDC00);
        return pack('U', $codepoint);
    }

    # returns the byte length and the codepoint
    sub peek_utf8_codepoint {
        my ($octets) = @_;
        my @rules = (
            [0xE0, 0xC0, 2], # 2 byte sequence
            [0xF0, 0xE0, 3], # 3 byte sequence
            [0XF8, 0xF0, 4]  # 4 byte sequence
        );

        length($$octets) >= 1 or return undef;
        my $byte = substr($$octets, 0, 1);
        my $byteval = ord($byte);
        my $charlen = 1;
        foreach my $rule (@rules) {
            if(($byteval & $rule->[0]) == $rule->[1]) {
                $charlen = $rule->[2];
                last;
            }
        }
        length($octets) >= $charlen or return undef;
        my $char = decode("utf8", substr($$octets, 0, $charlen));
        if(length($char) > 1) {
            return {'codepoint' => 0xFFFD, 'bytelength' => 1};
        }
        return { 'codepoint' => ord($char), 'bytelength' => $charlen};
    }

    sub get_printable_utf8 {
        my ($octets) = @_;

        #my $cp = ((0xF0 & 0x07) << 18) | ((0x9F & 0x3F) << 12) | ((0x8E & 0x3F) << 6) | (0x84 & 0x3F);
        #say "codepoint $cp";
#
        #my @tests = (
        ##    #(chr(1 << 7) . chr(1 << 7)),
        ##    #chr(0xED).chr(0xA0).chr(0xBC),
        ##    #chr(0xED).chr(0xA0).chr(0xBC) . chr(1 << 7) . chr(1 << 7),
        ##    #chr(0xED).chr(0xED).chr(0xED),
        ##    chr(0xF0).chr(0xBF).chr(0xBF).chr(0xBF),
        ##    chr(0xED).chr(0xA0),
        ##    chr(0xF0).chr(0x9F).chr(0x8E).chr(0x84),
        ##    chr(0xF0).chr(0x9F).chr(0x8E),
        #    chr(0xF0).chr(0x9F).chr(0x8E).chr(0x84),
        #    chr(0xF0).chr(0x9F).chr(0x8E).chr(0x04),
        #    chr(0x7F),
        #    chr(0xC1).chr(0x80),
        #    chr(0xC2).chr(0x80)
        #);
##
        #foreach my $test (@tests) {
        #    my $unsafedec = decode("utf8", $test, Encode::LEAVE_SRC);
        #    my $safedec = decode('UTF-8', $test);
        #    say "udec $unsafedec len ".length($unsafedec)." sdec $safedec len ".length($safedec);
        #    say "udec codepoint ".ord($unsafedec)." sdec codepoint " . ord($safedec);
        #}
        #die;

        my $res;
        while(length($octets)) {
            $res .= decode('UTF-8', $octets, Encode::FB_QUIET);
            last if(!length($octets));

            # by default replace with the replacement char
            my $chardata = peek_utf8_codepoint(\$octets);
            my $toappend = chr(0xFFFD);
            my $toremove = $chardata->{'bytelength'};

            # if we find a surrogate pair, make the actual codepoint
            if(($chardata->{'bytelength'} == 3) && ($chardata->{'codepoint'}  >= 0xD800) && ($chardata->{'codepoint'} <= 0xDBFF)) {
                my $secondchar = peek_utf8_codepoint(\substr($octets, 3, 3));
                if($secondchar && ($secondchar->{'bytelength'} == 3) && ($secondchar->{'codepoint'}  >= 0xDC00) && ($secondchar->{'codepoint'} <= 0xDFFF)) {
                    $toappend = surrogatecodepointpairtochar($chardata->{'codepoint'}, $secondchar->{'codepoint'});
                    $toremove += 3;
                }
            }

            $res .= $toappend;
            substr($octets, 0, $toremove, '');
        }

        return $res;
    }

    # save space by not precent encoding valid UTF-8 characters
    sub small_url_encode {
        my ($octets) = @_;
        say "before $octets";

        my $escapedoctets = ${escape_html($octets)};
        my $res;
        while(length($escapedoctets)) {
            $res .= decode('UTF-8', $escapedoctets, Encode::FB_QUIET);
            last if(!length($escapedoctets));
            my $oct = ord(substr($escapedoctets, 0, 1, ''));
            $res .= sprintf ("%%%02X", $oct);
        }
        say "now: $res";
        return $res;
    }

    sub uri_escape_path {
        my ($path) = @_;
        my @components = split('/', $path);
        my @encodedcomponents = map(uri_escape($_), @components);
        return join('/', @encodedcomponents);
    }

    sub round {
        return int($_[0]+0.5);
    }

    sub ceil_div {
        return int(($_[0] + $_[1] - 1) / $_[1]);
    }

    sub get_SI_size {
        my ($bytes) = @_;
        my $mebibytes = ($bytes / 1048576);
        if($mebibytes >= 1024) {
            return  sprintf("%.2f GiB", $bytes / 1073741824);
        }
        else {
            return sprintf("%.2f MiB", $mebibytes);
        }
    }

    1;
}

package MHFS::HTTP::Server::Client::Request {
    MHFS::Util->import();
    use strict; use warnings;
    use feature 'say';
    use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
    use URI::Escape;
    use Cwd qw(abs_path getcwd);
    use File::Basename;
    use File::stat;
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Data::Dumper;
    use Scalar::Util qw(weaken);
    use List::Util qw[min max];
    use Symbol 'gensym';
    use Devel::Peek;
    use Encode qw(decode encode);
    use constant {
        MAX_REQUEST_SIZE => 8192,
    };
    use FindBin;
    use File::Spec;
    BEGIN {
        if( ! (eval "use JSON; 1")) {
            eval "use JSON::PP; 1" or die "No implementation of JSON available";
            warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
        }
    }

    # Optional dependency, Alien::Tar::Size
    BEGIN {
        use constant HAS_Alien_Tar_Size => (eval "use Alien::Tar::Size; 1");
        if(! HAS_Alien_Tar_Size) {
            warn "Alien::Tar::Size is not available";
        }
    }

    sub new {
        my ($class, $client) = @_;
        my %self = ( 'client' => $client);
        bless \%self, $class;
        weaken($self{'client'}); #don't allow Request to keep client alive
        $self{'on_read_ready'} = \&want_request_line;
        $self{'outheaders'}{'X-MHFS-CONN-ID'} = $client->{'outheaders'}{'X-MHFS-CONN-ID'};
        $self{'rl'} = 0;
        # we want the request
        $client->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
        $self{'recvrequesttimerid'} = $client->AddClientCloseTimer($client->{'server'}{'settings'}{'recvrequestimeout'}, $client->{'CONN-ID'});
        return \%self;
    }

    # on ready ready handlers
    sub want_request_line {
        my ($self) = @_;

        my $ipos = index($self->{'client'}{'inbuf'}, "\r\n");
        if($ipos != -1) {
            if(substr($self->{'client'}{'inbuf'}, 0, $ipos+2, '') =~ /^(([^\s]+)\s+([^\s]+)\s+(?:HTTP\/1\.([0-1])))\r\n/) {
                my $rl = $1;
                $self->{'method'}    = $2;
                $self->{'uri'}       = $3;
                $self->{'httpproto'} = $4;
                my $rid = int(clock_gettime(CLOCK_MONOTONIC) * rand()); # insecure uid
                $self->{'outheaders'}{'X-MHFS-REQUEST-ID'} = sprintf("%X", $rid);
                say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . " X-MHFS-REQUEST-ID: " . $self->{'outheaders'}{'X-MHFS-REQUEST-ID'};
                say "RECV: $rl";
                if(($self->{'method'} ne 'GET') && ($self->{'method'} ne 'HEAD') && ($self->{'method'} ne 'PUT')) {
                    say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . 'Invalid method: ' . $self->{'method'}. ', closing conn';
                    return undef;
                }
                my ($path, $querystring) = ($self->{'uri'} =~ /^([^\?]+)(?:\?)?(.*)$/g);
                say("raw path: $path\nraw querystring: $querystring");

                # transformations
                ## Path
                $path = uri_unescape($path);
                my %pathStruct = ( 'unescapepath' => $path );

                # collapse slashes
                $path =~ s/\/{2,}/\//g;
                say "collapsed: $path";
                $pathStruct{'unsafecollapse'} = $path;

                # without trailing slash
                if(index($pathStruct{'unsafecollapse'}, '/', length($pathStruct{'unsafecollapse'})-1) != -1) {
                    chop($path);
                    say "no slash path: $path ";
                }
                $pathStruct{'unsafepath'} = $path;

                ## Querystring
                my %qsStruct;
                # In the querystring spaces are sometimes encoded as + for legacy reasons unfortunately
                $querystring =~ s/\+/%20/g;
                my @qsPairs = split('&', $querystring);
                foreach my $pair (@qsPairs) {
                    my($key, $value) = split('=', $pair);
                    if(defined $value) {
                        if(!defined $qsStruct{$key}) {
                            $qsStruct{$key} = uri_unescape($value);
                        }
                        else {
                            if(ref($qsStruct{$key}) ne 'ARRAY') {
                                $qsStruct{$key} = [$qsStruct{$key}];
                            };
                            push @{$qsStruct{$key}}, uri_unescape($value);
                        }
                    }
                }

                $self->{'path'} = \%pathStruct;
                $self->{'qs'} = \%qsStruct;
                $self->{'on_read_ready'} = \&want_headers;
                #return want_headers($self);
                goto &want_headers;
            }
            else {
                say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' Invalid Request line, closing conn';
                return undef;
            }
        }
        elsif(length($self->{'client'}{'inbuf'}) > MAX_REQUEST_SIZE) {
            say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' No Request line, closing conn';
            return undef;
        }
        return 1;
    }

    sub want_headers {
        my ($self) = @_;
        my $ipos;
        while($ipos = index($self->{'client'}{'inbuf'}, "\r\n")) {
            if($ipos == -1) {
                if(length($self->{'client'}{'inbuf'}) > MAX_REQUEST_SIZE) {
                    say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' Headers too big, closing conn';
                    return undef;
                }
                return 1;
            }
            elsif(substr($self->{'client'}{'inbuf'}, 0, $ipos+2, '') =~ /^(([^:]+):\s*(.*))\r\n/) {
                say "RECV: $1";
                $self->{'header'}{$2} = $3;
            }
            else {
                say "X-MHFS-CONN-ID: " . $self->{'outheaders'}{'X-MHFS-CONN-ID'} . ' Invalid header, closing conn';
                return undef;
            }
        }
        # when $ipos is 0 we recieved the end of the headers: \r\n\r\n

        # verify correct host is specified when required
        if($self->{'client'}{'serverhostname'}) {
            if((! $self->{'header'}{'Host'}) ||
            ($self->{'header'}{'Host'} ne $self->{'client'}{'serverhostname'})) {
                my $printhostname = $self->{'header'}{'Host'} // '';
                say "Host: $printhostname does not match ". $self->{'client'}{'serverhostname'};
                return undef;
            }
        }

        $self->{'ip'} = $self->{'client'}{'ip'};

        # check if we're trusted (we can trust the headers such as from reverse proxy)
        my $trusted;
        if($self->{'client'}{'X-MHFS-PROXY-KEY'} && $self->{'header'}{'X-MHFS-PROXY-KEY'}) {
            $trusted = $self->{'client'}{'X-MHFS-PROXY-KEY'} eq $self->{'header'}{'X-MHFS-PROXY-KEY'};
        }
        # drops conns for naughty client's using forbidden headers
        if(!$trusted) {
            my @absolutelyforbidden = ('X-MHFS-PROXY-KEY', 'X-Forwarded-For');
            foreach my $forbidden (@absolutelyforbidden) {
                if( exists $self->{'header'}{$forbidden}) {
                    say "header $forbidden is forbidden!";
                    return undef;
                }
            }
        }
        # process reverse proxy headers
        else {
            delete $self->{'header'}{'X-MHFS-PROXY-KEY'};
            $self->{'ip'} = MHFS::Util::ParseIPv4($self->{'header'}{'X-Forwarded-For'}) if($self->{'header'}{'X-Forwarded-For'});
        }
        my $netmap = $self->{'client'}{'server'}{'settings'}{'NETMAP'};
        if($netmap && (($self->{'ip'} >> 24) == $netmap->[0])) {
            say "HACK for netmap converting to local ip";
            $self->{'ip'} = ($self->{'ip'} & 0xFFFFFF) | ($netmap->[1] << 24);
        }

        # remove the final \r\n
        substr($self->{'client'}{'inbuf'}, 0, 2, '');
        if((defined $self->{'header'}{'Range'}) &&  ($self->{'header'}{'Range'} =~ /^bytes=([0-9]+)\-([0-9]*)$/)) {
            $self->{'header'}{'_RangeStart'} = $1;
            $self->{'header'}{'_RangeEnd'} = ($2 ne  '') ? $2 : undef;
        }
        $self->{'on_read_ready'} = undef;
        $self->{'client'}->SetEvents(MHFS::EventLoop::Poll->ALWAYSMASK );
        $self->{'client'}->KillClientCloseTimer($self->{'recvrequesttimerid'});
        $self->{'recvrequesttimerid'} = undef;

        # finally handle the request
        foreach my $route (@{$self->{'client'}{'server'}{'routes'}}) {
            if($self->{'path'}{'unsafecollapse'} eq $route->[0]) {
                $route->[1]($self);
                return 1;
            }
            else {
                # wildcard ending
                next if(index($route->[0], '*', length($route->[0])-1) == -1);
                next if(rindex($self->{'path'}{'unsafecollapse'}, substr($route->[0], 0, -1), 0) != 0);
                $route->[1]($self);
                return 1;
            }
        }
        $self->{'client'}{'server'}{'route_default'}($self);
        return 1;
    }

    # unfortunately the absolute url of the server is required for stuff like m3u playlist generation
    sub getAbsoluteURL {
        my ($self) = @_;
        return $self->{'client'}{'absurl'} // (defined($self->{'header'}{'Host'}) ? 'http://'.$self->{'header'}{'Host'} : undef);
    }

    sub _ReqDataLength {
        my ($self, $datalength) = @_;
        $datalength //= 99999999999;
        my $end =  $self->{'header'}{'_RangeEnd'} // ($datalength-1);
        my $dl = $end+1;
        say "_ReqDataLength returning: $dl";
        return $dl;
    }

    sub _SendResponse {
        my ($self, $fileitem) = @_;
        if(Encode::is_utf8($fileitem->{'buf'})) {
            warn "_SendResponse: UTF8 flag is set, turning off";
            Encode::_utf8_off($fileitem->{'buf'});
        }
        if($self->{'outheaders'}{'Transfer-Encoding'} && ($self->{'outheaders'}{'Transfer-Encoding'} eq 'chunked')) {
            say "chunked response";
            $fileitem->{'is_chunked'} = 1;
        }

        $self->{'response'} = $fileitem;
        $self->{'client'}->SetEvents(POLLOUT | MHFS::EventLoop::Poll->ALWAYSMASK );
    }

    sub _SendDataItem {
        my ($self, $dataitem, $opt) = @_;
        my $size  = $opt->{'size'};
        my $code = $opt->{'code'};

        if(! $code) {
            # if start is defined it's a range request
            if(defined $self->{'header'}{'_RangeStart'}) {
                $code = 206;
            }
            else {
                $code = 200;
            }
        }

        my $contentlength;
        # range request
        if($code == 206) {
            my $start =  $self->{'header'}{'_RangeStart'};
            my $end =  $self->{'header'}{'_RangeEnd'};
            if(defined $end) {
                $contentlength = $end - $start + 1;
            }
            elsif(defined $size) {
                say 'Implicitly setting end to size';
                $end = $size - 1;
                $contentlength = $end - $start + 1;
            }
            # no end and size unknown. we have 4 choices:
            # set end to the current end (the satisfiable range on RFC 7233 2.1). Dumb clients don't attempt to request the rest of the data ...
            # send non partial response (200). This will often disable range requests.
            # send multipart. "A server MUST NOT generate a multipart response to a request for a single range"(RFC 7233 4.1) guess not

            # LIE, use a large value to signify infinite size. RFC 8673 suggests doing so when client signifies it can.
            # Current clients don't however, so lets hope they can.
            else {
                say 'Implicitly setting end to 999999999999 to signify unknown end';
                $end = 999999999999;
            }

            if($end < $start) {
                say "_SendDataItem, end < start";
                $self->Send403();
                return;
            }
            $self->{'outheaders'}{'Content-Range'} = "bytes $start-$end/" . ($size // '*');
        }
        # everybody else
        else {
            $contentlength = $size;
        }

        # if the CL isn't known we need to send chunked
        if(! defined $contentlength) {
            $self->{'outheaders'}{'Transfer-Encoding'} = 'chunked';
        }
        else {
            $self->{'outheaders'}{'Content-Length'} = "$contentlength";
        }



        my %lookup = (
            200 => "HTTP/1.1 200 OK\r\n",
            206 => "HTTP/1.1 206 Partial Content\r\n",
            301 => "HTTP/1.1 301 Moved Permanently\r\n",
            307 => "HTTP/1.1 307 Temporary Redirect\r\n",
            403 => "HTTP/1.1 403 Forbidden\r\n",
            404 => "HTTP/1.1 404 File Not Found\r\n",
            416 => "HTTP/1.1 416 Range Not Satisfiable\r\n",
            503 => "HTTP/1.1 503 Service Unavailable\r\n"
        );

        my $headtext = $lookup{$code};
        if(!$headtext) {
            say "_SendDataItem, bad code $code";
            $self->Send403();
            return;
        }
        my $mime     = $opt->{'mime'};
        $headtext .=   "Content-Type: $mime\r\n";

        my $filename = $opt->{'filename'};
        my $disposition = 'inline';
        if($opt->{'attachment'}) {
            $disposition = 'attachment';
            $filename = $opt->{'attachment'};
        }
        elsif($opt->{'inline'}) {
            $filename = $opt->{'inline'};
        }
        if($filename) {
            my $sendablebytes = encode('UTF-8', get_printable_utf8($filename));
            $headtext .=   "Content-Disposition: $disposition; filename*=UTF-8''".uri_escape($sendablebytes)."; filename=\"$sendablebytes\"\r\n";
        }

        $self->{'outheaders'}{'Accept-Ranges'} //= 'bytes';
        $self->{'outheaders'}{'Connection'} //= $self->{'header'}{'Connection'};
        $self->{'outheaders'}{'Connection'} //= 'keep-alive';

        # SharedArrayBuffer
        if($opt->{'allowSAB'}) {
            say "sending SAB headers";
            $self->{'outheaders'}{'Cross-Origin-Opener-Policy'} =  'same-origin';
            $self->{'outheaders'}{'Cross-Origin-Embedder-Policy'} = 'require-corp';
        }

        # serialize the outgoing headers
        foreach my $header (keys %{$self->{'outheaders'}}) {
            $headtext .= "$header: " . $self->{'outheaders'}{$header} . "\r\n";
        }

        $headtext .= "\r\n";
        $dataitem->{'buf'} = $headtext;

        if($dataitem->{'fh'}) {
            $dataitem->{'fh_pos'} = tell($dataitem->{'fh'});
            $dataitem->{'get_current_length'} //= sub { return undef };
        }

        $self->_SendResponse($dataitem);
    }

    sub Send403 {
        my ($self) = @_;
        my $msg = "403 Forbidden\r\n";
        $self->SendHTML($msg, {'code' => 403});
    }

    sub Send404 {
        my ($self) = @_;
        my $msg = "404 Not Found";
        $self->SendHTML($msg, {'code' => 404});
    }

    sub Send416 {
        my ($self, $cursize) = @_;
        $self->{'outheaders'}{'Content-Range'} = "*/$cursize";
        $self->SendHTML('', {'code' => 416});
    }

    sub Send503 {
        my ($self) = @_;
        $self->{'outheaders'}{'Retry-After'} = 5;
        my $msg = "503 Service Unavailable";
        $self->SendHTML($msg, {'code' => 503});
    }

    # requires already encoded url
    sub SendRedirectRawURL {
        my ($self, $code, $url) = @_;

        $self->{'outheaders'}{'Location'} = $url;
        my $msg = "UNKNOWN REDIRECT MSG";
        if($code == 301) {
            $msg = "301 Moved Permanently";
        }
        elsif($code == 307) {
            $msg = "307 Temporary Redirect";
        }
        $msg .= "\r\n<a href=\"$url\"></a>\r\n";
        $self->SendHTML($msg, {'code' => $code});
    }

    # encodes path and querystring
    # path and query string keys and values must be bytes not unicode string
    sub SendRedirect {
        my ($self, $code, $path, $qs) = @_;
        my $url;
        # encode the path component
        while(length($path)) {
            my $slash = index($path, '/');
            my $len = ($slash != -1) ? $slash : length($path);
            my $pathcomponent = substr($path, 0, $len, '');
            $url .= uri_escape($pathcomponent);
            if($slash != -1) {
                substr($path, 0, 1, '');
                $url .= '/';
            }
        }
        # encode the querystring
        if($qs) {
            $url .= '?';
            foreach my $key (keys %{$qs}) {
                my @values;
                if(ref($qs->{$key}) ne 'ARRAY') {
                    push @values, $qs->{$key};
                }
                else {
                    @values = @{$qs->{$key}};
                }
                foreach my $value (@values) {
                    $url .= uri_escape($key).'='.uri_escape($value) . '&';
                }
            }
            chop $url;
        }

        @_ = ($self, $code, $url);
        goto &SendRedirectRawURL;
    }

    sub SendLocalFile {
        my ($self, $requestfile) = @_;
        my $start =  $self->{'header'}{'_RangeStart'};
        my $client = $self->{'client'};

        # open the file and get the size
        my %fileitem = ('requestfile' => $requestfile);
        my $currentsize;
        if($self->{'method'} ne 'HEAD') {
            my $FH;
            if(! open($FH, "<", $requestfile)) {
                say "SLF: open failed";
                $self->Send404;
                return;
            }
            binmode($FH);
            my $st = stat($FH);
            if(! $st) {
                $self->Send404();
                return;
            }
            $currentsize = $st->size;
            $fileitem{'fh'} = $FH;
        }
        else {
            $currentsize = (-s $requestfile);
        }

        # seek if a start is specified
        if(defined $start) {
            if($start >= $currentsize) {
                $self->Send416($currentsize);
                return;
            }
            elsif($fileitem{'fh'}) {
                seek($fileitem{'fh'}, $start, 0);
            }
        }

        # get the maximumly possible file size. 99999999999 signfies unknown
        my $get_current_size = sub {
            return $currentsize;
        };
        my $done;
        my $ts;
        my $get_max_size = sub {
            my $locksz = LOCK_GET_LOCKDATA($requestfile);
            if($done) {
                return $ts;
            }
            if(defined($locksz)) {
                $ts = ($locksz || 0);
            }
            else {
                $done = 1;
                $ts = ($get_current_size->() || 0);
            }
        };
        my $filelength = $get_max_size->();

        # truncate to the [potentially] satisfiable end
        if(defined $self->{'header'}{'_RangeEnd'}) {
            $self->{'header'}{'_RangeEnd'} = min($filelength-1,  $self->{'header'}{'_RangeEnd'});
        }

        # setup callback for retrieving current file size if we are following the file
        if($fileitem{'fh'}) {
            if(! $done) {
                $get_current_size = sub {
                    return stat($fileitem{'fh'})
                };
            }

            my $get_read_filesize = sub {
                my $maxsize = $get_max_size->();
                if(defined $self->{'header'}{'_RangeEnd'}) {
                    my $rangesize = $self->{'header'}{'_RangeEnd'}+1;
                    return $rangesize if($rangesize <= $maxsize);
                }
                return $maxsize;
            };
            $fileitem{'get_current_length'} = $get_read_filesize;
        }

        # flag to add SharedArrayBuffer headers
        my @SABwhitelist = ('static/music_worklet_inprogress/index.html');
        my $allowSAB;
        foreach my $allowed (@SABwhitelist) {
            if(index($requestfile, $allowed, length($requestfile)-length($allowed)) != -1) {
                $allowSAB = 1;
                last;
            }
        }

        # finally build headers and send
        if($filelength == 99999999999) {
            $filelength = undef;
        }
        my $mime = getMIME($requestfile);

        my $opt = {
           'size'     => $filelength,
           'mime'     => $mime,
           'allowSAB' => $allowSAB
        };
        if($self->{'responseopt'}{'cd_file'}) {
            $opt->{$self->{'responseopt'}{'cd_file'}} = basename($requestfile);
        }

        $self->_SendDataItem(\%fileitem, $opt);
    }

    # currently only supports fixed filelength
    sub SendPipe {
        my ($self, $FH, $filename, $filelength, $mime) = @_;
        if(! defined $filelength) {
            $self->Send404();
        }

        $mime //= getMIME($filename);
        binmode($FH);
        my %fileitem;
        $fileitem{'fh'} = $FH;
        $fileitem{'get_current_length'} = sub {
            my $tocheck = defined $self->{'header'}{'_RangeEnd'} ? $self->{'header'}{'_RangeEnd'}+1 : $filelength;
            return min($filelength, $tocheck);
        };

        $self->_SendDataItem(\%fileitem, {
           'size'     => $filelength,
           'mime'     => $mime,
           'filename' => $filename
        });
    }

    # to do get rid of shell escape, launch ssh without blocking
    sub SendFromSSH {
        my ($self, $sshsource, $filename, $node) = @_;
        my @sshcmd = ('ssh', $sshsource->{'userhost'}, '-p', $sshsource->{'port'});
        my $fullescapedname = "'" . shell_escape($filename) . "'";
        my $folder = $sshsource->{'folder'};
        my $size = $node->[1];
        my @cmd;
        if(defined $self->{'header'}{'_RangeStart'}) {
            my $start = $self->{'header'}{'_RangeStart'};
            my $end = $self->{'header'}{'_RangeEnd'} // ($size - 1);
            my $bytestoskip =  $start;
            my $count = $end - $start + 1;
            @cmd = (@sshcmd, 'dd', 'skip='.$bytestoskip, 'count='.$count, 'bs=1', 'if='.$fullescapedname);
        }
        else{
            @cmd = (@sshcmd, 'cat', $fullescapedname);
        }
        say "SendFromSSH (BLOCKING)";
        open(my $cmdh, '-|', @cmd) or die("SendFromSSH $!");

        $self->SendPipe($cmdh, basename($filename), $size);
        return 1;
    }

    # ENOTIMPLEMENTED
    sub Proxy {
        my ($self, $proxy, $node) = @_;
        die;
        return 1;
    }

    # buf is a bytes scalar
    sub SendBytes {
        my ($self, $mime, $buf, $options) = @_;

        # we want to sent in increments of bytes not characters
        if(Encode::is_utf8($buf)) {
            warn "SendBytes: UTF8 flag is set, turning off";
            Encode::_utf8_off($buf);
        }

        my $bytesize = length($buf);

        # only truncate buf if responding to a range request
        if((!$options->{'code'}) || ($options->{'code'} == 206)) {
            my $start =  $self->{'header'}{'_RangeStart'} // 0;
            my $end   =  $self->{'header'}{'_RangeEnd'}  // $bytesize-1;
            $buf      =  substr($buf, $start, ($end-$start) + 1);
        }

        # Use perlio to read from the buf
        my $fh;
        if(!open($fh, '<', \$buf)) {
            $self->Send404;
            return;
        }
        my %fileitem = (
            'fh' => $fh,
            'get_current_length' => sub { return undef }
        );
        $self->_SendDataItem(\%fileitem, {
           'size'     => $bytesize,
           'mime'     => $mime,
           'filename' => $options->{'filename'},
           'code'     => $options->{'code'}
        });
    }

    # expects unicode string (not bytes)
    sub SendText {
        my ($self, $mime, $buf, $options) = @_;
        @_ = ($self, $mime, encode('UTF-8', $buf), $options);
        goto &SendBytes;
    }

    # expects unicode string (not bytes)
    sub SendHTML {
        my ($self, $buf, $options) = @_;;
        @_ = ($self, 'text/html; charset=utf-8', encode('UTF-8', $buf), $options);
        goto &SendBytes;
    }

    # expects perl data structure
    sub SendAsJSON {
        my ($self, $obj, $options) = @_;
        @_ = ($self, 'application/json', encode_json($obj), $options);
        goto &SendBytes;
    }

    sub SendCallback {
        my ($self, $callback, $options) = @_;
        my %fileitem;
        $fileitem{'cb'} = $callback;

        $self->_SendDataItem(\%fileitem, {
           'size'     => $options->{'size'},
           'mime'     => $options->{'mime'},
           'filename' => $options->{'filename'}
        });
    }

    sub SendAsTar {
        my ($self, $requestfile) = @_;

        if(!HAS_Alien_Tar_Size) {
            warn("Cannot send tar without Alien::Tar::Size");
            $self->Send404();
            return;
        }
        my ($libtarsize) = Alien::Tar::Size->dynamic_libs;
        if(!$libtarsize) {
            warn("Cannot find libtarsize");
            $self->Send404();
            return;
        }

        # HACK, use LD_PRELOAD to hook tar to calculate the size quickly
        my @tarcmd = ('tar', '-C', dirname($requestfile), basename($requestfile), '-c', '--owner=0', '--group=0');
        $self->{'process'} =  MHFS::Process->new(\@tarcmd, $self->{'client'}{'server'}{'evp'}, {
            'SIGCHLD' => sub {
                my $out = $self->{'process'}{'fd'}{'stdout'}{'fd'};
                my $size;
                read($out, $size, 50);
                chomp $size;
                say "size: $size";
                $self->{'process'} = MHFS::Process->new(\@tarcmd, $self->{'client'}{'server'}{'evp'}, {
                    'STDOUT' => sub {
                        my($out) = @_;
                        say "tar sending response";
                        $self->{'outheaders'}{'Accept-Ranges'} = 'none';
                        my %fileitem = ('fh' => $out, 'get_current_length' => sub { return undef });
                        $self->_SendDataItem(\%fileitem, {
                            'size' => $size,
                            'mime' => 'application/x-tar',
                            'code' => 200,
                            'attachment' => basename($requestfile).'.tar'
                        });
                        return 0;
                    }
                });
            },
        },
        undef, # fd settings
        {
            'LD_PRELOAD' => $libtarsize
        });
    }

    sub SendDirectory {
        my ($request, $droot) = @_;

        # otherwise attempt to send a file from droot
        my $requestfile = abs_path($droot . $request->{'path'}{'unsafecollapse'});
        say "abs requestfile: $requestfile" if(defined $requestfile);

        # not a file or is outside of the document root
        if(( ! defined $requestfile) ||
        (rindex($requestfile, $droot, 0) != 0)){
            $request->Send404;
        }
        # is regular file
        elsif (-f $requestfile) {
            if(index($request->{'path'}{'unsafecollapse'}, '/', length($request->{'path'}{'unsafecollapse'})-1) == -1) {
                $request->SendFile($requestfile);
            }
            else {
                $request->Send404;
            }
        }
        # is directory
        elsif (-d _) {
            # ends with slash
            if(index($request->{'path'}{'unescapepath'}, '/', length($request->{'path'}{'unescapepath'})-1) != -1) {
                my $index = $requestfile.'/index.html';
                if(-f $index) {
                    $request->SendFile($index);
                    return;
                }
                $request->Send404;
            }
            else {
                # redirect to slash path
                my $bn = basename($requestfile);
                $request->SendRedirect(301, $bn.'/');
            }
        }
        else {
            $request->Send404;
        }
    }

    sub SendDirectoryListing {
        my ($self, $absdir, $urldir) = @_;
        my $urf = $absdir .'/'.substr($self->{'path'}{'unsafepath'}, length($urldir));
        my $requestfile = abs_path($urf);
        my $ml = $absdir;
        say "rf $requestfile " if(defined $requestfile);
        if (( ! defined $requestfile) || (rindex($requestfile, $ml, 0) != 0)){
            $self->Send404;
            return;
        }

        if(-f $requestfile) {
            if(index($self->{'path'}{'unsafecollapse'}, '/', length($self->{'path'}{'unsafecollapse'})-1) == -1) {
                $self->SendFile($requestfile);
            }
            else {
                $self->Send404;
            }
            return;
        }
        elsif(-d _) {
            # ends with slash
            if((substr $self->{'path'}{'unescapepath'}, -1) eq '/') {
                opendir ( my $dh, $requestfile ) or die "Error in opening dir $requestfile\n";
                my $buf;
                my $filename;
                while( ($filename = readdir($dh))) {
                   next if(($filename eq '.') || ($filename eq '..'));
                   next if(!(-s "$requestfile/$filename"));
                   my $url = uri_escape($filename);
                   $url .= '/' if(-d _);
                   $buf .= '<a href="' . $url .'">'.${escape_html_noquote(decode('UTF-8', $filename, Encode::LEAVE_SRC))} .'</a><br><br>';
                }
                closedir($dh);
                $self->SendHTML($buf);
                return;
            }
            # redirect to slash path
            else {
                $self->SendRedirect(301, basename($requestfile).'/');
                return;
            }
        }
        $self->Send404;
    }

    sub PUTBuf_old {
        my ($self, $handler) = @_;
        if(length($self->{'client'}{'inbuf'}) < $self->{'header'}{'Content-Length'}) {
            $self->{'client'}->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
        }
        my $sdata;
        $self->{'on_read_ready'} = sub {
            my $contentlength = $self->{'header'}{'Content-Length'};
            $sdata .= $self->{'client'}{'inbuf'};
            my $dlength = length($sdata);
            if($dlength >= $contentlength) {
                say 'PUTBuf datalength ' . $dlength;
                my $data;
                if($dlength > $contentlength) {
                    $data = substr($sdata, 0, $contentlength);
                    $self->{'client'}{'inbuf'} = substr($sdata, $contentlength);
                    $dlength = length($data)
                }
                else {
                    $data = $sdata;
                    $self->{'client'}{'inbuf'} = '';
                }
                $self->{'on_read_ready'} = undef;
                $handler->($data);
            }
            else {
                $self->{'client'}{'inbuf'} = '';
            }
            #return '';
            return 1;
        };
        $self->{'on_read_ready'}->();
    }

    sub PUTBuf {
        my ($self, $handler) = @_;
        if($self->{'header'}{'Content-Length'} > 20000000) {
            say "PUTBuf too big";
            $self->{'client'}->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
            $self->{'on_read_ready'} = sub { return undef };
            return;
        }
        if(length($self->{'client'}{'inbuf'}) < $self->{'header'}{'Content-Length'}) {
            $self->{'client'}->SetEvents(POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK );
        }
        $self->{'on_read_ready'} = sub {
            my $contentlength = $self->{'header'}{'Content-Length'};
            my $dlength = length($self->{'client'}{'inbuf'});
            if($dlength >= $contentlength) {
                say 'PUTBuf datalength ' . $dlength;
                my $data;
                if($dlength > $contentlength) {
                    $data = substr($self->{'client'}{'inbuf'}, 0, $contentlength, '');
                }
                else {
                    $data = $self->{'client'}{'inbuf'};
                    $self->{'client'}{'inbuf'} = '';
                }
                $self->{'on_read_ready'} = undef;
                $handler->($data);
            }
            return 1;
        };
        $self->{'on_read_ready'}->();
    }

    sub SendFile {
        my ($self, $requestfile) = @_;
        foreach my $uploader (@{$self->{'client'}{'server'}{'uploaders'}}) {
            return if($uploader->($self, $requestfile));
        }
        say "SendFile - SendLocalFile $requestfile";
        return $self->SendLocalFile($requestfile);
    }

    1;
}

package MHFS::HTTP::Server::Client {
    use strict; use warnings;
    use feature 'say';
    use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
    use IO::Socket::INET;
    use Errno qw(EINTR EIO :POSIX);
    use Fcntl qw(:seek :mode);
    use File::stat;
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Scalar::Util qw(looks_like_number weaken);
    use Data::Dumper;
    use Carp;
    $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

    sub new {
        my ($class, $sock, $server, $serverhostinfo, $ip) = @_;
        $sock->blocking(0);
        my %self = ('sock' => $sock, 'server' => $server, 'time' => clock_gettime(CLOCK_MONOTONIC), 'inbuf' => '', 'serverhostname' => $serverhostinfo->{'hostname'}, 'absurl' => $serverhostinfo->{'absurl'}, 'ip' => $ip, 'X-MHFS-PROXY-KEY' => $serverhostinfo->{'X-MHFS-PROXY-KEY'});
        $self{'CONN-ID'} = int($self{'time'} * rand()); # insecure uid
        $self{'outheaders'}{'X-MHFS-CONN-ID'} = sprintf("%X", $self{'CONN-ID'});
        bless \%self, $class;
        $self{'request'} = MHFS::HTTP::Server::Client::Request->new(\%self);
        return \%self;
    }

    # add a connection timeout timer
    sub AddClientCloseTimer {
        my ($self, $timelength, $id) = @_;
        weaken($self); #don't allow this timer to keep the client object alive
        my $server = $self->{'server'};
        say "CCT | add timer: $id";
        $server->{'evp'}->add_timer($timelength, 0, sub {
            if(! defined $self) {
                say "CCT | $id self undef";
                return undef;
            }
            #(defined $self) or return undef;
            say "CCT | \$timelength ($timelength) exceeded, closing CONN $id";
            say "-------------------------------------------------";
            $server->{'evp'}->remove($self->{'sock'});
            say "poll has " . scalar ( $server->{'evp'}{'poll'}->handles) . " handles";
            return undef;
        }, $id);
        return $id;
    }

    sub KillClientCloseTimer {
        my ($self, $id) = @_;
        my $server = $self->{'server'};
        say "CCT | removing timer: $id";
        $server->{'evp'}->remove_timer_by_id($id);
    }

    sub SetEvents {
        my ($self, $events) = @_;
        $self->{'server'}{'evp'}->set($self->{'sock'}, $self, $events);
    }

    use constant {
        RECV_SIZE => 65536,
        CT_YIELD => 1,
        CT_DONE  => undef,
        #CT_READ => 1,
        #CT_PROCESS = 2,
        #CT_WRITE => 3
    };

    # The "client_thread" consists of 5 states, CT_READ, CT_PROCESS, CT_WRITE, CT_YIELD, and CT_DONE
    # CT_READ reads input data from the socket
    ##    on data read transitions to CT_PROCESS
    ##    on error transitions to CT_DONE
    ##    otherwise CT_YIELD

    # CT_PROCESS processes the input data
    ##    on processing done, switches to CT_WRITE or CT_READ to read more data to process
    ##    on error transitions to CT_DONE
    ##    otherwise CT_YIELD

    # CT_WRITE outputs data to the socket
    ##   on all data written transitions to CT_PROCESS unless Connection: close is set.
    ##   on error transitions to CT_DONE
    ##   otherwise CT_YIELD

    # CT_YIELD just returns control to the poll loop to wait for IO or allow another client thread to run

    # CT_DONE also returns control to the poll loop, it is called on error or when the client connection should be closed or is closed

    sub CT_READ {
        my ($self) = @_;
        my $tempdata;
        if(!defined($self->{'sock'}->recv($tempdata, RECV_SIZE))) {
            if(! $!{EAGAIN}) {
                print ("CT_READ RECV errno: $!\n");
                return CT_DONE;
            }
            return CT_YIELD;
        }
        if(length($tempdata) == 0) {
            say 'Server::Client read 0 bytes, client read closed';
            return CT_DONE;
        }
        $self->{'inbuf'} .= $tempdata;
        goto &CT_PROCESS;
    }

    sub CT_PROCESS {
        my ($self) = @_;
        $self->{'request'} //= MHFS::HTTP::Server::Client::Request->new($self);
        if(!defined($self->{'request'}{'on_read_ready'})) {
            die("went into CT_PROCESS in bad state");
            return CT_YIELD;
        }
        my $res = $self->{'request'}{'on_read_ready'}->($self->{'request'});
        if(!$res) {
            return $res;
        }
        if(defined $self->{'request'}{'response'}) {
            goto &CT_WRITE;
        }
        elsif(defined $self->{'request'}{'on_read_ready'}) {
            goto &CT_READ;
        }
        return $res;
    }

    sub CT_WRITE {
        my ($self) = @_;
        if(!defined $self->{'request'}{'response'}) {
            die("went into CT_WRITE in bad state");
            return CT_YIELD;
        }
        # TODO only TrySendResponse if there is data in buf or to be read
        my $tsrRet = $self->TrySendResponse;
        if(!defined($tsrRet)) {
            say "-------------------------------------------------";
            return CT_DONE;
        }
        elsif($tsrRet ne '') {
            if($self->{'request'}{'outheaders'}{'Connection'} && ($self->{'request'}{'outheaders'}{'Connection'} eq 'close')) {
                say "Connection close header set closing conn";
                say "-------------------------------------------------";
                return CT_DONE;
            }
            $self->{'request'} = undef;
            goto &CT_PROCESS;
        }
        return CT_YIELD;
    }

    sub do_on_data {
        my ($self) = @_;
        my $res = $self->{'request'}{'on_read_ready'}->($self->{'request'});
        if($res) {
            if(defined $self->{'request'}{'response'}) {
                #say "do_on_data: goto onWriteReady";
                goto &onWriteReady;
                #return onWriteReady($self);
            }
            #else {
            elsif(defined $self->{'request'}{'on_read_ready'}) {
                #say "do_on_data: goto onReadReady inbuf " . length($self->{'inbuf'});
                goto &onReadReady;
                #return onReadReady($self);
            }
            else {
                say "do_on_data: response and on_read_ready not defined, response by timer or poll?";
            }
        }
        return $res;
    }


    sub onReadReady {
        goto &CT_READ;
        my ($self) = @_;
        my $tempdata;
        if(defined($self->{'sock'}->recv($tempdata, RECV_SIZE))) {
            if(length($tempdata) == 0) {
                say 'Server::Client read 0 bytes, client read closed';
                return undef;
            }
            $self->{'inbuf'} .= $tempdata;
            goto &do_on_data;
        }
        if(! $!{EAGAIN}) {
            print ("MHFS::HTTP::Server::Client onReadReady RECV errno: $!\n");
            return undef;
        }
        return '';
    }

    sub onWriteReady {
        goto &CT_WRITE;
        my ($client) = @_;
        # send the response
        if(defined $client->{'request'}{'response'}) {
            # TODO only TrySendResponse if there is data in buf or to be read
            my $tsrRet = $client->TrySendResponse;
            if(!defined($tsrRet)) {
                say "-------------------------------------------------";
                return undef;
            }
            elsif($tsrRet ne '') {
                if($client->{'request'}{'outheaders'}{'Connection'} && ($client->{'request'}{'outheaders'}{'Connection'} eq 'close')) {
                    say "Connection close header set closing conn";
                    say "-------------------------------------------------";
                    return undef;
                }
                $client->{'request'} = MHFS::HTTP::Server::Client::Request->new($client);
                # handle possible existing read data
                goto &do_on_data;
            }
        }
        else {
            say "response not defined, probably set later by a timer or poll";
        }
        return 1;
    }

    sub _TSRReturnPrint {
        my ($sentthiscall) = @_;
        if($sentthiscall > 0) {
            say "wrote $sentthiscall bytes";
        }
    }

    sub TrySendResponse {
        my ($client) = @_;
        my $csock = $client->{'sock'};
        my $dataitem = $client->{'request'}{'response'};
        defined($dataitem->{'buf'}) or die("dataitem must always have a buf");
        my $sentthiscall = 0;
        do {
            # Try to send the buf if set
            if(length($dataitem->{'buf'})) {
                my $sret = TrySendItem($csock, \$dataitem->{'buf'});
                # critical conn error
                if(! defined($sret)) {
                    _TSRReturnPrint($sentthiscall);
                    return undef;
                }
                if($sret) {
                    $sentthiscall += $sret;
                    # if we sent data, kill the send timer
                    if(defined $client->{'sendresponsetimerid'}) {
                        $client->KillClientCloseTimer($client->{'sendresponsetimerid'});
                        $client->{'sendresponsetimerid'} = undef;
                    }
                }
                # not all data sent, add timer
                if(length($dataitem->{'buf'}) > 0) {
                    $client->{'sendresponsetimerid'} //= $client->AddClientCloseTimer($client->{'server'}{'settings'}{'sendresponsetimeout'}, $client->{'CONN-ID'});
                    _TSRReturnPrint($sentthiscall);
                    return '';
                }

                #we sent the full buf
            }

            # read more data
            my $newdata;
            if(defined $dataitem->{'fh'}) {
                my $FH = $dataitem->{'fh'};
                my $req_length = $dataitem->{'get_current_length'}->();
                my $filepos = $dataitem->{'fh_pos'};
                # TODO, remove this assert
                if($filepos != tell($FH)) {
                    die('tell mismatch');
                }
                if($req_length && ($filepos >= $req_length)) {
                    if($filepos > $req_length) {
                        say "Reading too much tell: $filepos req_length: $req_length";
                    }
                    say "file read done";
                    close($FH);
                }
                else {
                    my $readamt = 24000;
                    if($req_length) {
                        my $tmpsend = $req_length - $filepos;
                        $readamt = $tmpsend if($tmpsend < $readamt);
                    }
                    # this is blocking, it shouldn't block for long but it could if it's a pipe especially
                    my $bytesRead = read($FH, $newdata, $readamt);
                    if(! defined($bytesRead)) {
                        $newdata = undef;
                        say "READ ERROR: $!";
                    }
                    elsif($bytesRead == 0) {
                        # read EOF, better remove the error
                        if(! $req_length) {
                            say '$req_length not set and read 0 bytes, treating as EOF';
                            $newdata = undef;
                        }
                        else {
                            say 'FH EOF ' .$filepos;
                            seek($FH, 0, 1);
                            _TSRReturnPrint($sentthiscall);
                            return '';
                        }
                    }
                    else {
                        $dataitem->{'fh_pos'} += $bytesRead;
                    }
                }
            }
            elsif(defined $dataitem->{'cb'}) {
                $newdata = $dataitem->{'cb'}->($dataitem);
            }

            my $encode_chunked = $dataitem->{'is_chunked'};
            # if we got to here and there's no data, fetching newdata is done
            if(! $newdata) {
                $dataitem->{'fh'} = undef;
                $dataitem->{'cb'} = undef;
                $dataitem->{'is_chunked'} = undef;
                $newdata = '';
            }

            # encode chunked encoding if needed
            if($encode_chunked) {
                my $sizeline = sprintf "%X\r\n", length($newdata);
                $newdata = $sizeline.$newdata."\r\n";
            }

            # add the new data to the dataitem buffer
            $dataitem->{'buf'} .= $newdata;

        } while(length($dataitem->{'buf'}));
        $client->{'request'}{'response'} = undef;

        _TSRReturnPrint($sentthiscall);
        say "DONE Sending Data";
        return 'RequestDone'; # not undef because keep-alive
    }

    sub TrySendItem {
        my ($csock, $dataref) = @_;
        my $sret = send($csock, $$dataref, MSG_DONTWAIT);
        if(! defined($sret)) {
            if($!{EAGAIN}) {
                #say "SEND EAGAIN\n";
                return 0;
            }
            elsif($!{ECONNRESET}) {
                print "ECONNRESET\n";
            }
            elsif($!{EPIPE}) {
                print "EPIPE\n";
            }
            else {
                print "send errno $!\n";
            }
            return undef;
        }
        elsif($sret) {
            substr($$dataref, 0, $sret, '');
        }
        return $sret;
    }

    sub onHangUp {
        my ($client) = @_;
        return undef;
    }

    sub DESTROY {
        my $self = shift;
        say "$$ MHFS::HTTP::Server::Client destructor: ";
        say "$$ ".'X-MHFS-CONN-ID: ' . $self->{'outheaders'}{'X-MHFS-CONN-ID'};
        if($self->{'sock'}) {
            #shutdown($self->{'sock'}, 2);
            close($self->{'sock'});
        }
    }

    1;
}

package MHFS::FD::Reader {
    use strict; use warnings;
    use feature 'say';
    use Time::HiRes qw( usleep clock_gettime CLOCK_MONOTONIC);
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Scalar::Util qw(looks_like_number weaken);
    sub new {
        my ($class, $process, $fd, $func) = @_;
        my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'process' => $process, 'fd' => $fd, 'onReadReady' => $func);
        say "PID " . $self{'process'}{'pid'} . 'FD ' . $self{'fd'};
        weaken($self{'process'});
        return bless \%self, $class;
    }

    sub onReadReady {
        my ($self) = @_;
        my $ret = $self->{'onReadReady'}($self->{'fd'});
        if($ret == 0) {
            $self->{'process'}->remove($self->{'fd'});
            return 1;
        }
        if($ret == -1) {
            return undef;
        }
        if($ret == 1) {
            return 1;
        }
    }

    sub onHangUp {

    }

    sub DESTROY {
        my $self = shift;
        print "PID " . $self->{'process'}{'pid'} . ' ' if($self->{'process'});
        print "FD " . $self->{'fd'};
        say ' reader DESTROY called';
    }

    1;
 }

 package MHFS::FD::Writer {
    use strict; use warnings;
    use feature 'say';
    use Time::HiRes qw( usleep clock_gettime CLOCK_MONOTONIC);
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Scalar::Util qw(looks_like_number weaken);
    sub new {
        my ($class, $process, $fd, $func) = @_;
        my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'process' => $process, 'fd' => $fd, 'onWriteReady' => $func);
        say "PID " . $self{'process'}{'pid'} . 'FD ' . $self{'fd'};
        weaken($self{'process'});
        return bless \%self, $class;
    }

    sub onWriteReady {
        my ($self) = @_;
        my $ret = $self->{'onWriteReady'}($self->{'fd'});
        if($ret == 0) {
            $self->{'process'}->remove($self->{'fd'});
            return 1;
        }
        if($ret == -1) {
            return undef;
        }
        if($ret == 1) {
            return 1;
        }
    }

    sub onHangUp {

    }

    sub DESTROY {
        my $self = shift;
        say "PID " . $self->{'process'}{'pid'} . " FD " . $self->{'fd'}.' writer DESTROY called';
    }

    1;
 }

package MHFS::Process {
    use strict; use warnings;
    use feature 'say';
    use Symbol 'gensym';
    use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
    use POSIX ":sys_wait_h";
    use IO::Socket::INET;
    use IO::Poll qw(POLLIN POLLOUT POLLHUP);
    use Errno qw(EINTR EIO :POSIX);
    use Fcntl qw(:seek :mode);
    use File::stat;
    use IPC::Open3;
    use Scalar::Util qw(looks_like_number weaken);
    use Data::Dumper;
    use Devel::Peek;

    use Carp;
    $SIG{ __DIE__ } = sub { Carp::confess( @_ ) };

    #my %CHILDREN;
    #$SIG{CHLD} = sub {
    #    while((my $child = waitpid(-1, WNOHANG)) > 0) {
    #        my ($wstatus, $exitcode) = ($?, $?>> 8);
    #        if(defined $CHILDREN{$child}) {
    #            say "PID $child reaped (func) $exitcode";
    #            $CHILDREN{$child}->($exitcode);
    #            # remove file handles here?
    #            $CHILDREN{$child} = undef;
    #        }
    #        else {
    #            say "PID $child reaped (No func) $exitcode";
    #        }
    #    }
    #};

    sub _setup_handlers {
        my ($self, $in, $out, $err, $fddispatch, $handlesettings) = @_;
        my $pid = $self->{'pid'};
        my $evp = $self->{'evp'};

        if($fddispatch->{'SIGCHLD'}) {
            say "PID $pid custom SIGCHLD handler";
            #$CHILDREN{$pid} = $fddispatch->{'SIGCHLD'};
            $evp->register_child($pid, $fddispatch->{'SIGCHLD'});
        }
        if($fddispatch->{'STDIN'}) {
            $self->{'fd'}{'stdin'} = MHFS::FD::Writer->new($self, $in, $fddispatch->{'STDIN'});
            $evp->set($in, $self->{'fd'}{'stdin'}, POLLOUT | MHFS::EventLoop::Poll->ALWAYSMASK);
        }
        else {
            $self->{'fd'}{'stdin'}{'fd'} = $in;
        }
        if($fddispatch->{'STDOUT'}) {
            $self->{'fd'}{'stdout'} = MHFS::FD::Reader->new($self, $out, $fddispatch->{'STDOUT'});
            $evp->set($out, $self->{'fd'}{'stdout'}, POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK());
        }
        else {
            $self->{'fd'}{'stdout'}{'fd'} = $out;
        }
        if($fddispatch->{'STDERR'}) {
            $self->{'fd'}{'stderr'} = MHFS::FD::Reader->new($self, $err, $fddispatch->{'STDERR'});
            $evp->set($err, $self->{'fd'}{'stderr'}, POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK);
        }
        else {
            $self->{'fd'}{'stderr'}{'fd'} = $err;
        }

        if($handlesettings->{'O_NONBLOCK'}) {
            my $flags = 0;
            # stderr
            (0 == fcntl($err, Fcntl::F_GETFL, $flags)) or die;#return undef;
            $flags |= Fcntl::O_NONBLOCK;
            (0 == fcntl($err, Fcntl::F_SETFL, $flags)) or die;#return undef;
            # stdout
            (0 == fcntl($out, Fcntl::F_GETFL, $flags)) or die;#return undef;
            $flags |= Fcntl::O_NONBLOCK;
            (0 == fcntl($out, Fcntl::F_SETFL, $flags)) or die;#return undef;
            # stdin
            defined($in->blocking(0)) or die($!);
            #(0 == fcntl($in, Fcntl::F_GETFL, $flags)) or die("$!");#return undef;
            #$flags |= Fcntl::O_NONBLOCK;
            #(0 == fcntl($in, Fcntl::F_SETFL, $flags)) or die;#return undef;
            return $self;
        }
    }

    sub sigkill {
        my ($self, $cb) = @_;
        if($cb) {
            $self->{'evp'}{'children'}{$self->{'pid'}} = $cb;
        }
        kill('KILL', $self->{'pid'});
    }

    sub stopSTDOUT {
        my ($self) = @_;
        $self->{'evp'}->set($self->{'fd'}{'stdout'}{'fd'}, $self->{'fd'}{'stdout'}, MHFS::EventLoop::Poll->ALWAYSMASK);
    }

    sub resumeSTDOUT {
        my ($self) = @_;
        $self->{'evp'}->set($self->{'fd'}{'stdout'}{'fd'}, $self->{'fd'}{'stdout'}, POLLIN | MHFS::EventLoop::Poll->ALWAYSMASK);
    }

    sub new {
        my ($class, $torun, $evp, $fddispatch, $handlesettings, $env) = @_;
        my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'evp' => $evp);


        my %oldenvvars;
        if($env) {
            foreach my $key(keys %{$env}) {
                # save current value
                $oldenvvars{$key} = $ENV{$key};
                # set new value
                $ENV{$key} = $env->{$key};
                my $oldval = $oldenvvars{$key} // '{undef}';
                my $newval = $env->{$key}  // '{undef}';
                say "Changed \$ENV{$key} from $oldval to $newval";
            }
        }

        my ($pid, $in, $out, $err);
        eval{ $pid = open3($in, $out, $err = gensym, @$torun); };
        if($@) {
            say "BAD process";
            return undef;
        }
        $self{'pid'} = $pid;
        say 'PID '. $pid . ' NEW PROCESS: ' . $torun->[0];
        if($env) {
            # restore environment
            foreach my $key(keys %oldenvvars) {
                $ENV{$key} = $oldenvvars{$key};
                my $oldval = $env->{$key} // '{undef}';
                my $newval = $oldenvvars{$key} // '{undef}';
                say "Restored \$ENV{$key} from $oldval to $newval";
            }
        }
        _setup_handlers(\%self, $in, $out, $err, $fddispatch, $handlesettings);
        return bless \%self, $class;
    }

    sub _new_ex {
        my ($make_process, $make_process_args, $context) = @_;
         my $process;
        $context->{'stdout'} = '';
        $context->{'stderr'} = '';
        my $prochandlers = {
        'STDOUT' => sub {
            my ($handle) = @_;
            my $buf;
            while(read($handle, $buf, 4096)) {
                $context->{'stdout'} .= $buf;
            }
            if($context->{'on_stdout_data'}) {
                $context->{'on_stdout_data'}->($context);
            }
            return 1;
        },
        'STDERR' => sub {
            my ($handle) = @_;
            my $buf;
            while(read($handle, $buf, 4096)) {
                $context->{'stderr'} .= $buf;
            }
            return 1;
        },
        'SIGCHLD' => sub {
            my $obuf;
            my $handle = $process->{'fd'}{'stdout'}{'fd'};
            while(read($handle, $obuf, 100000)) {
                $context->{'stdout'} .= $obuf;
                say "stdout sigchld read";
            }
            my $ebuf;
            $handle = $process->{'fd'}{'stderr'}{'fd'};
            while(read($handle, $ebuf, 100000)) {
                $context->{'stderr'} .= $ebuf;
                say "stderr sigchld read";
            }
            if($context->{'on_stdout_data'}) {
                $context->{'on_stdout_data'}->($context);
            }
            $context->{'at_exit'}->($context);
        },
        };

        if($context->{'input'}) {
            $prochandlers->{'STDIN'} = sub {
                my ($fh) = @_;
                while(1) {
                    my $curbuf = $context->{'curbuf'};
                    if($curbuf) {
                        my $rv = syswrite($fh, $curbuf, length($curbuf));
                        if(!defined($rv)) {
                            if(! $!{EAGAIN}) {
                                say "Critical write error";
                                return -1;
                            }
                            return 1;
                        }
                        elsif($rv != length($curbuf)) {
                            substr($context->{'curbuf'}, 0, $rv, '');
                            return 1;
                        }
                        else {
                            say "wrote all";
                        }
                    }
                    $context->{'curbuf'} = $context->{'input'}->($context);
                    if(! defined $context->{'curbuf'}) {
                        return 0;
                    }
                }
            };
        }

        $process = $make_process->($make_process_args, $prochandlers, {'O_NONBLOCK' => 1});
        return $process;
    }

    # launch a command process with poll handlers
    sub _new_cmd {
        my ($mpa, $prochandlers, $handlesettings) = @_;
        return $mpa->{'class'}->new($mpa->{'cmd'}, $mpa->{'evp'}, $prochandlers, $handlesettings);
    }

    # launch a command process
    sub new_cmd_process {
        my ($class, $evp, $cmd, $context) = @_;
        my $mpa = {'class' => $class, 'evp' => $evp, 'cmd' => $cmd};
        return _new_ex(\&_new_cmd, $mpa, $context);
    }

    # subset of command process, just need the data on SIGCHLD
    sub new_output_process {
        my ($class, $evp, $cmd, $handler) = @_;

        return new_cmd_process($class, $evp, $cmd, {
            'at_exit' => sub {
                my ($context) = @_;
                say 'run handler';
                $handler->($context->{'stdout'}, $context->{'stderr'});
            }
        });
    }

    sub new_io_process {
        my ($class, $evp, $cmd, $handler, $inputdata) = @_;
        my $ctx = {
            'at_exit' => sub {
                my ($context) = @_;
                say 'run handler';
                $handler->($context->{'stdout'}, $context->{'stderr'});
            }
        };
        if(defined $inputdata) {
            $ctx->{'curbuf'} = $inputdata;
            $ctx->{'input'} = sub {
                say "all written";
                return undef;
            };
        }
        return new_cmd_process($class, $evp, $cmd, $ctx);
    }

    # launch a process without a new exe with poll handlers
    sub _new_child {
        my ($mpa, $prochandlers, $handlesettings) = @_;

        my %self = ('time' => clock_gettime(CLOCK_MONOTONIC), 'evp' => $mpa->{'evp'});
        # inreader/inwriter   is the parent to child data channel
        # outreader/outwriter is the child to parent data channel
        # errreader/errwriter is the child to parent log channel
        pipe(my $inreader, my $inwriter)   or die("pipe failed $!");
        pipe(my $outreader, my $outwriter) or die("pipe failed $!");
        pipe(my $errreader, my $errwriter) or die("pipe failed $!");
        # the childs stderr will be UTF-8 text
        binmode($errreader, ':encoding(UTF-8)');
        my $pid = fork();
        if($pid == 0) {
            close($inwriter);
            close($outreader);
            close($errreader);
            open(STDIN,  "<&", $inreader) or die("Can't dup \$inreader to STDIN");
            open(STDOUT, ">&", $errwriter) or die("Can't dup \$errwriter to STDOUT");
            open(STDERR, ">&", $errwriter) or die("Can't dup \$errwriter to STDERR");
            $mpa->{'func'}->($outwriter);
            exit 0;
        }
        close($inreader);
        close($outwriter);
        close($errwriter);
        $self{'pid'} = $pid;
        say 'PID '. $pid . ' NEW CHILD';
        _setup_handlers(\%self, $inwriter, $outreader, $errreader, $prochandlers, $handlesettings);
        return bless \%self, $mpa->{'class'};
    }

    sub cmd_to_sock {
        my ($name, $cmd, $sockfh) = @_;
        if(fork() == 0) {
            open(STDOUT, ">&", $sockfh) or die("Can't dup \$sockfh to STDOUT");
            exec(@$cmd);
            die;
        }
        close($sockfh);
    }

    # launch a process without a new exe with just sigchld handler
    sub new_output_child {
        my ($class, $evp, $func, $handler) = @_;
        my $mpa = {'class' => $class, 'evp' => $evp, 'func' => $func};
        return _new_ex(\&_new_child, $mpa, {
            'at_exit' => sub {
                my ($context) = @_;
                $handler->($context->{'stdout'}, $context->{'stderr'});
            }
        });
    }

    sub remove {
        my ($self, $fd) = @_;
        $self->{'evp'}->remove($fd);
        say "poll has " . scalar ( $self->{'evp'}{'poll'}->handles) . " handles";
        foreach my $key (keys %{$self->{'fd'}}) {
            if(defined($self->{'fd'}{$key}{'fd'}) && ($fd == $self->{'fd'}{$key}{'fd'})) {
                $self->{'fd'}{$key} = undef;
                last;
            }
        }
    }


    sub DESTROY {
        my $self = shift;
        say "PID " . $self->{'pid'} . ' DESTROY called';
        foreach my $key (keys %{$self->{'fd'}}) {
            if(defined($self->{'fd'}{$key}{'fd'})) {
                #Dump($self->{'fd'}{$key});
                $self->{'evp'}->remove($self->{'fd'}{$key}{'fd'});
                $self->{'fd'}{$key} = undef;
            }
        }
    }

    1;
}

package MHFS::Settings {
    use strict; use warnings;
    use feature 'say';
    use Scalar::Util qw(reftype);
    use File::Basename;
    use Digest::MD5 qw(md5_hex);
    use Storable qw(freeze);
    use Cwd qw(abs_path);
    use File::ShareDir qw(dist_dir);
    MHFS::Util->import();

    sub write_settings_file {
        my ($SETTINGS, $filepath) = @_;
        my $indentcnst = 4;
        my $indentspace = '';
        my $settingscontents = "#!/usr/bin/perl\nuse strict; use warnings;\n\nmy \$SETTINGS = ";

        # we only encode SCALARS. Loop through expanding HASH and ARRAY refs into SCALARS
        my @values = ($SETTINGS);
        while(@values) {
            my $value = shift @values;
            my $type = reftype($value);
            say "value: $value type: " . ($type // 'undef');
            my $raw;
            my $noindent;
            if(! defined $type) {
                if(defined $value) {
                    # process lead control code if provided
                    $raw = ($value eq '__raw');
                    $noindent = ($value eq '__noindent');
                    if($raw || $noindent) {
                        $value = shift @values;
                    }
                }

                if(! defined $value) {
                    $raw = 1;
                    $value = 'undef';
                    $type = 'SCALAR';
                }
                elsif($value eq '__indent-') {
                    substr($indentspace, -4, 4, '');
                    # don't actually encode anything
                    $value = '';
                    $type = 'NOP';
                }
                else {
                    $type = reftype($value) // 'SCALAR';
                }
            }

            say "v2: $value type $type";
            if($type eq 'NOP') {
                next;
            }

            $settingscontents .= $indentspace if(! $noindent);
            if($type eq 'SCALAR') {
                # encode the value
                if(! $raw) {
                    $value =~ s/'/\\'/g;
                    $value = "'".$value."'";
                }

                # add the value to the buffer
                $settingscontents .= $value;
                $settingscontents .= ",\n" if(! $raw);
            }
            elsif($type eq 'HASH') {
                $settingscontents .= "{\n";
                $indentspace .= (' ' x $indentcnst);
                my @toprepend;
                foreach my $key (keys %{$value}) {
                    push @toprepend, '__raw', "'$key' => ", '__noindent', $value->{$key};
                }
                push @toprepend, '__indent-', '__raw', "},\n";
                unshift(@values, @toprepend);
            }
            elsif($type eq 'ARRAY') {
                $settingscontents .= "[\n";
                $indentspace .= (' ' x $indentcnst);
                my @toprepend = @{$value};
                push @toprepend, '__indent-', '__raw', "],\n";
                unshift(@values, @toprepend);
            }
            else {
                die("Unknown type: $type");
            }
        }
        chop $settingscontents;
        chop $settingscontents;
        $settingscontents .= ";\n\n\$SETTINGS;\n";
        system('mkdir', '-p', dirname($filepath)) == 0 or die("failed to make settings folder");
        write_file($filepath,  $settingscontents);
    }

    sub calc_source_id {
        my ($source) = @_;
        if($source->{'type'} ne 'local') {
            say "only local sources supported right now";
            return undef;
        }
        return substr(md5_hex('local:'.$source->{folder}), 0, 8);
    }

    sub load {
        my ($launchsettings) = @_;
        my $scriptpath = abs_path(__FILE__);

        # determine the settings dir
        my $CFGDIR;
        if($launchsettings->{CFGDIR}) {
            -d $launchsettings->{CFGDIR} or die("Bad CFGDIR provided");
            $CFGDIR = $launchsettings->{CFGDIR};
            delete $launchsettings->{CFGDIR};
        }
        else {
            # set the settings dir to the first that exists of $XDG_CONFIG_HOME and $XDG_CONFIG_DIRS
            # https://specifications.freedesktop.org/basedir-spec/basedir-spec-latest.html
            my $XDG_CONFIG_HOME = $ENV{'XDG_CONFIG_HOME'} || ($ENV{'HOME'} . '/.config');
            my @configdirs = ($XDG_CONFIG_HOME);
            my $XDG_CONFIG_DIRS = $ENV{'XDG_CONFIG_DIRS'} || '/etc/xdg';
            push @configdirs, split(':', $XDG_CONFIG_DIRS);
            foreach my $cfgdir (@configdirs) {
                if(-d "$cfgdir/mhfs") {
                    $CFGDIR = "$cfgdir/mhfs";
                    last;
                }
            }
            $CFGDIR ||= ($XDG_CONFIG_HOME.'/mhfs');
        }

        # load from the settings file
        my $SETTINGS_FILE = $CFGDIR . '/settings.pl';
        my $SETTINGS = do ($SETTINGS_FILE);
        if(! $SETTINGS) {
            die "Error parsing settingsfile: $@" if($@);
            die "Cannot read settingsfile: $!" if(-e $SETTINGS_FILE);
            warn("No settings file found, using default settings");
            $SETTINGS = {};
        }

        # launchsettings overrides
        foreach my $key (keys %{$launchsettings}) {
            $SETTINGS->{$key} = $launchsettings->{$key};
        }

        # load defaults for unset values
        $SETTINGS->{'HOST'} ||= "127.0.0.1";
        $SETTINGS->{'PORT'} ||= 8000;

        $SETTINGS->{'ALLOWED_REMOTEIP_HOSTS'} ||= [
            ['127.0.0.1'],
        ];

        # write the default settings
        if(! -f $SETTINGS_FILE) {
            write_settings_file($SETTINGS, $SETTINGS_FILE);
        }

        # determine the allowed remoteip host combos. only ipv4 now sorry
        $SETTINGS->{'ARIPHOSTS_PARSED'} = [];
        foreach my $rule (@{$SETTINGS->{'ALLOWED_REMOTEIP_HOSTS'}}) {
            # parse IPv4 with optional CIDR
            $rule->[0] =~ /^([^\/]+)(?:\/(\d{1,2}))?$/ or die("Invalid rule: " . $rule->[0]);
            my $ipstr = $1; my $cidr = $2 // 32;
            my $ip = MHFS::Util::ParseIPv4($ipstr);
            defined($ip) or die("Invalid rule: " . $rule->[0]);
            $cidr >= 0 && $cidr <= 32  or die("Invalid rule: " . $rule->[0]);
            my $mask = (0xFFFFFFFF << (32-$cidr)) & 0xFFFFFFFF;
            my %ariphost = (
                'ip' => $ip,
                'subnetmask' => $mask
            );
            # store the server hostname if verification is required for this rule
            $ariphost{'hostname'} = $rule->[1] if($rule->[1]);
            # store overriding absurl from this host if provided
            if($rule->[2]) {
                my $absurl = $rule->[2];
                chop $absurl if(index($absurl, '/', length($absurl)-1) != -1);
                $ariphost{'absurl'} = $absurl;
            }
            # store whether to trust connections with this host
            if($rule->[3]) {
                $ariphost{'X-MHFS-PROXY-KEY'} = $rule->[3];
            }
            push @{ $SETTINGS->{'ARIPHOSTS_PARSED'}}, \%ariphost;
        }

        # locate files based on appdir
        my $APPDIR = $SETTINGS->{'APPDIR'} || dist_dir('App-MHFS');
        say __PACKAGE__.": using APPDIR " . $APPDIR;
        $SETTINGS->{'APPDIR'} = $APPDIR;

        if( ! $SETTINGS->{'DOCUMENTROOT'}) {
            $SETTINGS->{'DOCUMENTROOT'} = "$APPDIR/public_html";
        }
        $SETTINGS->{'XSEND'} //= 0;
        my $tmpdir = $SETTINGS->{'TMPDIR'} || ($ENV{'XDG_CACHE_HOME'} || ($ENV{'HOME'} . '/.cache')) . '/mhfs';
        delete $SETTINGS->{'TMPDIR'}; # Use specific temp dir instead
        if(!$SETTINGS->{'RUNTIME_DIR'} ) {
            my $RUNTIMEDIR = $ENV{'XDG_RUNTIME_DIR'};
            if(! $RUNTIMEDIR ) {
                $RUNTIMEDIR = $tmpdir;
                warn("XDG_RUNTIME_DIR not defined!, using $RUNTIMEDIR instead");
            }
            $SETTINGS->{'RUNTIME_DIR'} = $RUNTIMEDIR.'/mhfs';
        }
        my $datadir = $SETTINGS->{'DATADIR'} || ($ENV{'XDG_DATA_HOME'} || ($ENV{'HOME'} . '/.local/share')) . '/mhfs';
        $SETTINGS->{'DATADIR'} = $datadir;
        $SETTINGS->{'MHFS_TRACKER_TORRENT_DIR'} ||= $SETTINGS->{'DATADIR'}.'/torrent';
        $SETTINGS->{'VIDEO_TMPDIR'} ||= $tmpdir.'/video';
        $SETTINGS->{'MUSIC_TMPDIR'} ||= $tmpdir.'/music';
        $SETTINGS->{'GENERIC_TMPDIR'} ||= $tmpdir.'/tmp';
        $SETTINGS->{'SECRET_TMPDIR'} ||= $tmpdir.'/secret';
        $SETTINGS->{'MEDIALIBRARIES'}{'movies'} ||= $SETTINGS->{'DOCUMENTROOT'} . "/media/movies",
        $SETTINGS->{'MEDIALIBRARIES'}{'tv'} ||= $SETTINGS->{'DOCUMENTROOT'} . "/media/tv",
        $SETTINGS->{'MEDIALIBRARIES'}{'music'} ||= $SETTINGS->{'DOCUMENTROOT'} . "/media/music",
        my %sources;
        my %mediasources;
        foreach my $lib ('movies', 'tv', 'music') {
            my $srcs = $SETTINGS->{'MEDIALIBRARIES'}{$lib};
            if(ref($srcs) ne 'ARRAY') {
                $srcs = [$srcs];
            }
            my @subsrcs;
            foreach my $source (@$srcs) {
                my $stype = ref($source);
                my $tohash = $source;
                if($stype ne 'HASH') {
                    if($stype ne '') {
                        say __PACKAGE__.": skipping source";
                        next;
                    }
                    $tohash = {type => 'local',  folder => $source};
                }
                my $sid = calc_source_id($tohash);
                $sources{$sid} = $tohash;
                push @subsrcs, $sid;
            }
            $mediasources{$lib} = \@subsrcs;
        }
        $SETTINGS->{'MEDIASOURCES'} = \%mediasources;

        my $videotmpdirsrc = {type => 'local',  folder => $SETTINGS->{'VIDEO_TMPDIR'}};
        my $vtempsrcid = calc_source_id($videotmpdirsrc);
        $sources{$vtempsrcid} = $videotmpdirsrc;
        $SETTINGS->{'VIDEO_TMPDIR_QS'} = 'sid='.$vtempsrcid;
        $SETTINGS->{'SOURCES'} = \%sources;

        $SETTINGS->{'BINDIR'} ||= $APPDIR . '/bin';
        $SETTINGS->{'DOCDIR'} ||= $APPDIR . '/doc';
        $SETTINGS->{'CFGDIR'} = $CFGDIR;

        # specify timeouts in seconds
        $SETTINGS->{'TIMEOUT'} ||= 75;
        # time to recieve the requestline and headers before closing the conn
        $SETTINGS->{'recvrequestimeout'} ||= $SETTINGS->{'TIMEOUT'};
        # maximum time allowed between sends
        $SETTINGS->{'sendresponsetimeout'} ||= $SETTINGS->{'TIMEOUT'};

        $SETTINGS->{'Torrent'}{'pyroscope'} ||= $ENV{'HOME'} .'/.local/pyroscope';

        return $SETTINGS;
    }

    1;
};

package MHFS::BitTorrent::Bencoding {
    use strict; use warnings;
    use Exporter 'import';
    our @EXPORT = ('bencode', 'bdecode');
    use feature 'say';

    # a node is an array with the first element being the type, followed by the value(s)
    # ('int', iv)          - integer node, MUST have one integer value, bencoded as iIVe
    # ('bstr', bytestring) - byte string node, MUST have one bytestring value, bencoded as bytestringLength:bytestring where bytestringLength is the length as ASCII numbers
    # ('l', values)        - list node, MAY have one or more values of type int, bstr, list, and dict bencoded as lVALUESe
    # ('d', kvpairs)       - dict node, special case of list, MAY one or more key and value pairs. A dict node MUST have multiple of 2 values; a bstr key with corespoding value
    # ('null', value)      - null node, MAY have one value, used internally by bdecode to avoid dealing with the base case of no parent
    # ('e')                - end node, MUST NOT have ANY values, used internally by bencode to handle writing list/dict end

    sub bencode {
        my ($node) = @_;
        my @toenc = ($node);
        my $output;

        while(my $node = shift @toenc) {
            my $type = $node->[0];
            if(($type eq 'd') || ($type eq 'l')) {
                $output .= $type;
                my @nextitems = @{$node};
                shift @nextitems;
                push @nextitems, ['e'];
                unshift @toenc, @nextitems;
            }
            elsif($type eq 'bstr') {
                $output .= sprintf("%u:%s", length($node->[1]), $node->[1]);
            }
            elsif($type eq 'int') {
                $output .= 'i'.$node->[1].'e';
            }
            elsif($type eq 'e') {
                $output .= 'e';
            }
            else {
                return undef;
            }
        }

        return $output;
    }

    sub bdecode {
        my ($contents, $foffset) = @_;
        my @headnode = ('null');
        my @nodestack = (\@headnode);
        my $startoffset = $foffset;

        while(1) {
            # a bstr is always valid as it can be a dict key
            if(substr($$contents, $foffset) =~ /^(0|[1-9][0-9]*):/) {
                my $count = $1;
                $foffset += length($count)+1;
                my $bstr = substr($$contents, $foffset, $count);
                my $node = ['bstr', $bstr];
                $foffset += $count;
                push @{$nodestack[-1]}, $node;
            }
            elsif((substr($$contents, $foffset, 1) eq 'e') &&
            (($nodestack[-1][0] eq 'l') ||
            (($nodestack[-1][0] eq 'd') &&((scalar(@{$nodestack[-1]}) % 2) == 1)))) {
                pop @nodestack;
                $foffset++;
            }
            elsif(($nodestack[-1][0] ne 'd') || ((scalar(@{$nodestack[-1]}) % 2) == 0)) {
                my $firstchar = substr($$contents, $foffset++, 1);
                if(($firstchar eq 'd') || ($firstchar eq 'l')) {
                    my $node = [$firstchar];
                    push @{$nodestack[-1]}, $node;
                    push @nodestack, $node;
                }
                elsif(substr($$contents, $foffset-1) =~ /^i(0|\-?[1-9][0-9]*)e/) {
                    my $node = ['int', $1];
                    $foffset += length($1)+1;
                    push @{$nodestack[-1]}, $node;
                }
                else {
                    say "bad elm $firstchar $foffset";
                    return undef;
                }
            }
            else {
                say "bad elm $foffset";
                return undef;
            }

            if(scalar(@nodestack) == 1) {
                return [$headnode[1], $foffset-$startoffset];
            }
        }
    }

    1;
}

package MHFS::BitTorrent::Metainfo {
    use strict;
    use warnings;
    use feature 'say';
    use Digest::SHA qw(sha1);
    MHFS::BitTorrent::Bencoding->import();
    use Data::Dumper;

    sub Parse {
        my ($srcdata) = @_;
        my $tree = bdecode($srcdata, 0);
        return undef if(! $tree);
        return MHFS::BitTorrent::Metainfo->_new($tree->[0]);
    }

    sub mktor {
        my ($evp, $params, $cb) = @_;
        my $process;
        my @cmd = ('mktor', @$params);
        $process    = MHFS::Process->new_output_process($evp, \@cmd, sub {
            my ($output, $error) = @_;
            chomp $output;
            say 'mktor output: ' . $output;
            $cb->($output);
        });
        return $process;
    }

    sub Create {
        my ($evp, $opt, $cb) = @_;

        if((! exists $opt->{src}) || (! exists $opt->{dest_metafile}) || (! exists $opt->{tracker})) {
            say "MHFS::BitTorrent::Metainfo::Create - Invalid opts";
            $cb->(undef);
            return;
        }

        my @params;
        push @params, '-p' if($opt->{private});
        push @params, ('-o', $opt->{dest_metafile});
        push @params, $opt->{src};
        push @params, $opt->{tracker};
        print "$_ " foreach @params;
        print "\n";

        mktor($evp, \@params, $cb);
    }

    sub InfohashAsHex {
        my ($self) = @_;
        return uc(unpack('H*', $self->{'infohash'}));
    }

    sub _bdictfind {
        my ($node, $keys, $valuetype) = @_;
        NEXTKEY: foreach my $key (@{$keys}) {
            if($node->[0] ne 'd') {
                say "cannot search non dictionary";
                return undef;
            }
            for(my $i = 1; $i < scalar(@{$node}); $i+=2) {
                if($node->[$i][1] eq $key) {
                    $node = $node->[$i+1];
                    last NEXTKEY;
                }
            }
            say "failed to find key $key";
            return undef;
        }
        if(($valuetype) && ($node->[0] ne $valuetype)) {
            say "node has wrong type, expected $valuetype got ". $node->[0];
            return undef;
        }
        return $node;
    }

    sub _bdictgetkeys {
        my ($node) = @_;
        if($node->[0] ne 'd') {
            say "cannot search non dictionary";
            return undef;
        }
        my @keys;
        for(my $i = 1; $i < scalar(@{$node}); $i+=2) {
            push @keys, $node->[$i][1];
        }
        return \@keys;
    }

    sub _new {
        my ($class, $tree) = @_;
        my $infodata = _bdictfind($tree, ['info'], 'd');
        return undef if(! $infodata);
        my %self = (tree => $tree, 'infohash' => sha1(bencode($infodata)));
        bless \%self, $class;
        return \%self;
    }

    1;
}

package MHFS::FS {
    use strict; use warnings;
    use feature 'say';
    use Cwd qw(abs_path);
    use File::Basename qw(fileparse);

    sub lookup {
        my ($self, $name, $sid) = @_;

        if(! exists $self->{'sources'}{$sid}) {
            return undef;
        }

        my $src = $self->{'sources'}{$sid};
        if($src->{'type'} ne 'local') {
            say "unhandled src type ". $src->{'type'};
            return undef;
        }
        my $location = $src->{'folder'};
        my $absolute = abs_path($location.'/'.$name);
        return undef if( ! $absolute);
        return undef if ($absolute !~ /^$location/);
        return _media_filepath_to_src_file($absolute, $location);
    }

    sub _media_filepath_to_src_file {
        my ($filepath, $flocation) = @_;
        my ($name, $loc, $ext) = fileparse($filepath, '\.[^\.]*');
        $ext =~ s/^\.//;
        return { 'filepath' => $filepath, 'name' => $name, 'containingdir' => $loc, 'ext' => $ext, 'fullname' => substr($filepath, length($flocation)+1), 'root' => $flocation};
    }

    sub new {
        my ($class, $sources) = @_;
        my %self = ('sources' => $sources);
        bless \%self, $class;
        return \%self;
    }

    1;
}

package MHFS::BitTorrent::Client {
    use strict; use warnings;
    use feature 'say';

    sub rtxmlrpc {
        my ($server, $params, $cb, $inputdata) = @_;
        my $process;
        my @cmd = ('rtxmlrpc', @$params, '--config-dir', $server->{settings}{'CFGDIR'} . '/.pyroscope/');
        print "$_ " foreach @cmd;
        print "\n";
        $process    = MHFS::Process->new_io_process($server->{evp}, \@cmd, sub {
            my ($output, $error) = @_;
            chomp $output;
            #say 'rtxmlrpc output: ' . $output;
            $cb->($output);
        }, $inputdata);

        if(! $process) {
            $cb->(undef);
        }

        return $process;
    }

    sub torrent_d_bytes_done {
        my ($server, $infohash, $callback) = @_;
        rtxmlrpc($server, ['d.bytes_done', $infohash ], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_d_size_bytes {
        my ($server, $infohash, $callback) = @_;
        rtxmlrpc($server, ['d.size_bytes', $infohash ],sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_load_verbose {
        my ($server, $filename, $callback) = @_;
        rtxmlrpc($server, ['load.verbose', '', $filename], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_load_raw_verbose {
        my ($server, $data, $callback) = @_;
        rtxmlrpc($server, ['load.raw_verbose', '', '@-'], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        }, $data);
    }

    sub torrent_d_directory_set {
        my ($server, $infohash, $directory, $callback) = @_;
        rtxmlrpc($server, ['d.directory.set', $infohash, $directory], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_d_start {
        my ($server, $infohash, $callback) = @_;
        rtxmlrpc($server, ['d.start', $infohash], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_d_delete_tied {
        my ($server, $infohash, $callback) = @_;
        rtxmlrpc($server, ['d.delete_tied', $infohash], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }


    sub torrent_d_name {
        my ($server, $infohash, $callback) = @_;
        rtxmlrpc($server, ['d.name', $infohash], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_d_is_multi_file {
        my ($server, $infohash, $callback) = @_;
        rtxmlrpc($server, ['d.is_multi_file', $infohash], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }


    sub torrent_set_priority {
        my ($server, $infohash, $priority, $callback) = @_;
        rtxmlrpc($server, ['f.multicall', $infohash, '', 'f.priority.set=' . $priority], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $callback->(undef);
            return;
        }
        rtxmlrpc($server, ['d.update_priorities', $infohash], sub {
        if($output =~ /ERROR/) {
            $output = undef;
        }
        $callback->($output);
        })});
    }


    # lookup the findex for the file and then set the priority on it
    # ENOTIMPLEMENTED
    sub torrent_set_file_priority {
        my ($server, $infohash, $file, $priority, $callback) = @_;
        rtxmlrpc($server, ['f.multicall', $infohash, '', 'f.path='], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $callback->(undef);
            return;
        }
        say "torrent_set_file_priority";
        say $output;
        die;

        $callback->($output);
        });
    }

    sub torrent_list_torrents {
        my ($server, $callback) = @_;
        rtxmlrpc($server, ['d.multicall2', '', 'default', 'd.name=', 'd.hash=', 'd.size_bytes=', 'd.bytes_done=', 'd.is_private='], sub {
            my ($output) = @_;
            if($output =~ /ERROR/) {
                $output = undef;
            }
            $callback->($output);
        });
    }

    sub torrent_file_information {
        my ($server, $infohash, $name, $cb) = @_;
        rtxmlrpc($server, ['f.multicall', $infohash, '', 'f.path=', 'f.size_bytes='], sub {
        my ($output) = @_;
        if($output =~ /ERROR/) {
            $output = undef;
        }

        # pase the name and size arrays
        my %files;
        my @lines = split(/\n/, $output);
        while(1) {
            my $line = shift @lines;
            last if(!defined $line);
            if(substr($line, 0, 1) ne '[') {
                say "fail parse";
                $cb->(undef);
                return;
            }
            while(substr($line, -1) ne ']') {
                my $newline = shift @lines;
                if(!defined $newline) {
                    say "fail parse";
                    $cb->(undef);
                    return;
                }
                $line .= $newline;
            }
            my ($file, $size) = $line =~ /^\[.(.+).,\s(\d+)\]$/;
            if((! defined $file) || (!defined $size)) {
                say "fail parse";
                $cb->(undef);
                return;
            }
            $files{$file} = {'size' => $size};
        }

        my @fkeys = (keys %files);
        if(@fkeys == 1) {
            my $key = $fkeys[0];
            torrent_d_is_multi_file($server, $infohash, sub {
            my ($res) = @_;
            if(! defined $res) {
                $cb->(undef);
            }
            if($res == 1) {
                %files = (   $name . '/' . $key => $files{$key});
            }
            $cb->(\%files);
            });
            return;
        }
        my %newfiles;
        foreach my $key (@fkeys) {
            $newfiles{$name . '/' . $key} = $files{$key};
        }
        $cb->(\%newfiles);
        });
    }

    sub torrent_start {
        my ($server, $torrentData, $saveto, $cb) = @_;
        my $torrent = MHFS::BitTorrent::Metainfo::Parse($torrentData);
        if(! $torrent) {
            $cb->{on_failure}->(); return;
        }
        my $asciihash = $torrent->InfohashAsHex();
        say 'infohash ' . $asciihash;

        # see if the hash is already in rtorrent
        torrent_d_bytes_done($server, $asciihash, sub {
        my ($bytes_done) = @_;
        if(! defined $bytes_done) {
            # load, set directory, and download it (race condition)
            # 02/05/2020 what race condition?
            torrent_load_raw_verbose($server, $$torrentData, sub {
            if(! defined $_[0]) { $cb->{on_failure}->(); return;}

            torrent_d_directory_set($server, $asciihash, $saveto, sub {
            if(! defined $_[0]) { $cb->{on_failure}->(); return;}

            torrent_d_start($server, $asciihash, sub {
            if(! defined $_[0]) { $cb->{on_failure}->(); return;}

            say 'starting ' . $asciihash;
            $cb->{on_success}->($asciihash);
            })})});
        }
        else {
            # set the priority and download
            torrent_set_priority($server, $asciihash, '1', sub {
            if(! defined $_[0]) { $cb->{on_failure}->(); return;}

            torrent_d_start($server, $asciihash, sub {
            if(! defined $_[0]) { $cb->{on_failure}->(); return;}

            say 'starting (existing) ' . $asciihash;
            $cb->{on_success}->($asciihash);
            })});
        }
        });
    }

    1;
}

package MHFS::Plugin::MusicLibrary {
    use strict; use warnings;
    use feature 'say';
    use Cwd qw(abs_path getcwd);
    use File::Find;
    use Data::Dumper;
    use Devel::Peek;
    use Fcntl ':mode';
    use File::stat;
    use File::Basename;
    use File::Path qw(make_path);
    use Scalar::Util qw(looks_like_number);
    MHFS::Util->import();
    BEGIN {
        if( ! (eval "use JSON; 1")) {
            eval "use JSON::PP; 1" or die "No implementation of JSON available";
            warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
        }
    }
    use Encode qw(decode encode);
    use URI::Escape;
    use Storable qw(dclone);
    use Fcntl ':mode';
    use Time::HiRes qw( usleep clock_gettime CLOCK_REALTIME CLOCK_MONOTONIC);
    use Scalar::Util qw(looks_like_number weaken);
    use POSIX qw/ceil/;
    use Storable qw( freeze thaw);
    #use ExtUtils::testlib;
    use FindBin;
    use File::Spec;
    use List::Util qw[min max];
    use HTML::Template;

    # Optional dependency, MHFS::XS
    BEGIN {
        use constant HAS_MHFS_XS => (eval "use MHFS::XS; 1");
        if(! HAS_MHFS_XS) {
            warn __PACKAGE__.": XS not available";
        }
    }

    # read the directory tree from desk and store
    # this assumes filenames are UTF-8ish, the octlets will be the actual filename, but the printable filename is created by decoding it as UTF-8
    sub BuildLibrary {
        my ($path) = @_;
        my $statinfo = stat($path);
        return undef if(! $statinfo);
        my $basepath = basename($path);
        my $utf8name = get_printable_utf8($basepath);

        if(!S_ISDIR($statinfo->mode)){
        return undef if($path !~ /\.(flac|mp3|m4a|wav|ogg|webm)$/);
            return [$basepath, $statinfo->size, undef, $utf8name];
        }
        else {
            my $dir;
            if(! opendir($dir, $path)) {
                warn "outputdir: Cannot open directory: $path $!";
                return undef;
            }
            my @files = sort { uc($a) cmp uc($b)} (readdir $dir);
            closedir($dir);
            my @tree;
            my $size = 0;
            foreach my $file (@files) {
                next if(($file eq '.') || ($file eq '..'));
                if(my $file = BuildLibrary("$path/$file")) {
                        push @tree, $file;
                        $size += $file->[1];
                }
            }
            return undef if( $size eq 0);
            return [$basepath, $size, \@tree, $utf8name];
       }
    }

    sub ToHTML {
        my ($files, $where) = @_;
        $where //= '';
        my $buf = '';
        #my $name_unencoded = decode('UTF-8', $files->[0]);
        my $name_unencoded = $files->[3];
        my $name = ${escape_html_noquote($name_unencoded)};
        if($files->[2]) {
            my $dir = $files->[0];
            $buf .= '<tr>';
            $buf .= '<td>';
            $buf .= '<table border="1" class="tbl_track">';
            $buf .= '<tbody>';
            $buf .= '<tr class="track">';
            $buf .= '<th>' . $name . '</th>';
            $buf .= '<th><a href="#">Play</a></th><th><a href="#">Queue</a></th><th><a href="music_dl?action=dl&name=' . uri_escape_utf8($where.$name_unencoded) . '">DL</a></th>';
            $buf .= '</tr>';
            $where .= $name_unencoded . '/';
            foreach my $file (@{$files->[2]}) {
                $buf .= ToHTML($file, $where) ;
            }
            $buf .= '</tbody></table>';
            $buf .= '</td>';

        }
        else {
            if($where eq '') {
                 $buf .= '<table border="1" class="tbl_track">';
                 $buf .= '<tbody>';
            }
            $buf .= '<tr class="track">';
            $buf .= '<td>' . $name . '</td>';
            $buf .= '<td><a href="#">Play</a></td><td><a href="#">Queue</a></td><td><a href="music_dl?action=dl&name=' . uri_escape_utf8($where.$name_unencoded).'">DL</a></td>';
            if($where eq '') {
                 $buf .= '</tr>';
                 $buf .= '</tbody></table>';
                 return $buf;
            }
        }
        $buf .= '</tr>';
        return $buf;
    }

    sub toJSON {
        my ($self) = @_;
        my $head = {'files' => []};
        my @nodestack = ($head);
        my @files = (@{$self->{'library'}});
        while(@files) {
            my $file = shift @files;
            if( ! $file) {
                pop @nodestack;
                next;
            }
            my $node = $nodestack[@nodestack - 1];
            #my $newnode = {'name' => decode('UTF-8', $file->[0])};
            my $newnode = {'name' =>$file->[3]};
            if($file->[2]) {
                $newnode->{'files'} = [];
                push @nodestack, $newnode;
                @files = (@{$file->[2]}, undef, @files);
            }
            push @{$node->{'files'}}, $newnode;
        }
        # encode json outputs bytes NOT unicode string
        return encode_json($head);
    }


    sub LibraryHTML {
        my ($self) = @_;
        my $buf = '';
        foreach my $file (@{$self->{'library'}}) {
            $buf .= ToHTML($file);
            $buf .= '<br>';
        }

        my $legacy_template = HTML::Template->new(filename => 'templates/music_legacy.html', path => $self->{'settings'}{'APPDIR'} );
        $legacy_template->param(musicdb => $buf);
        $self->{'html'} = encode('UTF-8', $legacy_template->output, Encode::FB_CROAK);

        $self->{'musicdbhtml'} = encode('UTF-8', $buf, Encode::FB_CROAK);
        $self->{'musicdbjson'} = toJSON($self);
    }

    sub SendLibrary {
        my ($self, $request) = @_;

        # maybe not allow everyone to do these commands?
        if($request->{'qs'}{'forcerefresh'}) {
            say __PACKAGE__.": forcerefresh";
            $self->BuildLibraries();
        }
        elsif($request->{'qs'}{'refresh'}) {
            say __PACKAGE__.": refresh";
            UpdateLibrariesAsync($self, $request->{'client'}{'server'}{'evp'}, sub {
                say __PACKAGE__.": refresh done";
                $request->{'qs'}{'refresh'} = 0;
                SendLibrary($self, $request);
            });
            return 1;
        }

        # deduce the format if not provided
        my $fmt = $request->{'qs'}{'fmt'};
        if(! $fmt) {
            $fmt = 'worklet';
            my $fallback = 'musicinc';
            if($request->{'header'}{'User-Agent'} =~ /Chrome\/([^\.]+)/) {
                my $ver = $1;
                # SharedArrayBuffer support with spectre/meltdown fixes was added in 68
                # AudioWorklet on linux had awful glitching until somewhere in 92 https://bugs.chromium.org/p/chromium/issues/detail?id=825823
                if($ver < 93) {
                    if(($ver < 68) || ($request->{'header'}{'User-Agent'} =~ /Linux/)) {
                        $fmt = $fallback;
                    }
                }
            }
            elsif($request->{'header'}{'User-Agent'} =~ /Firefox\/([^\.]+)/) {
                my $ver = $1;
                # SharedArrayBuffer support with spectre/meltdown fixes was added in 79
                if($ver < 79) {
                    $fmt = $fallback;
                }
            }
            else {
                # Hope for the best, assume worklet works
            }

            # leave this here for now to not break the segment based players
            if($request->{'qs'}{'segments'}) {
                $fmt = $fallback;
            }
        }

        # route
        my $qs = defined($request->{'qs'}{'ptrack'}) ? {'ptrack' => $request->{'qs'}{'ptrack'}} : undef;
        if($fmt eq 'worklet') {
            return $request->SendRedirect(307, 'static/music_worklet_inprogress/', $qs);
        }
        elsif($fmt eq 'musicdbjson') {
            return $request->SendBytes('application/json', $self->{'musicdbjson'});
        }
        elsif($fmt eq 'musicdbhtml') {
            return $request->SendBytes("text/html; charset=utf-8", $self->{'musicdbhtml'});
        }
        elsif($fmt eq 'gapless') {
            $qs->{fmt} = 'musicinc';
            return $request->SendRedirect(301, "music", $qs);
        }
        elsif($fmt eq 'musicinc') {
            return $request->SendRedirect(307, 'static/music_inc/', $qs);
        }
        elsif($fmt eq 'legacy') {
            say __PACKAGE__.": legacy";
            return $request->SendBytes("text/html; charset=utf-8", $self->{'html'});
        }
        else {
            return $request->Send404;
        }
    }

    my $SEGMENT_DURATION = 5;
    my %TRACKDURATION;
    my %TRACKINFO;
    sub SendTrack {
        my ($request, $tosend) = @_;
        if(defined $request->{'qs'}{'part'}) {
            if(! HAS_MHFS_XS) {
                say __PACKAGE__.": route not available without XS";
                $request->Send503();
                return;
            }

            if(! $TRACKDURATION{$tosend}) {
                say __PACKAGE__.": failed to get track duration";
                $request->Send503();
                return;
            }

            say "no proc, duration cached";
            my $pv = MHFS::XS::new($tosend);
            $request->{'outheaders'}{'X-MHFS-NUMSEGMENTS'} = ceil($TRACKDURATION{$tosend} / $SEGMENT_DURATION);
            $request->{'outheaders'}{'X-MHFS-TRACKDURATION'} = $TRACKDURATION{$tosend};
            $request->{'outheaders'}{'X-MHFS-MAXSEGDURATION'} = $SEGMENT_DURATION;
            my $samples_per_seg = $TRACKINFO{$tosend}{'SAMPLERATE'} * $SEGMENT_DURATION;
            my $spos = $samples_per_seg * ($request->{'qs'}{'part'} - 1);
            my $samples_left = $TRACKINFO{$tosend}{'TOTALSAMPLES'} - $spos;
            my $res = MHFS::XS::get_flac($pv, $spos, $samples_per_seg < $samples_left ? $samples_per_seg : $samples_left);
            $request->SendBytes('audio/flac', $res);
        }
        elsif(defined $request->{'qs'}{'fmt'} && ($request->{'qs'}{'fmt'}  eq 'wav')) {
            if(! HAS_MHFS_XS) {
                say __PACKAGE__.": route not available without XS";
                $request->Send503();
                return;
            }

            my $pv = MHFS::XS::new($tosend);
            my $outbuf = '';
            my $wavsize = (44+ $TRACKINFO{$tosend}{'TOTALSAMPLES'} * ($TRACKINFO{$tosend}{'BITSPERSAMPLE'}/8) * $TRACKINFO{$tosend}{'NUMCHANNELS'});
            my $startbyte = $request->{'header'}{'_RangeStart'} || 0;
            my $endbyte = $request->{'header'}{'_RangeEnd'} // $wavsize-1;
            say "start byte" . $startbyte;
            say "end byte " . $endbyte;
            say "MHFS::XS::wavvfs_read_range " . $startbyte . ' ' . $endbyte;
            my $maxsendsize;
            $maxsendsize = 1048576/2;
            say "maxsendsize $maxsendsize " . ' bytespersample ' . ($TRACKINFO{$tosend}{'BITSPERSAMPLE'}/8) . ' numchannels ' . $TRACKINFO{$tosend}{'NUMCHANNELS'};
            $request->SendCallback(sub{
                my ($fileitem) = @_;
                my $actual_endbyte = $startbyte + $maxsendsize - 1;
                if($actual_endbyte >= $endbyte) {
                    $actual_endbyte = $endbyte;
                    $fileitem->{'cb'} = undef;
                    say "SendCallback last send";
                }
                my $actual_startbyte = $startbyte;
                $startbyte = $actual_endbyte+1;
                say "SendCallback wavvfs_read_range " . $actual_startbyte . ' ' . $actual_endbyte;
                return MHFS::XS::wavvfs_read_range($pv, $actual_startbyte, $actual_endbyte);
            }, {
                'mime' => 'audio/wav',
                'size' => $wavsize,
            });

        }
        else {
            if($request->{'qs'}{'action'} && ($request->{'qs'}{'action'} eq 'dl')) {
                $request->{'responseopt'}{'cd_file'} = 'attachment';
            }
            # Send the total pcm frame count for mp3
            elsif(lc(substr($tosend, -4)) eq '.mp3') {
                if(HAS_MHFS_XS) {
                    if(! $TRACKINFO{$tosend}) {
                        $TRACKINFO{$tosend} = { 'TOTALSAMPLES' => MHFS::XS::get_totalPCMFrameCount($tosend) };
                        say "mp3 totalPCMFrames: " . $TRACKINFO{$tosend}{'TOTALSAMPLES'};
                    }
                    $request->{'outheaders'}{'X-MHFS-totalPCMFrameCount'} = $TRACKINFO{$tosend}{'TOTALSAMPLES'};
                }
            }
            $request->SendLocalFile($tosend);
        }
    }

    sub parseStreamInfo {
        # https://metacpan.org/source/DANIEL/Audio-FLAC-Header-2.4/Header.pm
        my ($buf) = @_;
        my $metaBinString = unpack('B144', $buf);

        my $x32 = 0 x 32;
        my $info = {};
        $info->{'MINIMUMBLOCKSIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 0, 16), -32)));
        $info->{'MAXIMUMBLOCKSIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 16, 16), -32)));
        $info->{'MINIMUMFRAMESIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 32, 24), -32)));
        $info->{'MAXIMUMFRAMESIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 56, 24), -32)));

        $info->{'SAMPLERATE'}       = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 80, 20), -32)));
        $info->{'NUMCHANNELS'}      = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 100, 3), -32))) + 1;
        $info->{'BITSPERSAMPLE'}    = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 103, 5), -32))) + 1;

        # Calculate total samples in two parts
        my $highBits = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 108, 4), -32)));

        $info->{'TOTALSAMPLES'} = $highBits * 2 ** 32 +
                unpack('N', pack('B32', substr($x32 . substr($metaBinString, 112, 32), -32)));

        # Return the MD5 as a 32-character hexadecimal string
        $info->{'MD5CHECKSUM'} = unpack('H32',substr($buf, 18, 16));
        return $info;
    }

    sub GetTrackInfo {
        my ($file) = @_;
        open(my $fh, '<', $file) or die "open failed";
        my $buf = '';
        seek($fh, 8, 0) or die "seek failed";
        (read($fh, $buf, 34) == 34) or die "short read";
        my $info = parseStreamInfo($buf);
        $info->{'duration'} = $info->{'TOTALSAMPLES'}/$info->{'SAMPLERATE'};
        print Dumper($info);
        return $info;
    }

    sub SendLocalTrack {
        my ($request, $file) = @_;

        # fast path, just send the file
        my $justsendfile = (!defined($request->{'qs'}{'fmt'})) && (!defined($request->{'qs'}{'max_sample_rate'})) && (!defined($request->{'qs'}{'bitdepth'})) && (!defined($request->{'qs'}{'part'}));
        if($justsendfile) {
            SendTrack($request, $file);
            return;
        }

        my $evp = $request->{'client'}{'server'}{'evp'};
        my $tmpfileloc = $request->{'client'}{'server'}{'settings'}{'MUSIC_TMPDIR'} . '/';
        my $nameloc = $request->{'localtrack'}{'nameloc'};
        $tmpfileloc .= $nameloc if($nameloc);
        my $filebase = $request->{'localtrack'}{'basename'};

        # convert to lossy flac if necessary
        my $is_flac = lc(substr($file, -5)) eq '.flac';
        if(!$is_flac) {
            $filebase =~ s/\.[^.]+$/.lossy.flac/;
            $request->{'localtrack'}{'basename'} = $filebase;
            my $tlossy = $tmpfileloc . $filebase;
            if(-e $tlossy ) {
                $is_flac = 1;
                $file = $tlossy;

                if(defined LOCK_GET_LOCKDATA($tlossy)) {
                     # unlikely
                    say "SendLocalTrack: lossy flac exists and is locked 503";
                    $request->Send503;
                    return;
                }
            }
            else {
                make_path($tmpfileloc, {chmod => 0755});
                my @cmd = ('ffmpeg', '-i', $file, '-c:a', 'flac', '-sample_fmt', 's16', $tlossy);
                my $buf;
                if(LOCK_WRITE($tlossy)) {
                    $request->{'process'} = MHFS::Process->new(\@cmd, $evp, {
                    'SIGCHLD' => sub {
                        UNLOCK_WRITE($tlossy);
                        SendLocalTrack($request,$tlossy);
                    },
                    'STDERR' => sub {
                        my ($terr) = @_;
                        read($terr, $buf, 4096);
                    }});
                }
                else {
                    # unlikely
                    say "SendLocalTrack: lossy flac is locked 503";
                    $request->Send503;
                }

                return;
            }
        }

        # everything should be flac now, grab the track info
        if(!defined($TRACKINFO{$file}))
        {
            $TRACKINFO{$file} = GetTrackInfo($file);
            $TRACKDURATION{$file} = $TRACKINFO{$file}{'duration'};
        }

        my $max_sample_rate = $request->{'qs'}{'max_sample_rate'} // 192000;
        my $bitdepth = $request->{'qs'}{'bitdepth'} // ($max_sample_rate > 48000 ? 24 : 16);

        # check to see if the raw file fullfills the requirements
        my $samplerate = $TRACKINFO{$file}{'SAMPLERATE'};
        my $inbitdepth = $TRACKINFO{$file}{'BITSPERSAMPLE'};
        say "input: samplerate $samplerate inbitdepth $inbitdepth";
        say "maxsamplerate $max_sample_rate bitdepth $bitdepth";
        if(($samplerate <= $max_sample_rate) && ($inbitdepth <= $bitdepth)) {
            say "samplerate is <= max_sample_rate, not resampling";
            SendTrack($request, $file);
            return;
        }

        # determine the acceptable samplerate, bitdepth combinations to send
        my %rates = (
            '48000' => [192000, 96000, 48000],
            '44100' => [176400, 88200, 44100]
        );
        my @acceptable_settings = ( [24, 192000], [24, 96000], [24, 48000], [24, 176400],  [24, 88200], [16, 48000], [16, 44100]);
        my @desired = ([$bitdepth, $max_sample_rate]);
        foreach my $setting (@acceptable_settings) {
            if(($setting->[0] <= $bitdepth) && ($setting->[1] <= $max_sample_rate)) {
                push @desired, $setting;
            }
        }

        # if we already transcoded/resampled, don't waste time doing it again
        foreach my $setting (@desired) {
            my $tmpfile = $tmpfileloc . $setting->[0] . '_' . $setting->[1] . '_' . $filebase;
            if(-e $tmpfile) {
                say "No need to resample $tmpfile exists";
                SendTrack($request, $tmpfile);
                return;
            }
        }
        make_path($tmpfileloc, {chmod => 0755});

        # resampling
        my $desiredrate;
        RATE_FACTOR: foreach my $key (keys %rates) {
            if(($samplerate % $key) == 0) {
                foreach my $rate (@{$rates{$key}}) {
                    if(($rate <= $samplerate) && ($rate <= $max_sample_rate)) {
                        $desiredrate = $rate;
                        last RATE_FACTOR;
                    }
                }
            }
        }
        $desiredrate //= $max_sample_rate;
        say "desired rate: $desiredrate";
        # build the command
        my $outfile = $tmpfileloc . $bitdepth . '_' . $desiredrate . '_' . $filebase;
        my @cmd = ('sox', $file, '-G', '-b', $bitdepth, $outfile, 'rate', '-v', '-L', $desiredrate, 'dither');
        say "cmd: " . join(' ', @cmd);

        if(LOCK_WRITE($outfile)) {
            $request->{'process'} = MHFS::Process->new(\@cmd, $evp, {
            'SIGCHLD' => sub {
                UNLOCK_WRITE($outfile);
                # BUG? files isn't necessarily flushed to disk on SIGCHLD. filesize can be wrong
                SendTrack($request, $outfile);
            },
            'STDERR' => sub {
                my ($terr) = @_;
                my $buf;
                read($terr, $buf, 4096);
            }});
        }
        else {
            # unlikely
            say "SendLocalTrack: sox is locked 503";
            $request->Send503;
        }
        return;
    }


    sub BuildLibraries {
        my ($self) = @_;
        my @wholeLibrary;

        $self->{'sources'} = [];

        foreach my $sid (@{$self->{'settings'}{'MEDIASOURCES'}{'music'}}) {
            my $source = $self->{'settings'}{'SOURCES'}{$sid};
            my $lib;
            if($source->{'type'} eq 'local') {
                say __PACKAGE__.": building music " . clock_gettime(CLOCK_MONOTONIC);
                $lib = BuildLibrary($source->{'folder'});
                say __PACKAGE__.": done building music " . clock_gettime(CLOCK_MONOTONIC);
            }
            elsif($source->{'type'} eq 'ssh') {
            }
            elsif($source->{'type'} eq 'mhfs') {
            }

            if(!$lib) {
                warn "invalid source: " . $source->{'type'};
                warn 'folder: '. $source->{'folder'} if($source->{'type'} eq 'local');
                next;
            }
            push @{$self->{'sources'}}, [$sid, $lib];
            OUTER: foreach my $item (@{$lib->[2]}) {
                foreach my $already (@wholeLibrary) {
                    next OUTER if($already->[0] eq $item->[0]);
                }
                push @wholeLibrary, $item;
            }
        }
        $self->{'library'} = \@wholeLibrary;
        $self->LibraryHTML;
        return \@wholeLibrary;
    }

    sub FindInLibrary {
        my ($self, $msource, $name) = @_;
        my @namearr = split('/', $name);
        my $finalstring = $self->{'settings'}{'SOURCES'}{$msource->[0]}{'folder'};
        my $lib = $msource->[1];
        FindInLibrary_Outer: foreach my $component (@namearr) {
            foreach my $libcomponent (@{$lib->[2]}) {
                if($libcomponent->[3] eq $component) {
                     $finalstring .= "/".$libcomponent->[0];
                    $lib = $libcomponent;
                    next FindInLibrary_Outer;
                }
            }
            return undef;
        }
        return {
            'node' => $lib,
            'path' => $finalstring
        };
    }

    # Define source types here
    my %sendFiles = (
        'local' => sub {
            my ($request, $file, $node, $source, $nameloc) = @_;
            return undef if(! -e $file);
            if( ! -d $file) {
                $request->{'localtrack'} = { 'nameloc' => $nameloc, 'basename' => $node->[0]};
                SendLocalTrack($request, $file);
            }
            else {
                $request->SendAsTar($file);
            }
            return 1;
        },
        'mhfs' => sub {
            my ($request, $file, $node, $source) = @_;
            return $request->Proxy($source, $node);
        },
        'ssh' => sub {
            my ($request, $file, $node, $source) = @_;
            return $request->SendFromSSH($source, $file, $node);
        },
    );

    sub SendFromLibrary {
        my ($self, $request) = @_;
        my $utf8name = decode('UTF-8', $request->{'qs'}{'name'});
        foreach my $msource (@{$self->{'sources'}}) {
            my $node = $self->FindInLibrary($msource, $utf8name);
            next if ! $node;

            my $nameloc;
            if($utf8name =~ /(.+\/).+$/) {
                $nameloc  = $1;
            }
            my $source = $self->{'settings'}{'SOURCES'}{$msource->[0]};
            if($sendFiles{$source->{'type'}}->($request, $node->{'path'}, $node->{'node'}, $source, $nameloc)) {
                return 1;
            }
        }
        say "SendFromLibrary: did not find in library, 404ing";
        say "name: " . $request->{'qs'}{'name'};
        $request->Send404;
    }

    sub SendResources {
        my ($self, $request) = @_;

        if(! HAS_MHFS_XS) {
            say __PACKAGE__.": route not available without XS";
            $request->Send503();
            return;
        }

        my $utf8name = decode('UTF-8', $request->{'qs'}{'name'});
        foreach my $msource (@{$self->{'sources'}}) {
            my $node = $self->FindInLibrary($msource, $utf8name);
            next if ! $node;
            my $comments = MHFS::XS::get_vorbis_comments($node->{'path'});
            my $commenthash = {};
            foreach my $comment (@{$comments}) {
                $comment = decode('UTF-8', $comment);
                my ($key, $value) = split('=', $comment);
                $commenthash->{$key} = $value;
            }
            $request->SendAsJSON($commenthash);
            return 1;
        }
        say "SendFromLibrary: did not find in library, 404ing";
        say "name: " . $request->{'qs'}{'name'};
        $request->Send404;
    }

    sub SendArt {
        my ($self, $request) = @_;

        my $utf8name = decode('UTF-8', $request->{'qs'}{'name'});
        foreach my $msource (@{$self->{'sources'}}) {
            my $node = $self->FindInLibrary($msource, $utf8name);
            next if ! $node;

            my $dname = $node->{'path'};
            my $dh;
            if(! opendir($dh, $dname)) {
                $dname = dirname($node->{'path'});
                if(! opendir($dh, $dname)) {
                    $request->Send404;
                    return 1;
                }
            }

            # scan dir for art
            my @files;
            while(my $fname = readdir($dh)) {
                my $last = lc(substr($fname, -4));
                push @files, $fname if(($last eq '.png') || ($last eq '.jpg') || ($last eq 'jpeg'));
            }
            closedir($dh);
            if( ! @files) {
                $request->Send404;
                return 1;
            }
            my $tosend = "$dname/" . $files[0];
            foreach my $file (@files) {
               foreach my $expname ('cover', 'front', 'album') {
                    if(substr($file, 0, length($expname)) eq $expname) {
                        $tosend = "$dname/$file";
                        last;
                    }
               }
            }
            say "tosend $tosend";
            $request->SendLocalFile($tosend);
            return 1;
        }
    }

    sub UpdateLibrariesAsync {
        my ($self, $evp, $onUpdateEnd) = @_;
        MHFS::Process->new_output_child($evp, sub {
            # done in child
            my ($datachannel) = @_;

            # save references to before
            my @potentialupdates = ('html', 'musicdbhtml', 'musicdbjson');
            my %before;
            foreach my $pupdate (@potentialupdates) {
                $before{$pupdate} = $self->{$pupdate};
            }

            # build the new libraries
            $self->BuildLibraries();

            # determine what needs to be updated
            my @updates = (['sources', $self->{'sources'}]);
            foreach my $pupdate(@potentialupdates) {
                if($before{$pupdate} ne $self->{$pupdate}) {
                    push @updates, [$pupdate, $self->{$pupdate}];
                }
            }

            # serialize and output
            my $pipedata = freeze(\@updates);
            print $datachannel $pipedata;
            exit 0;
        }, sub {
            my ($out, $err) = @_;
            say "BEGIN_FROM_CHILD---------";
            print $err;
            say "END_FROM_CHILD-----------";
            my $unthawed;
            {
                local $@;
                unless (eval {
                    $unthawed = thaw($out);
                    return 1;
                }) {
                    warn("thaw threw exception");
                }
            }
            if($unthawed){
                foreach my $update (@$unthawed) {
                    say "Updating " . $update->[0];
                    $self->{$update->[0]} = $update->[1];
                }
            }
            else {
                say "failed to thaw, library not updated.";
            }
            $onUpdateEnd->();
        });
    }

    sub new {
        my ($class, $settings) = @_;
        my $self =  {'settings' => $settings};
        bless $self, $class;
        my $pstart = __PACKAGE__.":";

        # no sources until loaded
        $self->{'sources'} = [];
        $self->{'html'} = __PACKAGE__.' not loaded';
        $self->{'musicdbhtml'} = __PACKAGE__.' not loaded';
        $self->{'musicdbjson'} = '{}';

        my $musicpageroute = sub {
            my ($request) = @_;
            return $self->SendLibrary($request);
        };

        my $musicdlroute = sub {
            my ($request) = @_;
            return $self->SendFromLibrary($request);
        };

        my $musicresourcesroute = sub {
            my ($request) = @_;
            return $self->SendResources($request);
        };

        $self->{'routes'} = [
            ['/music', $musicpageroute],
            ['/music_dl', $musicdlroute],
            ['/music_resources', $musicresourcesroute],
            ['/music_art', sub {
                my ($request) = @_;
                return $self->SendArt($request);
            }]
        ];

        $self->{'timers'} = [
            # update the library at start and periodically
            [0, 300, sub {
                my ($timer, $current_time, $evp) = @_;
                say "$pstart library timer";
                UpdateLibrariesAsync($self, $evp, sub {
                    say "$pstart library timer done";
                });
                return 1;
            }],
        ];

        return $self;
    }

    1;
}

package MHFS::Plugin::Youtube {
    use strict; use warnings;
    use feature 'say';
    use Data::Dumper;
    use feature 'state';
    use Encode;
    use URI::Escape;
    use Scalar::Util qw(looks_like_number weaken);
    use File::stat;
    MHFS::Util->import();
    BEGIN {
        if( ! (eval "use JSON; 1")) {
            eval "use JSON::PP; 1" or die "No implementation of JSON available";
            warn __PACKAGE__.": Using PurePerl version of JSON (JSON::PP)";
        }
    }

    sub searchbox {
        my ($self, $request) = @_;
        #my $html = '<form  name="searchbox" action="' . $request->{'path'}{'basename'} . '">';
        my $html = '<form  name="searchbox" action="yt">';
        $html .= '<input type="text" width="50%" name="q" ';
        my $query = $request->{'qs'}{'q'};
        if($query) {
            $query =~ s/\+/ /g;
            my $escaped = escape_html($query);
            $html .= 'value="' . $$escaped . '"';
        }
        $html .=  '>';
        if($request->{'qs'}{'media'}) {
            $html .= '<input type="hidden" name="media" value="' . $request->{'qs'}{'media'} . '">';
        }
        $html .= '<input type="submit" value="Search">';
        $html .= '</form>';
        return $html;
    }

    sub ytplayer {
        my ($self, $request) = @_;
        my $html = '<meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no, minimum-scale=1.0, maximum-scale=1.0" /><iframe src="static/250ms_silence.mp3" allow="autoplay" id="audio" style="display:none"></iframe>';
        my $url = 'get_video?fmt=yt&id=' . uri_escape($request->{'qs'}{'id'});
        $url .= '&media=' . uri_escape($request->{'qs'}{'media'}) if($request->{'qs'}{'media'});
        if($request->{'qs'}{'media'} && ($request->{'qs'}{'media'} eq 'music')) {
            $request->{'path'}{'basename'} = 'ytaudio';
            $html .= '<audio controls autoplay src="' . $url . '">Great Browser</audio>';
        }
        else {
            $request->{'path'}{'basename'} = 'yt';
            $html .= '<video controls autoplay src="' . $url . '">Great Browser</video>';
        }
        return $html;
    }

    sub sendAsHTML {
        my ($self, $request, $response) = @_;
        my $json = decode_json($response);
        if(! $json){
            $request->Send404;
            return;
        }
        my $html = $self->searchbox($request);
        $html .= '<div id="vidlist">';
        foreach my $item (@{$json->{'items'}}) {
            my $id = $item->{'id'}{'videoId'};
            next if (! defined $id);
            $html .= '<div>';
            my $mediaurl = 'ytplayer?fmt=yt&id=' . $id;
            my $media =  $request->{'qs'}{'media'};
            $mediaurl .= '&media=' . uri_escape($media) if(defined $media);
            $html .= '<a href="' . $mediaurl . '">' . $item->{'snippet'}{'title'} . '</a>';
            $html .= '<br>';
            $html .= '<a href="' . $mediaurl . '"><img src="' . $item->{'snippet'}{'thumbnails'}{'default'}{'url'} . '" alt="Excellent image loading"></a>';
            $html .= ' <a href="https://youtube.com/channel/' . $item->{'snippet'}{'channelId'} . '">' .  $item->{'snippet'}{'channelTitle'} . '</a>';
            $html .= '<p>' . $item->{'snippet'}{'description'} . '</p>';
            $html .= '<br>-----------------------------------------------';
            $html .= '</div>'
        }
        $html .= '</div>';
        $html .= '<script>
        var vidlist = document.getElementById("vidlist");
        vidlist.addEventListener("click", function(e) {
            console.log(e);
            let target = e.target.pathname ? e.target : e.target.parentElement;
            if(target.pathname && target.pathname.endsWith("ytplayer")) {
                e.preventDefault();
                console.log(target.href);
                let newtarget = target.href.replace("ytplayer", "ytembedplayer");
                fetch(newtarget).then( response => response.text()).then(function(data) {
                    if(data) {
                        window.history.replaceState(vidlist.innerHTML, null);
                        window.history.pushState(data, null, target.href);
                        vidlist.innerHTML = data;
                    }
                });
            }
        });

        window.onpopstate = function(event) {
            console.log(event.state);
            vidlist.innerHTML = event.state;
        }
        </script>';
        $request->SendHTML($html);
    }

    sub onYoutube {
        my ($self, $request) = @_;
        my $evp = $request->{'client'}{'server'}{'evp'};
        my $youtubequery = 'q=' . (uri_escape($request->{'qs'}{'q'}) // '') . '&maxResults=' . ($request->{'qs'}{'maxResults'} // '25') . '&part=snippet&key=' . $self->{'settings'}{'Youtube'}{'key'};
        $youtubequery .= '&type=video'; # playlists not supported yet
        my $tosend = '';
        my @curlcmd = ('curl', '-G', '-d', $youtubequery, 'https://www.googleapis.com/youtube/v3/search');
        print "$_ " foreach @curlcmd;
        print "\n";
        state $tprocess;
        $tprocess = MHFS::Process->new(\@curlcmd, $evp, {
            'SIGCHLD' => sub {
                my $stdout = $tprocess->{'fd'}{'stdout'}{'fd'};
                my $buf;
                while(length($tosend) == 0) {
                    while(read($stdout, $buf, 24000)) {
                        say "did read sigchld";
                        $tosend .= $buf;
                    }
                }
                undef $tprocess;
                $request->{'qs'}{'fmt'} //= 'html';
                if($request->{'qs'}{'fmt'} eq 'json'){
                    $request->SendBytes('application/json', $tosend);
                }
                else {
                    $self->sendAsHTML($request, $tosend);
                }
            },
        });
        $request->{'process'} = $tprocess;
        return -1;
    }

    sub downloadAndServe {
        my ($self, $request, $video) = @_;
        weaken($request);


        my $filename = $video->{'out_filepath'};
        my $sendit = sub {
            # we can send the file
            if(! $request) {
                return;
            }
            say "sending!!!!";
            $request->SendLocalFile($filename);
        };

        my $qs = $request->{'qs'};
        my @cmd = ($self->{'youtube-dl'}, '--no-part', '--print-traffic', '-f', $self->{'fmts'}{$qs->{"media"} // "video"} // "best", '-o', $video->{"out_filepath"}, '--', $qs->{"id"});
        $request->{'process'} = MHFS::Process->new_cmd_process($request->{'client'}{'server'}{'evp'}, \@cmd, {
            'on_stdout_data' => sub {
                my ($context) = @_;

                # determine the size of the file
                # relies on receiving content-length header last
                my ($cl) = $context->{'stdout'} =~ /^.*Content\-Length:\s(\d+)/s;
                return 1 if(! $cl);
                my ($cr) = $context->{'stdout'} =~ /^.*Content\-Range:\sbytes\s\d+\-\d+\/(\d+)/s;
                if($cr) {
                    say "cr $cr";
                    $cl = $cr if($cr > $cl);
                }
                say "cl is $cl";
                UNLOCK_WRITE($filename);
                LOCK_WRITE($filename, $cl);

                # make sure the file exists and within our parameters
                my $st = stat($filename);
                $st or return;
                my $minsize = 16384;
                $minsize = $cl if($cl < $minsize);
                return if($st->size < $minsize);
                say "sending, currentsize " . $st->size . ' totalsize ' . $cl;

                # dont need to check the new data anymore
                $context->{'on_stdout_data'} = undef;
                $sendit->();
                $request = undef;
            },
            'at_exit' => sub {
                my ($context) = @_;
                UNLOCK_WRITE($filename);
                # last ditch effort, try to send it if we haven't
                $sendit->();
            }
        });
        return 1;
    }

    sub getOutBase {
        my ($self, $qs) = @_;
        return undef if(! $qs->{'id'});

        my $media;
        if(defined $qs->{'media'} && (defined $self->{'fmts'}{$qs->{'media'}})) {
            $media = $qs->{'media'};
        }
        else  {
            $media = 'video';
        }
        return $qs->{'id'} . '_' . $media;
    }

    sub new {
        my ($class, $settings, $server) = @_;
        my $self =  {'settings' => $settings};
        bless $self, $class;

        $self->{'routes'} = [
        ['/youtube', sub {
            my ($request) = @_;
            $self->onYoutube($request);
        }],

        ['/yt', sub {
            my ($request) = @_;
            $self->onYoutube($request);
        }],

        ['/ytmusic', sub {
            my ($request) = @_;
            $request->{'qs'}{'media'} //= 'music';
            $self->onYoutube($request);
        }],

        ['/ytaudio', sub {
            my ($request) = @_;
            $request->{'qs'}{'media'} //= 'music';
            $self->onYoutube($request);
        }],
        ['/ytplayer', sub {
            my ($request) = @_;
            my $html = $self->searchbox($request);
            $html .= $self->ytplayer($request);
            $request->SendHTML($html);
        }],
        ['/ytembedplayer', sub {
            my ($request) = @_;
            $request->SendHTML($self->ytplayer($request));
        }],
        ];

        $self->{'fmts'} = {'music' => 'bestaudio', 'video' => 'best'};
        $self->{'minsize'} = '1048576';
        say __PACKAGE__.': adding video format yt';
        $server->{'loaded_plugins'}{'MHFS::Plugin::GetVideo'}{'VIDEOFORMATS'}{yt} = {'lock' => 1, 'ext' => 'yt', 'plugin' => $self};

        my $pstart = __PACKAGE__.": ";

        # check for youtube-dl and install if not specified
        my $youtubedl = $settings->{'Youtube'}{'youtube-dl'};
        my $installed;
        if(!$youtubedl) {
            my $mhfsytdl = $settings->{'GENERIC_TMPDIR'}.'/youtube-dl';
            if(! -e $mhfsytdl) {
                say $pstart."Attempting to download youtube-dl";
                if(system('curl', '-L', 'https://yt-dl.org/downloads/latest/youtube-dl', '-o', $mhfsytdl) != 0) {
                    say $pstart . "Failed to download youtube-dl. plugin load failed";
                    return undef;
                }
                if(system('chmod', 'a+rx', $mhfsytdl) != 0) {
                    say $pstart . "Failed to set youtube-dl permissions. plugin load failed";
                    return undef;
                }
                $installed = 1;
                say $pstart."youtube-dl successfully installed!";
            }
            $youtubedl = $mhfsytdl;
        }
        elsif( ! -e $youtubedl) {
            say $pstart . "youtube-dl not found. plugin load failed";
            return undef;
        }
        $self->{'youtube-dl'} = $youtubedl;

        # update if we didn't just install
        if(! $installed) {
            say  $pstart . "Attempting to update youtube-dl";
            if(fork() == 0)
            {
                system "$youtubedl", "-U";
                exit 0;
            }
        }

        return $self;
    }

    1;
}

package MHFS::Plugin::BitTorrent::Tracker {
    use strict; use warnings;
    use feature 'say';
    use Time::HiRes qw( clock_gettime CLOCK_MONOTONIC);
    MHFS::BitTorrent::Bencoding->import();
    use Data::Dumper;

    sub createTorrent {
        my ($self, $request) = @_;
        my $fileitem = $self->{fs}->lookup($request->{'qs'}{'name'}, $request->{'qs'}{'sid'});
        if(!$fileitem) {
            $request->Send404;
            return;
        }
        my $absurl = $request->getAbsoluteURL;
        if(! $absurl) {
            say 'unable to $request->getAbsoluteURL';
            $request->Send404;
        }
        print Dumper($fileitem);
        my $outputname = $self->{'settings'}{'MHFS_TRACKER_TORRENT_DIR'}.'/'.$fileitem->{'name'}.'.torrent';
        my %maketorrent = ( private => 1,
        dest_metafile => $outputname,
        src => $fileitem->{filepath},
        tracker => $absurl.'/torrent/tracker');
        my $server = $request->{'client'}{'server'};
        my $evp = $server->{'evp'};
        MHFS::BitTorrent::Metainfo::Create($evp, \%maketorrent, sub {

        my $torrentData = MHFS::Util::read_file($outputname);
        if(!$torrentData) {
            $request->Send404;
        }
        my $torrent = MHFS::BitTorrent::Metainfo::Parse(\$torrentData);
        if(! $torrent) {
            $request->Send404; return;
        }
        my $asciihash = $torrent->InfohashAsHex();
        say "asciihash: $asciihash";
        $self->{'torrents'}{pack('H*', $asciihash)} //= {};

        MHFS::BitTorrent::Client::torrent_start($server, \$torrentData, $fileitem->{'containingdir'}, {
            'on_success' => sub {
                $request->{'responseopt'}{'cd_file'} = 'attachment';
                $request->SendLocalFile($outputname, 'applications/x-bittorrent');
            },
            'on_failure' => sub {
                $request->Send404;
            }
        })});
    }

    sub announce_error {
        my ($message) = @_;
        return ['d', ['bstr', 'failure reason'], ['bstr', $message]];
    }

    sub peertostring {
        my ($peer) = @_;
        my @pvals = unpack('CCCCCC', $peer);
        return "$pvals[0].$pvals[1].$pvals[2].$pvals[3]:" . (($pvals[4] << 8) | $pvals[5]);
    }

    sub removeTorrentPeer {
        my ($self, $infohash, $peer, $reason) = @_;
        say __PACKAGE__.": removing torrent peer ".peertostring($peer). " - $reason";
        delete $self->{torrents}{$infohash}{$peer};
    }

    sub announce {
        my ($self, $request) = @_;

        # hide the tracker if the required parameters aren't there
        foreach my $key ('port', 'left', 'info_hash') {
            if(! exists $request->{'qs'}{$key}) {
                say __PACKAGE__.": missing $key";
                $request->Send404;
                return;
            }
        }

        my $dictref;
        while(1) {
            my $port = $request->{'qs'}{'port'};
            if($port ne unpack('S', pack('S', $port))) {
                $dictref = announce_error("bad port");
                last;
            }
            my $left = $request->{'qs'}{'left'};
            if($left ne unpack('Q', pack('Q', $left))) {
                $dictref = announce_error("bad left");
                last;
            }
            if(exists $request->{'qs'}{'compact'} && ($request->{'qs'}{'compact'} eq '0')) {
                $dictref = announce_error("Only compact responses supported!");
                last;
            }

            my $rih = $request->{'qs'}{'info_hash'};
            if(!exists $self->{torrents}{$rih}) {
                $dictref = announce_error("The torrent does not exist!");
                last;
            }

            my $ip = $request->{'ip'};
            my $ipport = pack('Nn', $ip, $port);
            say __PACKAGE__.": announce from ".peertostring($ipport);


            my $event = $request->{'qs'}{'event'};
            #if( (! exists $self->{torrents}{$rih}{$ipport}) &&
            #((! defined $event) || ($event ne 'started'))) {
            #    $dictref = announce_error("first announce must include started event");
            #    last;
            #}

            if($left == 0) {
                $self->{torrents}{$rih}{$ipport}{'completed'} = 1;
            }

            $self->{torrents}{$rih}{$ipport}{'last_announce'} = clock_gettime(CLOCK_MONOTONIC);

            if(defined $event) {
                say __PACKAGE__.": announce event $event";
                if($event eq 'started') {
                    #$self->{torrents}{$rih}{$ipport} = {'exists' => 1};
                }
                elsif($event eq 'stopped') {
                    $self->removeTorrentPeer($rih, $ipport, " received stopped message");
                }
                elsif($event eq 'completed') {
                    #$self->{torrents}{$rih}{$ipport}{'completed'} = 1;
                }
            }

            my $numwant = $request->{'qs'}{'numwant'};
            if((! defined $numwant) || ($numwant ne unpack('C', pack('C', $numwant))) || ($numwant > 55)) {
                $numwant = 50;
            }

            my @dict = ('d');
            push @dict, ['bstr', 'interval'], ['int', $self->{'announce_interval'}];
            my $complete = 0;
            my $incomplete = 0;
            my $pstr = '';
            my $i = 0;
            foreach my $peer (keys %{$self->{torrents}{$rih}}) {
                if($self->{torrents}{$rih}{$peer}{'completed'}) {
                    $complete++;
                }
                else {
                    $incomplete++;
                }
                if($i++ < $numwant) {
                    if($peer ne $ipport) {
                        my @values = unpack('CCCCCC', $peer);
                        my $netmap = $request->{'client'}{'server'}{'settings'}{'NETMAP'};
                        my $pubip = $request->{'client'}{'server'}{'settings'}{'PUBLICIP'};
                        if($netmap && (($values[0] == $netmap->[1]) && (unpack('C', $ipport) != $netmap->[1])) && $pubip) {
                            say "HACK converting local peer to public ip";
                            $peer = pack('Nn', MHFS::Util::ParseIPv4($pubip), (($values[4] << 8) | $values[5]));
                        }
                        say __PACKAGE__.": sending peer ".peertostring($peer);
                        $pstr .= $peer;
                    }
                }
            }
            #push @dict, ['bstr', 'complete'], ['int', $complete];
            #push @dict, ['bstr', 'incomplete'], ['int', $incomplete];
            push @dict, ['bstr', 'peers'], ['bstr', $pstr];

            $dictref = \@dict;
            last;
        }

        # bencode and send
        my $bdata = bencode($dictref);
        if($bdata) {
            $request->SendBytes('text/plain', $bdata);
        }
        else {
            say "Critical: Failed to bencode!";
            $request->Send404;
        }
    }

    sub new {
        my ($class, $settings, $server) = @_;
        my $ai = ($settings->{'BitTorrent::Tracker'} && $settings->{'BitTorrent::Tracker'}{'announce_interval'}) ? $settings->{'BitTorrent::Tracker'}{'announce_interval'} : undef;
        $ai //= 1800;

        my $self =  {'settings' => $settings, 'torrents' => \%{$settings->{'TORRENTS'}}, 'announce_interval' => $ai, 'fs' => $server->{'fs'}};
        bless $self, $class;
        say __PACKAGE__.": announce interval: ".$self->{'announce_interval'};

        # load the existing torrents
        my $odres = opendir(my $tdh, $settings->{'MHFS_TRACKER_TORRENT_DIR'});
        if(! $odres){
            say __PACKAGE__.":failed to open torrent dir";
            return undef;
        }
        while(my $file = readdir($tdh)) {
            next if(substr($file, 0, 1) eq '.');
            my $fullpath = $settings->{'MHFS_TRACKER_TORRENT_DIR'}."/$file";
            my $torrentcontents = MHFS::Util::read_file($fullpath);
            if(! $torrentcontents) {
                say __PACKAGE__.": error reading $fullpath";
                return undef;
            }
            my $torrent = MHFS::BitTorrent::Metainfo::Parse(\$torrentcontents);
            if(! $torrent) {
                say __PACKAGE__.": error parsing $fullpath";
                return undef;
            }
            $self->{'torrents'}{$torrent->{'infohash'}} = {};
            say __PACKAGE__.": added torrent ".$torrent->InfohashAsHex() . ' '.$file;
        }

        $self->{'routes'} = [
        ['/torrent/tracker', sub {
            my ($request) = @_;
            $self->announce($request);
        }],
        ['/torrent/create', sub {
            my ($request) = @_;
            $self->createTorrent($request);
        }],
        ];

        $self->{'timers'} = [
            # once an hour evict peers that left the swarm ungracefully
            [0, 3600, sub {
                my ($timer, $current_time, $evp) = @_;
                say __PACKAGE__.": evict peers timer";
                foreach my $infohash (keys %{$self->{'torrents'}}) {
                    foreach my $peer (keys %{$self->{'torrents'}{$infohash}}) {
                        my $peerdata = $self->{'torrents'}{$infohash}{$peer};
                        if(($current_time - $peerdata->{'last_announce'}) > ($self->{'announce_interval'}+60)) {
                            $self->removeTorrentPeer($infohash, $peer, " timeout");
                        }
                    }
                }
                return 1;
            }],
        ];

        return $self;
    }

    1;
}

package MHFS::Plugin::BitTorrent::Client::Interface {
    use strict; use warnings;
    use feature 'say';
    MHFS::Util->import(qw(escape_html do_multiples get_SI_size));
    use URI::Escape qw(uri_escape);

    sub is_video {
        my ($name) = @_;
        my ($ext) = $name =~ /\.(mkv|avi|mp4|webm|flv|ts|mpeg|mpg|m2t|m2ts|wmv)$/i;
        return $ext;
    }

    sub is_mhfs_music_playable {
        my ($name) = @_;
        return $name =~ /\.(?:flac|mp3|wav)$/i;
    }

    sub play_in_browser_link {
        my ($file, $urlfile) = @_;
        return '<a href="video?name=' . $urlfile . '&fmt=hls">HLS (Watch in browser)</a>' if(is_video($file));
        return '<a href="music?ptrack=' . $urlfile . '">Play in MHFS Music</a>' if(is_mhfs_music_playable($file));
        return 'N/A';
    }

    sub torrentview {
        my ($request) = @_;
        my $qs = $request->{'qs'};
        my $server = $request->{'client'}{'server'};
        my $evp = $server->{'evp'};
        # dump out the status, if the torrent's infohash is provided
        if(defined $qs->{'infohash'}) {
            my $hash = $qs->{'infohash'};
            do_multiples({
            'bytes_done' => sub { MHFS::BitTorrent::Client::torrent_d_bytes_done($server, $hash, @_); },
            'size_bytes' => sub { MHFS::BitTorrent::Client::torrent_d_size_bytes($server, $hash, @_); },
            'name'       => sub { MHFS::BitTorrent::Client::torrent_d_name($server, $hash, @_); },
            }, sub {
            if( ! defined $_[0]) { $request->Send404; return;}
            my ($data) = @_;
            my $torrent_raw = $data->{'name'};
            my $bytes_done  = $data->{'bytes_done'};
            my $size_bytes  = $data->{'size_bytes'};
            # print out the current torrent status
            my $torrent_name = ${escape_html($torrent_raw)};
            my $size_print = get_SI_size($size_bytes);
            my $done_print = get_SI_size($bytes_done);
            my $percent_print = (sprintf "%u%%", ($bytes_done/$size_bytes)*100);
            my $buf = '<h1>Torrent</h1>';
            $buf  .=  '<h3><a href="../video">Video</a> | <a href="../music">Music</a></h3>';
            $buf   .= '<table border="1" >';
            $buf   .= '<thead><tr><th>Name</th><th>Size</th><th>Done</th><th>Downloaded</th></tr></thead>';
            $buf   .= "<tbody><tr><td>$torrent_name</td><td>$size_print</td><td>$percent_print</td><td>$done_print</td></tr></tbody>";
            $buf   .= '</table>';

            # Assume we are downloading, if the bytes don't match
            if($bytes_done < $size_bytes) {
                $buf   .= '<meta http-equiv="refresh" content="3">';
                $request->SendHTML($buf);
            }
            else {
                # print out the files with usage options
                MHFS::BitTorrent::Client::torrent_file_information($server, $qs->{'infohash'}, $torrent_raw, sub {
                if(! defined $_[0]){ $request->Send404; return; };
                my ($tfi) = @_;
                my @files = sort (keys %$tfi);
                $buf .= '<br>';
                $buf .= '<table border="1" >';
                $buf .= '<thead><tr><th>File</th><th>Size</th><th>DL</th><th>Play in browser</th></tr></thead>';
                $buf .= '<tbody';
                foreach my $file (@files) {
                    my $htmlfile = ${escape_html($file)};
                    my $urlfile = uri_escape($file);
                    my $link = '<a href="get_video?name=' . $urlfile . '&fmt=noconv">DL</a>';
                    my $playlink = play_in_browser_link($file, $urlfile);
                    $buf .= "<tr><td>$htmlfile</td><td>" . get_SI_size($tfi->{$file}{'size'}) . "</td><td>$link</td>";
                    $buf .= "<td>$playlink</td>" if(!defined($qs->{'playinbrowser'}) || ($qs->{'playinbrowser'} == 1));
                    $buf .= "</tr>";
                }
                $buf .= '</tbody';
                $buf .= '</table>';

                $request->SendHTML($buf);
                });
            }

            });
        }
        else {
            MHFS::BitTorrent::Client::torrent_list_torrents($server, sub{
                if(! defined $_[0]){ $request->Send404; return; };
                my ($rtresponse) = @_;
                my @lines = split( /\n/, $rtresponse);
                my $buf = '<h1>Torrents</h1>';
                $buf  .=  '<h3><a href="video?action=browsemovies">Browse Movies</a> | <a href="video">Video</a> | <a href="music">Music</a></h3>';
                $buf   .= '<table border="1" >';
                $buf   .= '<thead><tr><th>Name</th><th>Hash</th><th>Size</th><th>Done</th><th>Private</th></tr></thead>';
                $buf   .= "<tbody>";
                my $curtor = '';
                while(1) {
                    if($curtor =~ /^\[(u?)['"](.+)['"],\s'(.+)',\s([0-9]+),\s([0-9]+),\s([0-9]+)\]$/) {
                        my %torrent;
                        my $is_unicode = $1;
                        $torrent{'name'} = $2;
                        $torrent{'hash'} = $3;
                        $torrent{'size_bytes'} = $4;
                        $torrent{'bytes_done'} = $5;
                        $torrent{'private'} = $6;
                        if($is_unicode) {
                            my $escaped_unicode = $torrent{'name'};
                            $torrent{'name'} =~ s/\\u(.{4})/chr(hex($1))/eg;
                            $torrent{'name'} =~ s/\\x(.{2})/chr(hex($1))/eg;
                            my $decoded_as = $torrent{'name'};
                            $torrent{'name'} = ${escape_html($torrent{'name'})};
                            if($qs->{'logunicode'}) {
                                say 'unicode escaped: ' . $escaped_unicode;
                                say 'decoded as: ' . $decoded_as;
                                say 'html escaped ' . $torrent{'name'};
                            }
                        }
                        $buf .= '<tr><td>' . $torrent{'name'} . '</td><td>' . $torrent{'hash'} . '</td><td>' . $torrent{'size_bytes'} . '</td><td>' . $torrent{'bytes_done'} . '</td><td>' . $torrent{'private'} . '</td></tr>';
                        $curtor = '';
                    }
                    else {
                        my $line = shift @lines;
                        if(! $line) {
                            last;
                        }
                        $curtor .= $line;
                    }
                }
                $buf   .= '</tbody></table>';
                $request->SendHTML($buf);
            });
        }
    }

    sub torrentload {
        my ($request) = @_;
        my $packagename = __PACKAGE__;
        my $self = $request->{'client'}{server}{'loaded_plugins'}{$packagename};

        if((exists $request->{'qs'}{'dlsubsystem'}) && (exists $request->{'qs'}{'privdata'}) ) {
            my $subsystem = $request->{'qs'}{'dlsubsystem'};
            if(exists $self->{'dlsubsystems'}{$subsystem}) {
                my $server = $request->{'client'}{'server'};
                $self->{'dlsubsystems'}{$subsystem}->dl($server, $request->{'qs'}{'privdata'}, sub {
                    my ($result, $destdir) = @_;
                    if(! $result) {
                        say "failed to dl torrent";
                        $request->Send404;
                        return;
                    }
                    MHFS::BitTorrent::Client::torrent_start($server, \$result, $destdir, {
                        'on_success' => sub {
                            my ($hexhash) = @_;
                            $request->SendRedirectRawURL(301, 'view?infohash=' . $hexhash);
                        },
                        'on_failure' => sub {
                            $request->Send404;
                        }
                    });
                });
                return;
            }
        }
        $request->Send404;
    }

    sub new {
        my ($class, $settings) = @_;
        my $self =  { 'dlsubsystems' => {}};
        bless $self, $class;

        $self->{'routes'} = [
            [ '/torrent/view', \&torrentview ],
            [ '/torrent/load', \&torrentload ]
        ];

        return $self;
    }

    1;
}

package MHFS::Plugin::OpenDirectory {
    use strict; use warnings;
    use feature 'say';

    sub new {
        my ($class, $settings) = @_;
        my $self =  {};
        bless $self, $class;

        my $odmappings = $settings->{OPENDIRECTORY}{maps};

        $self->{'routes'} = [
            [
                '/od', sub {
                    my ($request) = @_;
                    $request->SendRedirect(301, 'od/');
                }
            ],
            [
                '/od/*', sub {
                    my ($request) = @_;
                    foreach my $key (keys %{$odmappings}) {
                        if(rindex($request->{'path'}{'unsafepath'}, '/od/'.$key, 0) == 0) {
                            $request->SendDirectoryListing($odmappings->{$key}, '/od/'.$key);
                            return;
                        }
                    }
                    $request->Send404;
                }
            ],
        ];

        return $self;
    }

    1;
}

package MHFS::Plugin::Playlist {
    use strict; use warnings;
    use feature 'say';
    use Data::Dumper;
    use URI::Escape qw(uri_escape);
    use Encode qw(decode);

    sub video_get_m3u8 {
        my ($video, $urlstart) = @_;
        my $buf;
        my $m3u8 = <<'M3U8END';
#EXTM3U
#EXTVLCOPT:network-caching=40000'
M3U8END

        my @files;
        if(! -d $video->{'src_file'}{'filepath'}) {
            push @files, $video->{'src_file'}{'fullname'};
        }
        else {
            output_dir_versatile($video->{'src_file'}{'filepath'}, {
                'root' => $video->{'src_file'}{'root'},
                'on_file' => sub {
                    my ($path, $shortpath) = @_;
                    push @files, $shortpath;
                }
            });
        }

        foreach my $file (@files) {
            $m3u8 .= '#EXTINF:0, ' . decode('UTF-8', $file, Encode::LEAVE_SRC) . "\n";
            $m3u8 .= $urlstart . uri_escape($file) . "\n";
            #$m3u8 .= $urlstart . small_url_encode($file) . "\n";
        }
        return \$m3u8;
    }

    sub new {
        my ($class, $settings, $server) = @_;
        my $self =  {};
        bless $self, $class;

        my @subsystems = ('video');

        $self->{'routes'} = [
            [
                '/playlist/*', sub {
                    my ($request) = @_;
                    my $qs = $request->{'qs'};
                    my @pathcomponents = split('/', $request->{'path'}{'unsafepath'});
                    if(scalar(@pathcomponents) >= 3) {
                        if($pathcomponents[2] eq 'video') {
                            if(scalar(@pathcomponents) >= 5) {
                                my %video = ('out_fmt' => ($request->{'qs'}{'vfmt'} // 'noconv'));
                                my $sid = $pathcomponents[3];
                                splice(@pathcomponents, 0, 4);
                                my $nametolookup = join('/', @pathcomponents);
                                $video{'src_file'} = $server->{'fs'}->lookup($nametolookup, $sid);
                                if( ! $video{'src_file'} ) {
                                    $request->Send404;
                                    return undef;
                                }
                                $video{'out_base'} = $video{'src_file'}{'name'};
                                my $fmt = $request->{'qs'}{'fmt'} // 'm3u8';
                                if($fmt eq 'm3u8') {
                                    my $absurl = $request->getAbsoluteURL;
                                    if(! $absurl) {
                                        say 'unable to $request->getAbsoluteURL';
                                        $request->Send404;
                                        return undef;
                                    }
                                    my $m3u8 = video_get_m3u8(\%video,  $absurl . '/get_video?sid='. $sid . '&name=');
                                    $video{'src_file'}{'ext'} = $video{'src_file'}{'ext'} ? '.'. $video{'src_file'}{'ext'} : '';
                                    $request->{'responseopt'}{'cd_file'} = 'inline';
                                    $request->SendText('application/x-mpegURL', $$m3u8, {'filename' => $video{'src_file'}{'name'} . $video{'src_file'}{'ext'} . '.m3u8'});
                                    return 1;
                                }
                            }
                        }
                    }
                    $request->Send404;
                }
            ],
        ];

        return $self;
    }

    1;
}

package MHFS::Plugin::Kodi {
    use strict; use warnings;
    use feature 'say';
    use File::Basename qw(basename);
    use Cwd qw(abs_path);
    use URI::Escape qw(uri_escape);
    use Encode qw(decode);

    # format tv library for kodi http
    sub route_tv {
        my ($request, $absdir, $kodidir) = @_;
        # read in the shows
        my $tvdir = abs_path($absdir);
        if(! defined $tvdir) {
            $request->Send404;
            return;
        }
        my $dh;
        if(! opendir ( $dh, $tvdir )) {
            warn "Error in opening dir $tvdir\n";
            $request->Send404;
            return;
        }
        my %shows = ();
        my @diritems;
        while( (my $filename = readdir($dh))) {
            next if(($filename eq '.') || ($filename eq '..'));
            next if(!(-s "$tvdir/$filename"));
            # extract the showname
            next if($filename !~ /^(.+)[\.\s]+S\d+/);
            my $showname = $1;
            if($showname) {
                $showname =~ s/\./ /g;
                if(! $shows{$showname}) {
                    $shows{$showname} = [];
                    push @diritems, {'item' => $showname, 'isdir' => 1}
                }
                push @{$shows{$showname}}, "$tvdir/$filename";
            }
        }
        closedir($dh);

        # locate the content
        if($request->{'path'}{'unsafepath'} ne $kodidir) {
            my $fullshowname = substr($request->{'path'}{'unsafepath'}, length($kodidir)+1);
            my $slash = index($fullshowname, '/');
            @diritems = ();
            my $showname = ($slash != -1) ? substr($fullshowname, 0, $slash) : $fullshowname;
            my $showfilename = ($slash != -1) ? substr($fullshowname, $slash+1) : undef;

            my $showitems = $shows{$showname};
            if(!$showitems) {
                $request->Send404;
                return;
            }
            my @initems = @{$showitems};
            my @outitems;
            # TODO replace basename usage?
            while(@initems) {
                my $item = shift @initems;
                $item = abs_path($item);
                if(! $item) {
                    say "bad item";
                }
                elsif(rindex($item, $tvdir, 0) != 0) {
                    say "bad item, path traversal?";
                }
                elsif(-f $item) {
                    my $filebasename = basename($item);
                    if(!$showfilename) {
                        push @diritems, {'item' => $filebasename, 'isdir' => 0};
                    }
                    elsif($showfilename eq $filebasename) {
                        if(index($request->{'path'}{'unsafecollapse'}, '/', length($request->{'path'}{'unsafecollapse'})-1) == -1) {
                            say "found show filename";
                            $request->SendFile($item);
                        }
                        else {
                            $request->Send404;
                        }
                        return;
                    }
                }
                elsif(-d _) {
                    opendir(my $dh, $item) or die('failed to open dir');
                    my @newitems;
                    while(my $newitem = readdir($dh)) {
                        next if(($newitem eq '.') || ($newitem eq '..'));
                        push @newitems, "$item/$newitem";
                    }
                    closedir($dh);
                    unshift @initems, @newitems;
                }
                else {
                    say "bad item unknown filetype " . $item;
                }
            }
        }

        # redirect if the slash wasn't there
        if(index($request->{'path'}{'unescapepath'}, '/', length($request->{'path'}{'unescapepath'})-1) == -1) {
            $request->SendRedirect(301, substr($request->{'path'}{'unescapepath'}, rindex($request->{'path'}{'unescapepath'}, '/')+1).'/');
            return;
        }

        # generate the directory html
        my $buf = '';
        foreach my $show (@diritems) {
            my $showname = $show->{'item'};
            my $url = uri_escape($showname);
            $url .= '/' if($show->{'isdir'});
            $buf .= '<a href="' . $url .'">'.${MHFS::Util::escape_html_noquote(decode('UTF-8', $showname, Encode::LEAVE_SRC))} .'</a><br><br>';
        }
        $request->SendHTML($buf);
    }

    # format movies library for kodi http
    sub route_movies {
        my ($request, $absdir, $kodidir) = @_;
        # read in the shows
        my $moviedir = abs_path($absdir);
        if(! defined $moviedir) {
            $request->Send404;
            return;
        }
        my $dh;
        if(! opendir ( $dh, $moviedir )) {
            warn "Error in opening dir $moviedir\n";
            $request->Send404;
            return;
        }
        my %shows = ();
        my @diritems;
        while( (my $filename = readdir($dh))) {
            next if(($filename eq '.') || ($filename eq '..'));
            next if(!(-s "$moviedir/$filename"));
            my $showname;
            # extract the showname
            if($filename =~ /^(.+)[\.\s]+\(?(\d{4})([^p]|$)/) {
                $showname = "$1 ($2)";
            }
            elsif($filename =~ /^(.+)(\.DVDRip)\.[a-zA-Z]{3,4}$/) {
                $showname = $1;
            }
            elsif($filename =~ /^(.+)\.VHS/) {
                $showname = $1;
            }
            elsif($filename =~ /^(.+)[\.\s]+\d{3,4}p\.[a-zA-Z]{3,4}$/) {
                $showname = $1;
            }
            elsif($filename =~ /^(.+)\.[a-zA-Z]{3,4}$/) {
                $showname = $1;
            }
            else{
                #next;
                $showname = $filename;
            }
            if($showname) {
                $showname =~ s/\./ /g;
                if(! $shows{$showname}) {
                    $shows{$showname} = [];
                    push @diritems, {'item' => $showname, 'isdir' => 1}
                }
                push @{$shows{$showname}}, "$moviedir/$filename";
            }
        }
        closedir($dh);

        # locate the content
        if($request->{'path'}{'unsafepath'} ne $kodidir) {
            my $fullshowname = substr($request->{'path'}{'unsafepath'}, length($kodidir)+1);
            say "fullshowname $fullshowname";
            my $slash = index($fullshowname, '/');
            @diritems = ();
            my $showname = ($slash != -1) ? substr($fullshowname, 0, $slash) : $fullshowname;
            my $showfilename = ($slash != -1) ? substr($fullshowname, $slash+1) : undef;
            say "showname $showname";

            my $showitems = $shows{$showname};
            if(!$showitems) {
                $request->Send404;
                return;
            }
            my @initems = @{$showitems};
            my @outitems;
            # TODO replace basename usage?
            while(@initems) {
                my $item = shift @initems;
                $item = abs_path($item);
                if(! $item) {
                    say "bad item";
                }
                elsif(rindex($item, $moviedir, 0) != 0) {
                    say "bad item, path traversal?";
                }
                elsif(-f $item) {
                    my $filebasename = basename($item);
                    if(!$showfilename) {
                        push @diritems, {'item' => $filebasename, 'isdir' => 0};
                    }
                    elsif($showfilename eq $filebasename) {
                        if(index($request->{'path'}{'unsafecollapse'}, '/', length($request->{'path'}{'unsafecollapse'})-1) == -1) {
                            say "found show filename";
                            $request->SendFile($item);
                        }
                        else {
                            $request->Send404;
                        }
                        return;
                    }
                }
                elsif(-d _) {
                    opendir(my $dh, $item) or die('failed to open dir');
                    my @newitems;
                    while(my $newitem = readdir($dh)) {
                        next if(($newitem eq '.') || ($newitem eq '..'));
                        push @newitems, "$item/$newitem";
                    }
                    closedir($dh);
                    unshift @initems, @newitems;
                }
                else {
                    say "bad item unknown filetype " . $item;
                }
            }
        }

        # redirect if the slash wasn't there
        if(index($request->{'path'}{'unescapepath'}, '/', length($request->{'path'}{'unescapepath'})-1) == -1) {
            $request->SendRedirect(301, substr($request->{'path'}{'unescapepath'}, rindex($request->{'path'}{'unescapepath'}, '/')+1).'/');
            return;
        }

        # generate the directory html
        my $buf = '';
        foreach my $show (@diritems) {
            my $showname = $show->{'item'};
            my $url = uri_escape($showname);
            $url .= '/' if($show->{'isdir'});
            $buf .= '<a href="' . $url .'">'. ${MHFS::Util::escape_html_noquote(decode('UTF-8', $showname, Encode::LEAVE_SRC))} .'</a><br><br>';
        }
        $request->SendHTML($buf);
    }

    sub new {
        my ($class, $settings) = @_;
        my $self =  {};
        bless $self, $class;

        my @subsystems = ('video');

        $self->{'routes'} = [
            [
                '/kodi/*', sub {
                    my ($request) = @_;
                    my @pathcomponents = split('/', $request->{'path'}{'unsafepath'});
                    if(scalar(@pathcomponents) >= 3) {
                        if($pathcomponents[2] eq 'movies') {
                            route_movies($request, $settings->{'MEDIALIBRARIES'}{'movies'}, '/kodi/movies');
                            return;
                        }
                        elsif($pathcomponents[2] eq 'tv') {
                            route_tv($request, $settings->{'MEDIALIBRARIES'}{'tv'}, '/kodi/tv');
                            return;
                        }
                    }
                    $request->Send404;
                }
            ],
        ];

        return $self;
    }


    1;
}

package MHFS::Plugin::GetVideo {
    use strict; use warnings;
    use feature 'say';
    use Data::Dumper qw (Dumper);
    use Fcntl qw(:seek);
    use Scalar::Util qw(weaken);
    use URI::Escape qw (uri_escape);
    use Devel::Peek qw(Dump);
    no warnings "portable";
BEGIN {
    use Config;
    die('Integers are too small!') if($Config{ivsize} < 8);
}
    MHFS::Util->import();

    sub new {
        my ($class, $settings) = @_;
        my $self =  {};
        bless $self, $class;

        $self->{'VIDEOFORMATS'} = {
            'hls' => {'lock' => 0, 'create_cmd' => sub {
                my ($video) = @_;
                return ['ffmpeg', '-i', $video->{"src_file"}{"filepath"}, '-codec:v', 'libx264', '-strict', 'experimental', '-codec:a', 'aac', '-ac', '2', '-f', 'hls', '-hls_base_url', $video->{"out_location_url"}, '-hls_time', '5', '-hls_list_size', '0',  '-hls_segment_filename', $video->{"out_location"} . "/" . $video->{"out_base"} . "%04d.ts", '-master_pl_name', $video->{"out_base"} . ".m3u8", $video->{"out_filepath"} . "_v"]
            }, 'ext' => 'm3u8', 'desired_audio' => 'aac',
            'player_html' => $settings->{'DOCUMENTROOT'} . '/static/hls_player.html'},

            'jsmpeg' => {'lock' => 0, 'create_cmd' => sub {
                my ($video) = @_;
                return ['ffmpeg', '-i', $video->{"src_file"}{"filepath"}, '-f', 'mpegts', '-codec:v', 'mpeg1video', '-codec:a', 'mp2', '-b', '0',  $video->{"out_filepath"}];
            }, 'ext' => 'ts', 'player_html' => $settings->{'DOCUMENTROOT'} . '/static/jsmpeg_player.html', 'minsize' => '1048576'},

            'mp4' => {'lock' => 1, 'create_cmd' => sub {
                my ($video) = @_;
                return ['ffmpeg', '-i', $video->{"src_file"}{"filepath"}, '-c:v', 'copy', '-c:a', 'aac', '-f', 'mp4', '-movflags', 'frag_keyframe+empty_moov', $video->{"out_filepath"}];
            }, 'ext' => 'mp4', 'player_html' => $settings->{'DOCUMENTROOT'} . '/static/mp4_player.html', 'minsize' => '1048576'},

            'noconv' => {'lock' => 0, 'ext' => '', 'player_html' => $settings->{'DOCUMENTROOT'} . '/static/noconv_player.html', },

            'mkvinfo' => {'lock' => 0, 'ext' => ''},
            'fmp4' => {'lock' => 0, 'ext' => ''},
        };

        $self->{'routes'} = [
            [
                '/get_video', \&get_video
            ],
        ];

        return $self;
    }

    sub get_video {
        my ($request) = @_;
        say "/get_video ---------------------------------------";
        my $packagename = __PACKAGE__;
        my $server = $request->{'client'}{'server'};
        my $self = $server->{'loaded_plugins'}{$packagename};
        my $settings = $server->{'settings'};
        my $videoformats = $self->{VIDEOFORMATS};
        $request->{'responseopt'}{'cd_file'} = 'inline';
        my $qs = $request->{'qs'};
        $qs->{'fmt'} //= 'noconv';
        my %video = ('out_fmt' => $self->video_get_format($qs->{'fmt'}));
        if(defined($qs->{'name'})) {
            if(defined($qs->{'sid'})) {
                $video{'src_file'} = $server->{'fs'}->lookup($qs->{'name'}, $qs->{'sid'});
                if( ! $video{'src_file'} ) {
                    $request->Send404;
                    return undef;
                }
            }
            else {
                $request->Send404;
                return undef;
            }
            print Dumper($video{'src_file'});
            # no conversion necessary, just SEND IT
            if($video{'out_fmt'} eq 'noconv') {
                say "NOCONV: SEND IT";
                $request->SendFile($video{'src_file'}{'filepath'});
                return 1;
            }
            elsif($video{'out_fmt'} eq 'mkvinfo') {
                get_video_mkvinfo($request, $video{'src_file'}{'filepath'});
                return 1;
            }
            elsif($video{'out_fmt'} eq 'fmp4') {
                get_video_fmp4($request, $video{'src_file'}{'filepath'});
                return;
            }

            if(! -e $video{'src_file'}{'filepath'}) {
                $request->Send404;
                return undef;
            }

            $video{'out_base'} = $video{'src_file'}{'name'};

            # soon https://github.com/video-dev/hls.js/pull/1899
            $video{'out_base'} = space2us($video{'out_base'}) if ($video{'out_fmt'} eq 'hls');
        }
        elsif($videoformats->{$video{'out_fmt'}}{'plugin'}) {
            $video{'plugin'} = $videoformats->{$video{'out_fmt'}}{'plugin'};
            if(!($video{'out_base'} = $video{'plugin'}->getOutBase($qs))) {
                $request->Send404;
                return undef;
            }
        }
        else {
            $request->Send404;
            return undef;
        }

        # Determine the full path to the desired file
        my $fmt = $video{'out_fmt'};
        $video{'out_location'} = $settings->{'VIDEO_TMPDIR'} . '/' . $video{'out_base'};
        $video{'out_filepath'} = $video{'out_location'} . '/' . $video{'out_base'} . '.' . $videoformats->{$video{'out_fmt'}}{'ext'};
        $video{'out_location_url'} = 'get_video?'.$settings->{VIDEO_TMPDIR_QS}.'&fmt=noconv&name='.$video{'out_base'}.'%2F';

        # Serve it up if it has been created
        if(-e $video{'out_filepath'}) {
            say $video{'out_filepath'} . " already exists";
            $request->SendFile($video{'out_filepath'});
            return 1;
        }
        # otherwise create it
        mkdir($video{'out_location'});
        if(($videoformats->{$fmt}{'lock'} == 1) && (LOCK_WRITE($video{'out_filepath'}) != 1)) {
            say "FAILED to LOCK";
            # we should do something here
        }
        if($video{'plugin'}) {
            $video{'plugin'}->downloadAndServe($request, \%video);
            return 1;
        }
        elsif(defined($videoformats->{$fmt}{'create_cmd'})) {
            my @cmd = @{$videoformats->{$fmt}{'create_cmd'}->(\%video)};
            print "$_ " foreach @cmd;
            print "\n";

            video_on_streams(\%video, $request, sub {
            #say "there should be no pids around";
            #$request->Send404;
            #return undef;

            if($fmt eq 'hls') {
                $video{'on_exists'} = \&video_hls_write_master_playlist;
            }

            # deprecated
            $video{'pid'} = ASYNC(\&shellcmd_unlock, \@cmd, $video{'out_filepath'});

            # our file isn't ready yet, so create a timer to check the progress and act
            weaken($request); # the only one who should be keeping $request alive is the client
            $request->{'client'}{'server'}{'evp'}->add_timer(0, 0, sub {
                if(! defined $request) {
                    say "\$request undef, ignoring CB";
                    return undef;
                }
                # test if its ready to send
                while(1) {
                     my $filename = $video{'out_filepath'};
                     if(! -e $filename) {
                         last;
                     }
                     my $minsize = $videoformats->{$fmt}{'minsize'};
                     if(defined($minsize) && ((-s $filename) < $minsize)) {
                         last;
                     }
                     if(defined $video{'on_exists'}) {
                         last if (! $video{'on_exists'}->($settings, \%video));
                     }
                     say "get_video_timer is destructing";
                     $request->SendLocalFile($filename);
                     return undef;
                }
                # 404, if we didn't send yet the process is not running
                if(pid_running($video{'pid'})) {
                    return 1;
                }
                say "pid not running: " . $video{'pid'} . " get_video_timer done with 404";
                $request->Send404;
                return undef;
            });
            say "get_video: added timer " . $video{'out_filepath'};
            });
        }
        else {
            say "out_fmt: " . $video{'out_fmt'};
            $request->Send404;
            return undef;
        }
        return 1;
    }

    sub video_get_format {
        my ($self, $fmt) = @_;

        if(defined($fmt)) {
            # hack for jsmpeg corrupting the url
            $fmt =~ s/\?.+$//;
            if(defined $self->{VIDEOFORMATS}{$fmt}) {
                return $fmt;
            }
        }

        return 'noconv';
    }
    sub video_hls_write_master_playlist {
        # Rebuilt the master playlist because reasons; YOU ARE TEARING ME APART, FFMPEG!
        my ($settings, $video) = @_;
        my $requestfile = $video->{'out_filepath'};

        # fix the path to the video playlist to be correct
        my $m3ucontent = read_file($requestfile);
        my $subm3u;
        my $newm3ucontent = '';
        foreach my $line (split("\n", $m3ucontent)) {
            # master playlist doesn't get written with base url ...
            if($line =~ /^(.+)\.m3u8_v$/) {
                $subm3u = "get_video?".$settings->{VIDEO_TMPDIR_QS}."&fmt=noconv&name=" . uri_escape("$1/$1");
                $line = $subm3u . '.m3u8_v';
            }
            $newm3ucontent .= $line . "\n";
        }

        # Always start at 0, even if we encoded half of the movie
        #$newm3ucontent .= '#EXT-X-START:TIME-OFFSET=0,PRECISE=YES' . "\n";

        # if ffmpeg created a sub include it in the playlist
        ($requestfile =~ /^(.+)\.m3u8$/);
        my $reqsub = "$1_vtt.m3u8";
        if($subm3u && -e $reqsub) {
            $subm3u .= "_vtt.m3u8";
            say "subm3u $subm3u";
            my $default = 'NO';
            my $forced =  'NO';
            foreach my $sub (@{$video->{'subtitle'}}) {
                $default = 'YES' if($sub->{'is_default'});
                $forced = 'YES' if($sub->{'is_forced'});
            }
            # assume its in english
            $newm3ucontent .= '#EXT-X-MEDIA:TYPE=SUBTITLES,GROUP-ID="subs",NAME="English",DEFAULT='.$default.',FORCED='.$forced.',URI="' . $subm3u . '",LANGUAGE="en"' . "\n";
        }
        write_file($requestfile, $newm3ucontent);
        return 1;
    }

    sub get_video_mkvinfo {
        my ($request, $fileabspath) = @_;
        my $matroska = matroska_open($fileabspath);
        if(! $matroska) {
            $request->Send404;
            return;
        }

        my $obj;
        if(defined $request->{'qs'}{'mkvinfo_time'}) {
            my $track = matroska_get_video_track($matroska);
            if(! $track) {
                $request->Send404;
                return;
            }
            my $gopinfo = matroska_get_gop($matroska, $track, $request->{'qs'}{'mkvinfo_time'});
            if(! $gopinfo) {
                $request->Send404;
                return;
            }
            $obj = $gopinfo;
        }
        else {
            $obj = {};
        }
        $obj->{duration} = $matroska->{'duration'};
        $request->SendAsJSON($obj);
    }

    sub get_video_fmp4 {
        my ($request, $fileabspath) = @_;
        my @command = ('ffmpeg', '-loglevel', 'fatal');
        if($request->{'qs'}{'fmp4_time'}) {
            my $formattedtime = hls_audio_formattime($request->{'qs'}{'fmp4_time'});
            push @command, ('-ss', $formattedtime);
        }
        push @command, ('-i', $fileabspath, '-c:v', 'copy', '-c:a', 'aac', '-f', 'mp4', '-movflags', 'frag_keyframe+empty_moov', '-');
        my $evp = $request->{'client'}{'server'}{'evp'};
        my $sent;
        print "$_ " foreach @command;
        $request->{'outheaders'}{'Accept-Ranges'} = 'none';

        # avoid bookkeeping, have ffmpeg output straight to the socket
        $request->{'outheaders'}{'Connection'} = 'close';
        $request->{'outheaders'}{'Content-Type'} = 'video/mp4';
        my $sock = $request->{'client'}{'sock'};
        print  $sock  "HTTP/1.0 200 OK\r\n";
        my $headtext = '';
        foreach my $header (keys %{$request->{'outheaders'}}) {
            $headtext .= "$header: " . $request->{'outheaders'}{$header} . "\r\n";
        }
        print $sock $headtext."\r\n";
        $evp->remove($sock);
        $request->{'client'} = undef;
        MHFS::Process->cmd_to_sock(\@command, $sock);
    }

    sub hls_audio_formattime {
        my ($ttime) = @_;
        my $hours = int($ttime / 3600);
        $ttime -= ($hours * 3600);
        my $minutes = int($ttime / 60);
        $ttime -= ($minutes*60);
        #my $seconds = int($ttime);
        #$ttime -= $seconds;
        #say "ttime $ttime";
        #my $mili = int($ttime * 1000000);
        #say "mili $mili";
        #my $tstring = sprintf "%02d:%02d:%02d.%06d", $hours, $minutes, $seconds, $mili;
        my $tstring = sprintf "%02d:%02d:%f", $hours, $minutes, $ttime;
        return $tstring;
    }

    sub adts_get_packet_size {
        my ($buf) = @_;
        my ($sync, $stuff, $rest) = unpack('nCN', $buf);
        if(!defined($sync)) {
            say "no pack, len " . length($buf);
            return undef;
        }
        if($sync != 0xFFF1) {
            say "bad sync";
            return undef;
        }

        my $size = ($rest >> 13) & 0x1FFF;
        return $size;
    }

    sub ebml_read {
        my $ebml = $_[0];
        my $buf = \$_[1];
        my $amount = $_[2];
        my $lastelm = ($ebml->{'elements'} > 0) ? $ebml->{'elements'}[-1] : undef;
        return undef if($lastelm && defined($lastelm->{'size'}) && ($amount > $lastelm->{'size'}));

        my $amtread = read($ebml->{'fh'}, $$buf, $amount);
        if(! $amtread) {
            return $amtread;
        }

        foreach my $elem (@{$ebml->{'elements'}}) {
            if($elem->{'size'}) {
                $elem->{'size'} -= $amtread;
            }
        }
        return $amtread;
    }

    sub ebml_seek {
        my ($ebml, $position, $whence) = @_;
        ($whence == SEEK_CUR) or die("unsupported seek");
        return undef if(($ebml->{'elements'} > 0) && $ebml->{'elements'}[-1]{'size'} && ($position > $ebml->{'elements'}[-1]{'size'}));
        return undef if(!seek($ebml->{'fh'}, $position, $whence));
        foreach my $elem (@{$ebml->{'elements'}}) {
            if($elem->{'size'}) {
                $elem->{'size'} -= $position;
            }
        }
        return 1;
    }

    sub read_vint_from_buf {
        my $bufref   = $_[0];
        my $savewidth = $_[1];

        my $width = 1;
        my $value = unpack('C', substr($$bufref, 0, 1, ''));
        for(;;$width++) {
            last if(($value << ($width-1)) & 0x80);
            $width < 9 or return undef;
        }

        length($$bufref) >= ($width-1) or return undef;

        for(my $wcopy = $width; $wcopy > 1; $wcopy--) {
            $value <<= 8;
            $value |= unpack('C', substr($$bufref, 0, 1, ''));
        }

        $$savewidth = $width;
        return $value;
    }

    sub read_and_parse_vint_from_buf {
        my $bufref = $_[0];
        my $savewidth = $_[1];

        my $width;
        my $value = read_vint_from_buf($bufref, \$width);
        defined($value) or return undef;

        my $andval = 0xFF >> $width;
        for(my $wcopy = $width; $wcopy > 1; $wcopy--) {
            $andval <<= 8;
            $andval |= 0xFF;
        }
        $value &= $andval;
        if(defined $savewidth) {
            $$savewidth = $width;
        }
        return $value;
    }

    sub read_vint {
        my ($ebml, $val, $savewidth) = @_;
        my $value;
        ebml_read($ebml, $value, 1) or return 0;
        my $width = 1;
        $value = unpack('C', $value);
        for(;;$width++) {
            last if(($value << ($width-1)) & 0x80);
            $width < 9 or return 0;
        }
        $$savewidth = $width;
        my $byte;
        for(; $width > 1; $width--) {
            $value <<= 8;
            ebml_read($ebml, $byte, 1) or return 0;
            $value |= unpack('C', $byte);
        }
        $$val = $value;
        return 1;
    }

    sub read_and_parse_vint {
        my ($ebml, $val) = @_;
        my $value;
        my $width;
        read_vint($ebml, \$value, \$width) or return 0;
        my $andval = 0xFF >> $width;
        for(;$width > 1; $width--) {
            $andval <<= 8;
            $andval |= 0xFF;
        }
        $value &= $andval;
        $$val = $value;
        return 1;
    }

    sub ebml_open {
        my ($filename) = @_;
        open(my $fh, "<", $filename) or return 0;
        my $magic;
        read($fh, $magic, 4) or return 0;
        $magic eq "\x1A\x45\xDF\xA3" or return 0;
        my $ebmlheadsize;
        my $ebml = {'fh' => $fh, 'elements' => []};
        read_and_parse_vint($ebml, \$ebmlheadsize) or return 0;
        seek($fh, $ebmlheadsize, SEEK_CUR) or return 0;
        return $ebml;
    }

    sub ebml_read_element {
        my ($ebml) = @_;
        my $id;
        read_vint($ebml, \$id) or return undef;
        my $size;
        read_and_parse_vint($ebml, \$size) or return undef;
        my $elm = {'id' => $id, 'size' => $size};
        push @{$ebml->{'elements'}}, $elm;
        return $elm;
    }

    sub ebml_skip {
        my ($ebml) = @_;
        my $elm = $ebml->{'elements'}[-1];
        ebml_seek($ebml, $elm->{'size'}, SEEK_CUR) or return 0;
        pop @{$ebml->{'elements'}};
        return 1;
    }

    sub ebml_find_id {
        my ($ebml, $id) = @_;
        for(;;) {
            my $elm = ebml_read_element($ebml);
            $elm or return undef;
            if($elm->{'id'} == $id) {
                return $elm;
            }
            #say "id " . $elm->{'id'};
            ebml_skip($ebml) or return undef;
        }
    }

    sub ebml_make_elms {
        my @elms = @_;
        my @bufstack = ('');
        while(@elms) {
            my $elm = $elms[0];
            if(! $elm) {
                shift @elms;
                $elm = $elms[0];
                $elm->{'data'} = pop @bufstack;
            }
            elsif(! $elm->{'data'}) {
                @elms = (@{$elm->{'elms'}}, undef, @elms);
                push @bufstack, '';
                next;
            }
            shift @elms;
            my $elementid = $elm->{'id'};
            if(! $elementid) {
                print Dumper($elm);
                die;
            }
            $elementid < 0xFFFFFFFF or return undef;
            my $data = \$elm->{'data'};

            my $size = length($$data);
            $size < 0xFFFFFFFFFFFFFF or return undef;
            # pack the id
            my $buf;
            if($elementid > 0xFFFFFF) {
                # pack BE uint32_t
                #$buf = pack('CCCC', ($elementid >> 24) & 0xFF, ($elementid >> 16) & 0xFF, ($elementid >> 8) & 0xFF, $elementid & 0xFF);
                $buf = pack('N', $elementid);
            }
            elsif($elementid > 0xFFFF) {
                # pack BE uint24_t
                $buf = pack('CCC', ($elementid >> 16) & 0xFF, ($elementid >> 8) & 0xFF, $elementid & 0xFF);
            }
            elsif($elementid > 0xFF) {
                # pack BE uint16_t
                #$buf = pack('CC', ($elementid >> 8) & 0xFF, $elementid & 0xFF);
                $buf = pack('n', $elementid);
            }
            else {
                # pack BE uint8_t
                $buf = pack('C', $elementid & 0xFF);
            }

            # pack the size
            if($elm->{'infsize'}) {
                $buf .= pack('C', 0xFF);
            }
            else {
                # determine the VINT width and marker value, and the size needed for the vint
                my $sizeflag = 0x80;
                my $bitwidth = 0x8;
                while($size >= $sizeflag) {
                    $bitwidth += 0x8;
                    $sizeflag <<= 0x7;
                }

                # Apply the VINT marker and pack the vint
                $size |= $sizeflag;
                while($bitwidth) {
                    $bitwidth -= 8;
                    $buf .= pack('C', ($size >> $bitwidth) & 0xFF);
                }
            }

            # pack the data
            $buf .= $$data;
            $bufstack[-1] .= $buf;
        }

        return \$bufstack[0];
    }


    use constant {
        'EBMLID_EBMLHead'           => 0x1A45DFA3,
        'EBMLID_EBMLVersion'        => 0x4286,
        'EBMLID_EBMLReadVersion'    => 0x42F7,
        'EBMLID_EBMLMaxIDLength'    => 0x42F2,
        'EBMLID_EBMLMaxSizeLength'  => 0x42F3,
        'EBMLID_EBMLDocType'        => 0x4282,
        'EBMLID_EBMLDocTypeVer'     => 0x4287,
        'EBMLID_EBMLDocTypeReadVer' => 0x4285,
        'EBMLID_Segment'            => 0x18538067,
        'EBMLID_SegmentInfo'        => 0x1549A966,
        'EBMLID_TimestampScale'     => 0x2AD7B1,
        'EBMLID_Duration'           => 0x4489,
        'EBMLID_MuxingApp'          => 0x4D80,
        'EBMLID_WritingApp'         => 0x5741,
        'EBMLID_Tracks'             => 0x1654AE6B,
        'EBMLID_Track'              => 0xAE,
        'EBMLID_TrackNumber'        => 0xD7,
        'EBMLID_TrackUID'           => 0x73C5,
        'EBMLID_TrackType'          => 0x83,
        'EBMLID_DefaulDuration'     => 0x23E383,
        'EBMLID_CodecID'            => 0x86,
        'EBMLID_CodecPrivData',     => 0x63A2,
        'EBMLID_AudioTrack'         => 0xE1,
        'EBMLID_AudioChannels'      => 0x9F,
        'EBMLID_AudioSampleRate'    => 0xB5,
        'EBMLID_AudioBitDepth'      => 0x6264,
        'EBMLID_Cluster'            => 0x1F43B675,
        'EBMLID_ClusterTimestamp'   => 0xE7,
        'EBMLID_SimpleBlock'        => 0xA3,
        'EBMLID_BlockGroup'         => 0xA0,
        'EBMLID_Block'              => 0xA1
    };

    sub matroska_cluster_parse_simpleblock_or_blockgroup {
        my ($elm) = @_;

        my $data = $elm->{'data'};
        if($elm->{'id'} == EBMLID_BlockGroup) {
            say "blockgroup";
            while(1) {
                my $width;
                my $id = read_vint_from_buf(\$data, \$width);
                defined($id) or return undef;
                my $size = read_and_parse_vint_from_buf(\$data);
                defined($size) or return undef;
                say "blockgroup item: $id $size";
                last if($id == EBMLID_Block);
                substr($data, 0, $size, '');
            }
            say "IS BLOCK";
        }
        elsif($elm->{'id'} == EBMLID_SimpleBlock) {
            #say "IS SIMPLEBLOCK";
        }
        else {
            die "unhandled block type";
        }
        my $trackno = read_and_parse_vint_from_buf(\$data);
        if((!defined $trackno) || (length($data) < 3)) {
            return undef;
        }
        my $rawts = substr($data, 0, 2, '');
        my $rawflag = substr($data, 0, 1, '');

        my $lacing = unpack('C', $rawflag) & 0x6;
        my $framecnt;
        my @sizes;
        # XIPH
        if($lacing == 0x2) {
            $framecnt = unpack('C', substr($data, 0, 1, ''))+1;
            my $firstframessize = 0;
            for(my $i = 0; $i < ($framecnt-1); $i++) {
                my $fsize = 0;
                while(1) {
                    my $val = unpack('C', substr($data, 0, 1, ''));
                    $fsize += $val;
                    last if($val < 255);
                }
                push @sizes, $fsize;
                $firstframessize += $fsize;
            }
            push @sizes, (length($data) - $firstframessize);
        }
        # EBML
        elsif($lacing == 0x6) {
            $framecnt = unpack('C', substr($data, 0, 1, ''))+1;
            my $last = read_and_parse_vint_from_buf(\$data);
            push @sizes, $last;
            my $sum = $last;
            for(my $i = 0; $i < ($framecnt - 2); $i++) {
                my $width;
                my $offset = read_and_parse_vint_from_buf(\$data, \$width);
                # multiple by 2^bitwidth - 1 (with adjusted bitwidth)
                my $desiredbits = (8 * $width) - ($width+1);
                my $subtract = (1 << $desiredbits) - 1;
                my $result = $offset - $subtract;
                $last += $result;
                say "offset $offset width $width factor: " . sprintf("0x%X ", $subtract) . "result $result evaled $last";
                push @sizes, $last;
                $sum += $last;
            }
            my $lastlast = length($data) - $sum;
            say "lastlast $lastlast";
            push @sizes, $lastlast;
        }
        # fixed
        elsif($lacing == 0x4) {
            $framecnt = unpack('C', substr($data, 0, 1, ''))+1;
            my $framesize = length($data) / $framecnt;
            for(my $i = 0; $i < $framecnt; $i++) {
                push @sizes, $framesize;
            }
        }
        # no lacing
        else {
            push @sizes, length($data);
        }

        return {
            'trackno' => $trackno,
            'rawts' => $rawts,
            'rawflag'  => $rawflag,
            'frame_lengths' => \@sizes,
            'data' => $data,
            'ts' => unpack('s>', $rawts)
        };
    }

    sub telmval {
        my ($track, $stringid) = @_;
        my $constname = "EBMLID_$stringid";
        my $id = __PACKAGE__->$constname;
        return $track->{$id}{'value'}  // $track->{$id}{'data'};
        #return $track->{"$stringid"}}{'value'} // $track->{$EBMLID->{$stringid}}{'data'};
    }

    sub trackno_is_audio {
        my ($tracks, $trackno) = @_;
        foreach my $track (@$tracks) {
            if(telmval($track, 'TrackNumber') == $trackno) {
                return telmval($track, 'TrackType') == 0x2;
            }
        }
        return undef;
    }

    sub flac_read_METADATA_BLOCK {
        my $fh = $_[0];
        my $type = \$_[1];
        my $done = \$_[2];
        my $buf;
        my $headread = read($fh, $buf, 4);
        ($headread && ($headread == 4)) or return undef;
        my ($blocktypelast, $sizehi, $sizemid, $sizelo) = unpack('CCCC',$buf);
        $$done = $blocktypelast & 0x80;
        $$type = $blocktypelast & 0x7F;
        my $size = ($sizehi << 16) | ($sizemid << 8) | ($sizelo);
        #say "islast $$done type $type size $size";
        $$type != 0x7F or return undef;
        my $tbuf;
        my $dataread = read($fh, $tbuf, $size);
        ($dataread && ($dataread == $size)) or return undef;
        $buf .= $tbuf;
        return \$buf;
    }

    sub flac_parseStreamInfo {
        # https://metacpan.org/source/DANIEL/Audio-FLAC-Header-2.4/Header.pm
        my ($buf) = @_;
        my $metaBinString = unpack('B144', $buf);

        my $x32 = 0 x 32;
        my $info = {};
        $info->{'MINIMUMBLOCKSIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 0, 16), -32)));
        $info->{'MAXIMUMBLOCKSIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 16, 16), -32)));
        $info->{'MINIMUMFRAMESIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 32, 24), -32)));
        $info->{'MAXIMUMFRAMESIZE'} = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 56, 24), -32)));

        $info->{'SAMPLERATE'}       = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 80, 20), -32)));
        $info->{'NUMCHANNELS'}      = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 100, 3), -32))) + 1;
        $info->{'BITSPERSAMPLE'}    = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 103, 5), -32))) + 1;

        # Calculate total samples in two parts
        my $highBits = unpack('N', pack('B32', substr($x32 . substr($metaBinString, 108, 4), -32)));

        $info->{'TOTALSAMPLES'} = $highBits * 2 ** 32 +
                unpack('N', pack('B32', substr($x32 . substr($metaBinString, 112, 32), -32)));

        # Return the MD5 as a 32-character hexadecimal string
        $info->{'MD5CHECKSUM'} = unpack('H32',substr($buf, 18, 16));
        return $info;
    }

    sub flac_read_to_audio {
        my ($fh) = @_;
        my $buf;
        my $magic = read($fh, $buf, 4);
        ($magic && ($magic == 4)) or return undef;
        my $streaminfo;
        for(;;) {
            my $type;
            my $done;
            my $bref = flac_read_METADATA_BLOCK($fh, $type, $done);
            $bref or return undef;
            $buf .= $$bref;
            if($type == 0) {
                $streaminfo = flac_parseStreamInfo(substr($$bref, 4));
            }
            last if($done);
        }
        return {'streaminfo' => $streaminfo, 'buf' => \$buf};
    }

    sub parse_uinteger_str {
        my ($str) = @_;
        my @values = unpack('C'x length($str), $str);
        my $value = 0;
        my $shift = 0;
        while(@values) {
            $value |= ((pop @values) << $shift);
            $shift += 8;
        }
        return $value;
    }

    sub parse_float_str {
        my ($str) = @_;
        return 0 if(length($str) == 0);

        return unpack('f>', $str) if(length($str) == 4);

        return unpack('d>', $str) if(length($str) == 8);

        return undef;
    }

    # matroska object needs
    # - ebml
    # - tsscale
    # - tracks
    #     - audio track, codec, channels, samplerate
    #     - video track, fps
    # - duration

    sub matroska_open {
        my ($filename) = @_;
        my $ebml = ebml_open($filename);
        if(! $ebml) {
            return undef;
        }

        # find segment
        my $foundsegment = ebml_find_id($ebml, EBMLID_Segment);
        if(!$foundsegment) {
            return undef;
        }
        say "Found segment";
        my %segment = (id => EBMLID_Segment, 'infsize' => 1, 'elms' => []);

        # find segment info
        my $foundsegmentinfo = ebml_find_id($ebml, EBMLID_SegmentInfo);
        if(!$foundsegmentinfo) {
            return undef;
        }
        say "Found segment info";
        my %segmentinfo = (id => EBMLID_SegmentInfo, elms => []);

        # find TimestampScale
        my $tselm = ebml_find_id($ebml, EBMLID_TimestampScale);
        if(!$tselm) {
            return undef;
        }
        say "Found ts elm";
        my $tsbinary;
        if(!ebml_read($ebml, $tsbinary, $tselm->{'size'})) {
            return undef;
        }

        Dump($tsbinary);
        my $tsval = parse_uinteger_str($tsbinary);
        defined($tsval) or return undef;
        say "tsval: $tsval";

        if(!ebml_skip($ebml)) {
            return undef;
        }
        push @{$segmentinfo{'elms'}}, {id => EBMLID_TimestampScale, data => $tsbinary};

        # find Duration
        my $durationelm = ebml_find_id($ebml, EBMLID_Duration);
        if(!$durationelm) {
            return undef;
        }
        say "Found duration elm";
        my $durbin;
        if(!ebml_read($ebml, $durbin, $durationelm->{'size'})) {
            return undef;
        }
        Dump($durbin);
        my $scaledduration = parse_float_str($durbin);

        say "scaledduration $scaledduration";

        my $duration = ($tsval * $scaledduration)/1000000000;
        say "duration: $duration";

        # exit duration
        if(!ebml_skip($ebml)) {
            return undef;
        }

        # exit segment informations
        if(!ebml_skip($ebml)) {
            return undef;
        }

        # find tracks
        my $in_tracks = ebml_find_id($ebml, EBMLID_Tracks);
        if(!$in_tracks) {
            return undef;
        }
        # loop through the Tracks
        my %CodecPCMFrameLength = ( 'AAC' => 1024, 'EAC3' => 1536, 'AC3' => 1536, 'PCM' => 1);
        my %CodecGetSegment = ('AAC' => sub {
            my ($seginfo, $dataref) = @_;
            my $targetpackets = $seginfo->{'expected'} / $CodecPCMFrameLength{'AAC'};
            my $start = 0;
            my $packetsread = 0;
            while(1) {
                my $packetsize = adts_get_packet_size(substr($$dataref, $start, 7));
                $packetsize or return undef;
                say "packet size $packetsize";
                $start += $packetsize;
                $packetsread++;
                if($packetsread == $targetpackets) {
                    return {'mime' => 'audio/aac', 'data' => hls_audio_get_id3($seginfo->{'stime'}).substr($$dataref, 0, $start, '')};
                }
            }
            return undef;
        }, 'PCM' => sub {
            my ($seginfo, $dataref) = @_;
            my $targetsize = 2 * $seginfo->{'channels'}* $seginfo->{'expected'};
            if(length($$dataref) >= $targetsize) {
                return {'mime' => 'application/octet-stream', 'data' => substr($$dataref, 0, $targetsize, '')};
            }
            return undef;
        });
        my @tracks;
        for(;;) {
            my $in_track = ebml_find_id($ebml, EBMLID_Track);
            if(! $in_track) {
                ebml_skip($ebml);
                last;
            }
            my %track = ('id' => EBMLID_Track);
            for(;;) {
                my $telm = ebml_read_element($ebml);
                if(!$telm) {
                    ebml_skip($ebml);
                    last;
                }

                # save the element into tracks
                my %elm = ('id' => $telm->{'id'}, 'data' => '');
                ebml_read($ebml, $elm{'data'}, $telm->{'size'});
                if($elm{'id'} == EBMLID_TrackNumber) {
                    say "trackno";
                    $elm{'value'} = unpack('C', $elm{'data'});
                    $track{$elm{'id'}} = \%elm;
                }
                elsif($elm{'id'} == EBMLID_CodecID) {
                    say "codec " . $elm{'data'};
                    if($elm{'data'} =~ /^([A-Z]+_)([A-Z0-9]+)(?:\/([A-Z0-9_\/]+))?$/) {
                        $track{'CodecID_Prefix'} = $1;
                        $track{'CodecID_Major'} = $2;
                        if($3) {
                            $track{'CodecID_Minor'} = $3;
                        }
                        $track{'PCMFrameLength'} = $CodecPCMFrameLength{$track{'CodecID_Major'}} if($track{'CodecID_Prefix'} eq 'A_');
                    }
                    $track{$elm{'id'}} = \%elm;
                }
                elsif($elm{'id'} == EBMLID_TrackType) {
                    say "tracktype";
                    $elm{'value'} = unpack('C', $elm{'data'});
                    $track{$elm{'id'}} = \%elm;
                }
                elsif($elm{'id'} == EBMLID_TrackUID) {
                    say "trackuid";
                    $track{$elm{'id'}} = \%elm;
                }
                elsif($elm{'id'} == EBMLID_DefaulDuration) {
                    say "defaultduration";
                    $elm{'value'} = parse_uinteger_str($elm{'data'});
                    $track{$elm{'id'}} = \%elm;
                    $track{'fps'} = int(((1/($elm{'value'} / 1000000000)) * 1000) + 0.5)/1000;
                }
                elsif($elm{'id'} == EBMLID_AudioTrack) {
                    say "audiotrack";
                    my $buf = $elm{'data'};
                    while(length($buf)) {
                        # read the id, size, and data
                        my $vintwidth;
                        my $id = read_vint_from_buf(\$buf, \$vintwidth);
                        if(!$id) {
                            last;
                        }
                        say "elmid $id width $vintwidth";
                        say sprintf("0x%X 0x%X", ord(substr($buf, 0, 1)), ord(substr($buf, 1, 1)));
                        my $size = read_and_parse_vint_from_buf(\$buf);
                        if(!$size) {
                            last;
                        }
                        say "size $size";
                        my $data = substr($buf, 0, $size, '');

                        # save metadata
                        if($id == EBMLID_AudioSampleRate) {
                            $track{$id} = parse_float_str($data);
                            say "samplerate " . $track{$id};
                        }
                        elsif($id == EBMLID_AudioChannels) {
                            $track{$id} = parse_uinteger_str($data);
                            say "channels " . $track{$id};
                        }
                    }
                }

                ebml_skip($ebml);
            }
            # add the fake track
            if(($track{'CodecID_Major'} eq 'EAC3') || ($track{'CodecID_Major'} eq 'AC3')) {
                $track{'faketrack'} = {
                    'PCMFrameLength' => $CodecPCMFrameLength{'AAC'},
                    &EBMLID_AudioSampleRate => $track{&EBMLID_AudioSampleRate},
                    &EBMLID_AudioChannels => $track{&EBMLID_AudioChannels}
                };
                #$track{'outfmt'} = 'PCM';
                #$track{'outChannels'} = $track{&EBMLID_AudioChannels};
                $track{'outfmt'} = 'AAC';
                $track{'outChannels'} = 2;

                $track{'outPCMFrameLength'} = $CodecPCMFrameLength{$track{'outfmt'}};
                $track{'outGetSegment'} = $CodecGetSegment{$track{'outfmt'}};

            }
            push @tracks, \%track;
        }
        if(scalar(@tracks) == 0) {
            return undef;
        }

        my $segmentelm = $ebml->{'elements'}[0];
        my %matroska = ('ebml' => $ebml, 'tsscale' => $tsval, 'rawduration' => $scaledduration, 'duration' => $duration, 'tracks' => \@tracks, 'segment_data_start' => {'size' => $segmentelm->{'size'}, 'id' => $segmentelm->{'id'}, 'fileoffset' => tell($ebml->{'fh'})}, 'curframe' => -1, 'curpaks' => []);
        return \%matroska;
    }

    sub matroska_get_audio_track {
        my ($matroska) = @_;
        foreach my $track (@{$matroska->{'tracks'}}) {
            my $tt = $track->{&EBMLID_TrackType};
            if(defined $tt && ($tt->{'value'} == 2)) {
                return $track;
            }
        }
        return undef;
    }

    sub matroska_get_video_track {
        my ($matroska) = @_;
        foreach my $track (@{$matroska->{'tracks'}}) {
            my $tt = $track->{&EBMLID_TrackType};
            if(defined $tt && ($tt->{'value'} == 1)) {
                return $track;
            }
        }
        return undef;
    }

    sub matroska_read_cluster_metadata {
        my ($matroska) = @_;
        my $ebml = $matroska->{'ebml'};

        # find a cluster
        my $custer = ebml_find_id($ebml, EBMLID_Cluster);
        return undef if(! $custer);
        my %cluster = ( 'fileoffset' => tell($ebml->{'fh'}), 'size' => $custer->{'size'}, 'Segment_sizeleft' => $ebml->{'elements'}[0]{'size'});

        # find the cluster timestamp
        for(;;) {
            my $belm = ebml_read_element($ebml);
            if(!$belm) {
                ebml_skip($ebml);
                last;
            }
            my %elm = ('id' => $belm->{'id'}, 'data' => '');
            #say "elm size " . $belm->{'size'};
            ebml_read($ebml, $elm{'data'}, $belm->{'size'});
            if($elm{'id'} == EBMLID_ClusterTimestamp) {
                $cluster{'rawts'} = parse_uinteger_str($elm{'data'});
                $cluster{'ts'} = $cluster{'rawts'} * $matroska->{'tsscale'};
                # exit ClusterTimestamp
                ebml_skip($ebml);
                # exit cluster
                ebml_skip($ebml);
                return \%cluster;
            }

            ebml_skip($ebml);
        }
        return undef;
    }

    sub ebml_set_cluster {
        my ($ebml, $cluster) = @_;
        seek($ebml->{'fh'}, $cluster->{'fileoffset'}, SEEK_SET);
        $ebml->{'elements'} = [
            {
                'id' => EBMLID_Segment,
                'size' => $cluster->{'Segment_sizeleft'}
            },
            {
                'id' => EBMLID_Cluster,
                'size' => $cluster->{'size'}
            }
        ];
    }

    sub matroska_get_track_block {
        my ($matroska, $tid) = @_;
        my $ebml = $matroska->{'ebml'};
        for(;;) {
            my $belm = ebml_read_element($ebml);
            if(!$belm) {
                ebml_skip($ebml); # leave cluster
                my $cluster = matroska_read_cluster_metadata($matroska);
                if($cluster) {
                    say "advancing cluster";
                    $matroska->{'dc'} = $cluster;
                    ebml_set_cluster($ebml, $matroska->{'dc'});
                    next;
                }
                last;
            }
            my %elm = ('id' => $belm->{'id'}, 'data' => '');
            #say "elm size " . $belm->{'size'};

            ebml_read($ebml, $elm{'data'}, $belm->{'size'});
            if(($elm{'id'} == EBMLID_SimpleBlock) || ($elm{'id'} == EBMLID_BlockGroup)) {
                my $block = matroska_cluster_parse_simpleblock_or_blockgroup(\%elm);
                if($block && ($block->{'trackno'} == $tid)) {
                    ebml_skip($ebml);
                    return $block;
                }
            }
            ebml_skip($ebml);
        }
        return undef;
    }

    sub matroska_ts_to_sample  {
        my ($matroska, $samplerate, $ts) = @_;
        my $curframe = int(($ts * $samplerate / 1000000000)+ 0.5);
        return $curframe;
    }

    sub matroska_get_gop {
        my ($matroska, $track, $timeinseconds) = @_;
        my $tid = $track->{&EBMLID_TrackNumber}{'value'};

        my $prevcluster;
        my $desiredcluster;
        while(1) {
            my $cluster = matroska_read_cluster_metadata($matroska);
            last if(!$cluster);

            my $ctime = $cluster->{'ts'} / 1000000000;

            # this cluster could have our GOP, save it's info
            if($ctime <= $timeinseconds) {
                $prevcluster = $desiredcluster;
                $desiredcluster = $cluster;
                if($prevcluster) {
                    $prevcluster->{'prevcluster'} = undef;
                    $desiredcluster->{'prevcluster'} = $prevcluster;
                }
            }

            if($ctime >= $timeinseconds) {
                last;
            }
        }
        say "before dc check";
        return undef if(! $desiredcluster);

        say "cur rawts " . $desiredcluster->{'rawts'};
        say "last rawts " . $desiredcluster->{'prevcluster'}{'rawts'} if($desiredcluster->{'prevcluster'});

        # restore to the the cluster that probably has the GOP
        my $ebml = $matroska->{'ebml'};
        ebml_set_cluster($ebml, $desiredcluster);
        $matroska->{'dc'} = $desiredcluster;

        # find a valid track block that includes pcmFrameIndex;
        my $block;
        my $blocktime;
        while(1) {
            $block = matroska_get_track_block($matroska, $tid);
            if($block) {
                $blocktime = matroska_calc_block_fullts($matroska, $block);
                if($blocktime > $timeinseconds) {
                    $block = undef;
                }
                if(! $matroska->{'dc'}{'firstblk'}) {
                    $matroska->{'dc'}{'firstblk'} = $blocktime;
                }
            }
            if(! $block) {
                if(! $prevcluster) {
                    return undef;
                }
                say "revert cluster";
                $matroska->{'dc'} = $prevcluster;
                ebml_set_cluster($ebml, $matroska->{'dc'});
                next;
            }

            $prevcluster = undef;

            my $blockduration = ((1/24) * scalar(@{$block->{'frame_lengths'}}));
            if($timeinseconds < ($blocktime +  $blockduration)) {
                say 'got GOP at ' . $matroska->{'dc'}{'firstblk'};
                return {'goptime' => $matroska->{'dc'}{'firstblk'}};
                last;
            }
        }

    }

    sub matroska_seek_track {
        my ($matroska, $track, $pcmFrameIndex) = @_;
        my $tid = $track->{&EBMLID_TrackNumber}{'value'};
        $matroska->{'curframe'} = 0;
        $matroska->{'curpaks'} = [];
        my $samplerate = $track->{&EBMLID_AudioSampleRate};
        my $pcmFrameLen = $track->{'PCMFrameLength'};
        if(!$pcmFrameLen) {
            warn("Unknown codec");
            return undef;
        }
        my $prevcluster;
        my $desiredcluster;
        while(1) {
            my $cluster = matroska_read_cluster_metadata($matroska);
            last if(!$cluster);
            my $curframe = matroska_ts_to_sample($matroska, $samplerate, $cluster->{'ts'});
            #$curframe = int(($curframe/$pcmFrameLen)+0.5)*$pcmFrameLen; # requires revert cluster
            $curframe = ceil_div($curframe, $pcmFrameLen) * $pcmFrameLen;

            # this cluster could contain our frame, save it's info
            if($curframe <= $pcmFrameIndex) {
                $prevcluster = $desiredcluster;
                $desiredcluster = $cluster;
                $desiredcluster->{'frameIndex'} = $curframe;
                if($prevcluster) {
                    $prevcluster->{'prevcluster'} = undef;
                    $desiredcluster->{'prevcluster'} = $prevcluster;
                }
            }
            # this cluster is at or past the frame, breakout
            if($curframe >= $pcmFrameIndex){
                last;
            }
        }
        say "before dc check";
        return undef if(! $desiredcluster);

        say "cur rawts " . $desiredcluster->{'rawts'};
        say "last rawts " . $desiredcluster->{'prevcluster'}{'rawts'} if($desiredcluster->{'prevcluster'});

        # restore to the the cluster that probably has our audio
        my $ebml = $matroska->{'ebml'};
        ebml_set_cluster($ebml, $desiredcluster);
        $matroska->{'dc'} = $desiredcluster;

        # find a valid track block that includes pcmFrameIndex;
        my $block;
        my $blockframe;
        while(1) {
            $block = matroska_get_track_block($matroska, $tid);
            if($block) {
                $blockframe = matroska_block_calc_frame($matroska, $block, $samplerate, $pcmFrameLen);
                if($blockframe > $pcmFrameIndex) {
                    $block = undef;
                }
            }
            if(! $block) {
                if(! $prevcluster) {
                    return undef;
                }
                say "revert cluster";
                $matroska->{'dc'} = $prevcluster;
                ebml_set_cluster($ebml, $matroska->{'dc'});
                next;
            }

            $prevcluster = undef;

            my $pcmSampleCount = ($pcmFrameLen * scalar(@{$block->{'frame_lengths'}}));
            if($pcmFrameIndex < ($blockframe +  $pcmSampleCount)) {
                if((($pcmFrameIndex - $blockframe) % $pcmFrameLen) != 0) {
                    say "Frame index does not align with block!";
                    return undef;
                }
                last;
            }
        }

        # add the data to packs
        my $offset = 0;
        while($blockframe < $pcmFrameIndex) {
            my $len = shift @{$block->{'frame_lengths'}};
            $offset += $len;
            $blockframe += $pcmFrameLen;
        }
        $matroska->{'curframe'} = $pcmFrameIndex;
        foreach my $len (@{$block->{'frame_lengths'}}) {
            push @{$matroska->{'curpaks'}}, substr($block->{'data'}, $offset, $len);
            $offset += $len;
        }
        return 1;
    }

    sub matroska_calc_block_fullts {
        my ($matroska, $block) = @_;
        say 'clusterts ' . ($matroska->{'dc'}->{'ts'}/1000000000);
        say 'blockts ' . $block->{'ts'};
        my $time = ($matroska->{'dc'}->{'rawts'} + $block->{'ts'}) * $matroska->{'tsscale'};
        return ($time/1000000000);
    }

    sub matroska_block_calc_frame {
        my ($matroska, $block, $samplerate, $pcmFrameLen) = @_;
        say 'clusterts ' . ($matroska->{'dc'}->{'ts'}/1000000000);
        say 'blockts ' . $block->{'ts'};
        my $time = ($matroska->{'dc'}->{'rawts'} + $block->{'ts'}) * $matroska->{'tsscale'};
        say 'blocktime ' . ($time/1000000000);
        my $calcframe = matroska_ts_to_sample($matroska, $samplerate, $time);
        return round($calcframe/$pcmFrameLen)*$pcmFrameLen;
    }

    sub matroska_read_track {
        my ($matroska, $track, $pcmFrameIndex, $numsamples, $formatpacket) = @_;
        my $tid = $track->{&EBMLID_TrackNumber}{'value'};
        my $samplerate = $track->{&EBMLID_AudioSampleRate};
        my $pcmFrameLen = $track->{'PCMFrameLength'};
        if(!$pcmFrameLen) {
            warn("Unknown codec");
            return undef;
        }

        # find the cluster that might have the start of our audio
        if($matroska->{'curframe'} != $pcmFrameIndex) {
            say "do seek";
            if(!matroska_seek_track($matroska, $track, $pcmFrameIndex)) {
                return undef;
            }
        }

        my $outdata;
        my $destframe = $matroska->{'curframe'} + $numsamples;

        while(1) {
            # add read audio
            while(@{$matroska->{'curpaks'}}) {
                my $pak = shift @{$matroska->{'curpaks'}};
                $outdata .= $formatpacket->($pak, $samplerate);
                $matroska->{'curframe'} += $pcmFrameLen;
                if($matroska->{'curframe'} == $destframe) {
                    say "done, read enough";
                    return $outdata;
                }
            }

            # load a block
            my $block = matroska_get_track_block($matroska, $tid);
            if(! $block) {
                if(($matroska->{'ebml'}{'elements'}[0]{'id'} == EBMLID_Segment) && ($matroska->{'ebml'}{'elements'}[0]{'size'} == 0)) {
                    say "done, EOF";
                }
                else {
                    say "done, Error";
                }
                return $outdata;
            }

            # add the data to paks
            my $offset = 0;
            foreach my $len (@{$block->{'frame_lengths'}}) {
                push @{$matroska->{'curpaks'}}, substr($block->{'data'}, $offset, $len);
                $offset += $len;
            }
        }
    }

    sub video_on_streams {
        my ($video, $request, $continue) = @_;
        $video->{'audio'} = [];
        $video->{'video'} = [];
        $video->{'subtitle'} = [];
        my $input_file = $video->{'src_file'}{'filepath'};
        my @command = ('ffmpeg', '-i', $input_file);
        my $evp = $request->{'client'}{'server'}{'evp'};
        MHFS::Process->new_output_process($evp, \@command, sub {
            my ($output, $error) = @_;
            my @lines = split(/\n/, $error);
            my $current_stream;
            my $current_element;
            foreach my $eline (@lines) {
               if($eline =~ /^\s*Stream\s#0:(\d+)(?:\((.+)\)){0,1}:\s(.+):\s(.+)(.*)$/) {
                   my $type = $3;
                   $current_stream = $1;
                   $current_element = { 'sindex' => $current_stream, 'lang' => $2, 'fmt' => $4, 'additional' => $5, 'metadata' => '' };
                   $current_element->{'is_default'} = 1 if($current_element->{'fmt'} =~ /\(default\)$/i);
                   $current_element->{'is_forced'} = 1 if($current_element->{'fmt'} =~ /FORCED/i);
                   if($type =~ /audio/i) {
                       push @{$video->{'audio'}} , $current_element;
                   }
                   elsif($type =~ /video/i) {
                       push @{$video->{'video'}} , $current_element;
                   }
                   elsif($type =~ /subtitle/i) {
                       push @{$video->{'subtitle'}} , $current_element;
                   }
                   say $eline;
               }
               elsif($eline =~ /^\s+Duration:\s+(\d\d):(\d\d):(\d\d)\.(\d\d)/) {
                   #TODO add support for over day long video
                   $video->{'duration'} //= "PT$1H$2M$3.$4S";
                   write_file($video->{'out_location'} . '/duration',  $video->{'duration'});
               }
               elsif(defined $current_stream) {
                   if($eline !~ /^\s\s+/) {
                       $current_stream = undef;
                       $current_element = undef;
                       next;
                   }
                   $current_element->{'metadata'} .= $eline;
                   if($eline =~ /\s+title\s*:\s*(.+)$/) {
                       $current_element->{'title'} = $1;
                   }
               }
            }
            print Dumper($video);
            $continue->();
        });
    }

    1;
}

package MHFS::Plugin::VideoLibrary {
    use strict; use warnings;
    use feature 'say';
    use Encode qw(decode);
    use URI::Escape qw (uri_escape);
    MHFS::Util->import(qw(output_dir_versatile escape_html uri_escape_path));

    sub player_video {
        my ($request) = @_;
        my $qs = $request->{'qs'};
        my $server = $request->{'client'}{'server'};
        my $packagename = __PACKAGE__;
        my $settings = $server->{'settings'};
        my $self = $request->{'client'}{'server'}{'loaded_plugins'}{$packagename};

        my $buf =  "<html>";
        $buf .= "<head>";
        $buf .= '<style type="text/css">';
        my $temp = $server->GetResource($settings->{'DOCUMENTROOT'} . '/static/' . 'video_style.css');
        $buf .= $$temp;
        $buf .= '.searchfield { width: 50%; margin: 30px;}';
        $buf .= '</style>';
        $buf .= "</head>";
        $buf .= "<body>";

        $qs->{'action'} //= 'library';

        # action=library
        $buf .= '<div id="medialist">';
        $qs->{'library'} //= 'all';
        $qs->{'library'} = lc($qs->{'library'});
        my @libraries = ('movies', 'tv', 'other');
        if($qs->{'library'} ne 'all') {
            @libraries = ($qs->{'library'});
        }
        my %libraryprint = ( 'movies' => 'Movies', 'tv' => 'TV', 'other' => 'Other');
        print "plugin $_\n" foreach keys %{$server->{'loaded_plugins'}};
        my $fmt = $server->{'loaded_plugins'}{'MHFS::Plugin::GetVideo'}->video_get_format($qs->{'fmt'});
        foreach my $library (@libraries) {
            exists $settings->{'MEDIASOURCES'}{$library} or next;
            my $lib = $settings->{'MEDIASOURCES'}{$library};
            my $libhtmlcontent;
            foreach my $sid (@$lib) {
                my $sublib = $settings->{'SOURCES'}{$sid};
                next if(! -d $sublib->{'folder'});
                $libhtmlcontent .= ${video_library_html($sublib->{'folder'}, $library, $sid, {'fmt' => $fmt})};
            }
            next if(! $libhtmlcontent);
            $buf .= "<h1>" . $libraryprint{$library} . "</h1><ul>\n";
            $buf .= $libhtmlcontent.'</ul>';
        }
        $buf .= '</div>';

        # add the video player
        $temp = $server->GetResource($server->{'loaded_plugins'}{'MHFS::Plugin::GetVideo'}{'VIDEOFORMATS'}{$fmt}->{'player_html'});
        $buf .= $$temp;
        $buf .= '<script>';
        $temp = $server->GetResource($settings->{'DOCUMENTROOT'} . '/static/' . 'setVideo.js');
        $buf .= $$temp;
        $buf .= '</script>';
        $buf .= "</body>";
        $buf .= "</html>";
        $request->SendHTML($buf);
    }

    sub video_library_html {
        my ($dir, $lib, $sid, $opt) = @_;
        my $fmt = $opt->{'fmt'};

        my $urlconstant = 'lib='.$lib.'&sid='.$sid;
        my $playlisturl = "playlist/video/$sid/";

        my $buf;
        output_dir_versatile($dir, {
            'root' => $dir,
            'min_file_size' => 100000,
            'on_dir_start' => sub {
                my ($realpath, $unsafe_relpath) = @_;
                my $relpath = uri_escape($unsafe_relpath);
                my $disppath = escape_html(decode('UTF-8', $unsafe_relpath));
                $buf .= '<li><div class="row">';
                $buf .= '<a href="#' . $relpath . '_hide" class="hide" id="' . $$disppath . '_hide">' . "$$disppath</a>";
                $buf .= '<a href="#' . $relpath . '_show" class="show" id="' . $$disppath . '_show">' . "$$disppath</a>";
                $buf .= '    <a href="'.$playlisturl . uri_escape_path($unsafe_relpath) . '?fmt=m3u8">M3U</a>';
                $buf .= '<div class="list"><ul>';
            },
            'on_dir_end' => sub {
                $buf .= '</ul></div></div></li>';
            },
            'on_file' => sub {
                my ($realpath, $unsafe_relpath, $unsafe_name) = @_;
                my $relpath = uri_escape($unsafe_relpath);
                my $filename = escape_html(decode('UTF-8', $unsafe_name));
                $buf .= '<li><a href="video?'.$urlconstant.'&name='.$relpath.'&fmt=' . $fmt . '" class="mediafile">' . $$filename . '</a>    <a href="get_video?'.$urlconstant.'&name=' . $relpath . '&fmt=' . $fmt . '">DL</a>    <a href="'.$playlisturl . uri_escape_path($unsafe_relpath) . '?fmt=m3u8">M3U</a></li>';
            }
        });
        return \$buf;
    }

    sub new {
        my ($class, $settings) = @_;
        my $self =  {};
        bless $self, $class;

        $self->{'routes'} = [
            [
                '/video', \&player_video
            ],
            [
                '/video/', sub {
                    my ($request) = @_;
                    $request->SendRedirect(301, '../video');
                }
            ],
        ];
        return $self;
    }

    1;
}

package App::MHFS; #Media Http File Server
use version; our $VERSION = version->declare("v0.4.0");
use strict; use warnings;
use feature 'say';

sub run {
    binmode(STDOUT, ":utf8");
    binmode(STDERR, ":utf8");

    # parse command line args into launchsettings
    my %launchsettings;
    say __PACKAGE__ .": parsing command line args";

    for(my $i = 0; $i < scalar(@ARGV); $i++) {
        if($ARGV[$i] eq 'flush') {
            $launchsettings{'flush'} = 1;
        }
        else {
            defined($ARGV[$i+1]) or die("Missing PARAM");
            if($ARGV[$i] eq '--cfgdir') {
                $launchsettings{'CFGDIR'} = $ARGV[$i+1];
            }
            else {
                die("Unknown PARAM");
            }
            $i++;
        }
    }

    # start the server (blocks)
    say __PACKAGE__.": starting MHFS::HTTP::Server";
    my $server = MHFS::HTTP::Server->new(\%launchsettings,
    ['MHFS::Plugin::MusicLibrary',
    'MHFS::Plugin::GetVideo',
    'MHFS::Plugin::VideoLibrary',
    'MHFS::Plugin::Youtube',
    'MHFS::Plugin::BitTorrent::Tracker',
    'MHFS::Plugin::OpenDirectory',
    'MHFS::Plugin::Playlist',
    'MHFS::Plugin::Kodi',
    'MHFS::Plugin::BitTorrent::Client::Interface'],
    );
}

1;

__END__

=pod

=encoding utf-8

=head1 NAME

App::MHFS - A Media HTTP File Server. Stream your own music and video
library via your browser and standard media players.

=head1 SYNOPSIS

    use App::MHFS;
    App::MHFS->run;

=head1 AUTHOR

Gavin Hayes, C<< <gahayes at cpan.org> >>

=head1 SUPPORT AND DOCUMENTATION

You can find documentation for this module with the perldoc command.

    perldoc App::MHFS

Additional documentation, support, and bug reports can be found at the
MHFS repository L<https://github.com/G4Vi/MHFS>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2022 by Gavin Hayes.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
