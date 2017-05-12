#!perl -w

use strict;
use warnings;

=head1 NAME

B<App::CamelPKI::SysV::Apache> - Modeling the Camel-PKI web server.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

   use App::CamelPKI::SysV::Apache;
   use App::CamelPKI::Error;

   my $apache = load App::CamelPKI::SysV::Apache($directory);
   $apache->set_keys(-certificate => $cert, -key => $key,
                     -certification_chain => [ $opcacert, $rootcacert ]);
   $apache->https_port(443);
   try {
       $apache->start();
   } catch App::CamelPKI::Error::OtherProcess with {
       die "Dude, your Apache is out of whack!" if $apache->is_wedged;
       die "Could not start Apache: " .
           $apache->tail_error_logfile();
   };
   $apache->update_crl($crl);
   $apache->stop();

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

Instances of I<App::CamelPKI::SysV::Apache> each represent an Apache Web
server that serves the App-PKI application.  I<App::CamelPKI::SysV::Apache>
encapsulates all the system- and distribution-specific knowledge
needed to run an Apache web server: it knows how to create a
configuration file, start and stop it, manage its PID file, log files,
and so on.

In the current implementation, an instance of
I<App::CamelPKI::SysV::Apache> only listens to one TCP port in HTTP/S, and
the URLs are (mostly) interpreted relative to L<App::CamelPKI>'s standard
URL namespace.  The essential feature of I<App::CamelPKI::SysV::Apache>
that the default, Catalyst-provided server lacks
(C<camel_pki_server.pl>) is the support for client-side authentication
using SSL certificates.  Thanks to this feature, App-PKI is able to
use itself for its own authentication needs.

=cut

package App::CamelPKI::SysV::Apache;

use IO::File;
use IO::Socket::INET;
use Fcntl qw(:seek);
use File::Slurp;
use File::Spec::Functions qw(catfile catdir);
use App::CamelPKI::Error;
use App::CamelPKI::RestrictedClassMethod qw(:Restricted);
use App::CamelPKI::Sys qw(fork_and_do);
use App::CamelPKI::Certificate;

=head1 CONSTRUCTOR AND METHODS

=head2 load($directory)

Creates and returns an instance of I<App::CamelPKI::SysV::Apache> by
loading it from the file system.  Like all constructors that take a
directory as argument, I<load> is subdued to capability discipline
using L<App::CamelPKI::RestrictedClassMethod>.

$directory is the path where the server's various persistent files are
stored (configuration file, PID file, cryptographic keys
etc). $directory must exist, but can be empty.

=cut

sub load : Restricted {
    my ($class, $homedir) = @_;
    # Some Apaches don't interpret relative paths properly:
    $homedir = File::Spec->rel2abs($homedir);
    my $self = bless {
                      homedir => $homedir,
                     }, $class;
    $self->_try_and_parse_config_file;
    $self->tail_error_logfile;
    return $self;
}

=head2 https_port()

=head2 https_port($portnum)

Gets or set the port on which the daemon will listen for HTTP/S
requests.  The default value is 443 if the current process is
privileged enough to bind to it, or 3443 otherwise.  This port number
is persisted onto disk and therefore only needs to be set once.

=head2 test_php_directory()

=head2 test_php_directory($dir)

=head2 test_php_directory(undef)

Gets, sets or disables the test PHP script directory in this instance
of I<App::CamelPKI::SysV::Apache>.  The default is to disable this feature,
which only serves for Camel-PKI's self-tests (unit and integration).

The value of I<test_php_directory> is persisted to disk, so that it need
not be reset at each construction.  It only takes effect the next time
the server is restarted with L</start>.

=head2 has_camel_pki()

=head2 has_camel_pki($boolean)

Gets or sets the "has App-PKI" flag, which defaults to true.
Instances of I<App::CamelPKI::SysV::Apache> that have I<has_camel_pki()> set
to false do not contain the Camel-PKI application.  Again, this is only
useful for tests.

The value of I<has_camel_pki> is persisted to disk, so that it need not
be reset at each construction.  It only takes effect the next time the
server is restarted with L</start>.

=cut

{
    my %defaults =
        (https_port =>
         (IO::Socket::INET->new(LocalPort => 443, ReuseAddr => 1) ?
          443 : 3443),
         test_php_directory => undef,
         has_camel_pki => 1);

    foreach my $persistent_field (keys %defaults) {
        my $getsetter = sub {
            my ($self, @set) = @_;
            if (@set) {
                ($self->{$persistent_field}) = @set;
                $self->_write_config_file(); # Persist
            }
            unless (exists($self->{$persistent_field})) {
                $self->{$persistent_field} = $defaults{$persistent_field};
            }
            return $self->{$persistent_field};
        };
        no strict "refs"; *{$persistent_field} = $getsetter;
    }
}

=head2 set_keys(-certificate => $cert, -key => $key,
                -certification_chain => \@chain)

Installs key material that will allow this Apache daemon to
authenticate itself to its HTTP/S clients ($cert and $key, which must
be instances of L<App::CamelPKI::Certificate> and L<App::CamelPKI::PrivateKey>
respectively), and also to verify the identity of HTTP/S clients that
themselves use a certificate (@chain, which is a list of instances of
L<App::CamelPKI::Certificate>; see also L</update_crl>).  If $cert is a
self-signed certificate, C<-certification_chain> and its parameter
\@chain may be omitted.

=cut

sub set_keys {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, %keys) = @_;
    while(my ($k, $v) = each %keys) {
        if ($k eq "-certificate") {
            write_file($self->_certificate_filename, $v->serialize());
        } elsif ($k eq "-key") {
            write_file($self->_key_filename, $v->serialize());
        } elsif ($k eq "-certification_chain") {
            write_file($self->_ca_bundle_filename,
                       join("", map { $_->serialize } @$v));
        } else {
            throw App::CamelPKI::Error::Internal
                ("INCORRECT_ARGS",
                 -details => "Unknown named option $k");
        }
    }
}

=head2 is_operational()

Returns true if and only if the ad-hoc cryptographic material has been
added to this Web server using L</set_keys>.

=cut

# The above POD is ambiguous on purpose: ->is_operational may someday
# return true even if there is no CA chain available.
sub is_operational {
    my ($self) = @_;
    -r $self->_key_filename && -r $self->_certificate_filename &&
        -r $self->_ca_bundle_filename;
}

=head2 certificate()

Returns the Web server's SSL certificate, as an instance of
L<App::CamelPKI::Certificate>.

=cut

sub certificate {
    App::CamelPKI::Certificate->load(shift->_certificate_filename);
}

=head2 update_crl($crl)

Given $crl, an instance of L<App::CamelPKI::CRL>, verifies the signature
thereof and stores it into this Apache server if and only if it
matches one of the CAs previously installed using L</set_keys>'
C<-certificate_chain> named option, B<and> $crl is older than any CRL
previously added with I<update_crl()>.  If these security checks are
successful and Apache is already running, it will be restarted so as
to take the new CRL into account immediately.

Note that a Web server works perfectly without a CRL, and therefore
calling I<update_crl> is optional.  However, remember that CRLs have
expiration dates: once a CRL has been installed using this method, one
should plan for a suitable mechanism (e.g. a crontab entry) that will
download updated CRLs on a regular basis and submit them using
I<update_crl()>.

=cut

sub update_crl { "UNIMPLEMENTED" }

=head2 start(%opts)

Starts the daemon synchronously, meaning that I<start> will only
return control to its caller after ensuring that the Apache process
wrote its PID file and bound to its TCP port. I<start()> is
idempotent, and terminates immediately if the serveur is already up.

An L<App::CamelPKI::Error/App::CamelPKI::Error::OtherProcess> exception will be
thrown if the server doesn't answer within L</async_timeout> seconds.
An L<App::CamelPKI::Error/App::CamelPKI::Error::User> exception will be thrown
if one attempts to I<start()> the server before providing it with its
certificate and key with L</set_keys>.

Available named options are:

=over

=item I<< -strace => $strace_logfile >>

Starts Apache under the C<strace> debug command, storing all results
into $strace_logfile.

=item I<< -X => 1 >>

Starts Apache with the C<-X> option, which causes it to launch only
one worker and to not detach from the terminal.

=item I<< -gdb => 1 >>

=item I<< -gdb => $tty >>

Starts Apache under the GNU debugger attached to tty $tty (or the
current tty, if the value 1 is specified).  Incompatible with
I<-strace>.  If this option is specified, I<start()> will not time out
after L</async_timeout> seconds, but will instead wait an unlimited
amount of time for the server to come up.

=item I<< -exec => 1 >>

Don't fork a subprocess, use the C<exec> system call instead (see
L<perlfunc/exec>) to run Apache directly (or more usefully, some
combination of Apache and a debugger, according to the above named
options).  The current UNIX process will turn into Apache, and the
I<start> method will therefore never return.

=back

=cut

sub start {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, %opts) = @_;
    throw App::CamelPKI::Error::OtherProcess("Apache is wedged")
        if ($self->is_wedged);
    return if $self->is_started;

    $self->_write_config_file();
    my (@debugprecmd, @dashX);
    my $timeout = 1;
    if (defined(my $stracefile = delete $opts{-strace})) {
        @debugprecmd = ("strace", -o => $stracefile,
                   qw(-f -s 2000));
    } elsif (my $tty = delete $opts{-gdb}) {
        @debugprecmd = ("gdb", ( ($tty eq "1") ? () : ("-tty=$tty") ),
                        "--args");
        $timeout = 0;
    }
    if (delete $opts{-X}) { @dashX = qw(-X); }

    my @fullcmdline =
        (@debugprecmd,
         $self->_apache_bin, @dashX, -f => $self->_config_filename);
    if ($opts{-exec}) {
        exec(@fullcmdline) or
            throw App::CamelPKI::Error::OtherProcess("cannot exec() Apache",
                                                -cmdline => \@fullcmdline);
    } else {
        # Double fork(), so we don't have to bother with zombies :
        fork_and_do { fork_and_do {
            exec @fullcmdline;
        } };
    }

    if ($timeout) {
        $self->_wait_for(sub { $self->is_started })
            or throw App::CamelPKI::Error::OtherProcess("Cannot start Apache");
    } else {
        while(! $self->is_started) { sleep(1); }
    };
    return;
}

=head2 stop()

Stops the daemon synchronously, meaning that I<stop> will only return
control to its caller after ensuring that the Apache process whose PID
is in the PID file is terminated, and the TCP port is closed.  Like
L</start>, this method is idempotent and returns immediately if the
server was already down.

An exception of class L<App::CamelPKI::Error/App::CamelPKI::Error::OtherProcess>
will be thrown if the server still hasn't stopped after
L</async_timeout> seconds.

Note that the "started" or "stopped" state is persisted to the
filesystem using the usual UNIX PID file mechanism; therefore it is
not necessary to use the same Perl object (or even the same process)
to L</start> and I<stop()> a given server.

=cut

sub stop {
    my ($self) = @_;
    throw App::CamelPKI::Error::OtherProcess("Apache is wedged")
        if ($self->is_wedged);
    return # Not wedged and not started means stopped
        if ! defined(my $pid = $self->_process_ready);

    kill TERM => $pid;

    $self->_wait_for(sub { $self->is_stopped })
        or throw App::CamelPKI::Error::OtherProcess("Cannot stop Apache");
    return;
}

=head2 is_started()

Returns true iff the PID file currently contains the PID of a live
Apache process, B<and> one can connect to the TCP port.

=cut

sub is_started {
    my ($self) = @_;
    $self->_process_ready && $self->_port_ready;
}

=head2 is_stopped()

Returns true iff the PID file (if it exists at all) contains something
that is not the PID of a live Apache process, B<and> the TCP port is
closed.

=cut

sub is_stopped {
    my ($self) = @_;
    (! $self->_process_ready) && (! $self->_port_ready);
}

=head2 is_wedged()

Returns true iff neither L</is_stopped>, nor L</is_started> are true
(e.g. if the TCP port is taken, but not by us).  One cannot call
L</start> or L</stop> against an instance of I<App::CamelPKI::SysV::Apache>
that I<is_wedged()> (L<App::CamelPKI::Error/App::CamelPKI::Error::OtherProcess>
exceptions would be thrown).  More generally, neither can one call any
method that act upon other processes such as L</update_crl>.  The
systems administrator therefore needs to take manual corrective action
to get out of this state.

=cut

sub is_wedged {
    my ($self) = @_;
    $self->_process_ready xor $self->_port_ready;
}

sub _has_mod_apsx_support{
	my ($mod_name) = @_;
	
	my @mods = `apxs2 -q LIBEXECDIR | xargs ls | sed 's/\.so//'`;
	foreach (@mods){
	 	$_ =~ s/\n//g;
		return 1 if ($_ =~ /$mod_name/);
	}
	return 0;
}

=head2 is_installed_and_has_perl_support()

Returns true if Apache id installed and has perl support as a static or shared module, 
false otherwise.

=cut

sub is_installed_and_has_perl_support {
	use App::Info::HTTPD::Apache;
	my $apache = App::Info::HTTPD::Apache->new;
	
	return $apache->mod_perl if $apache->mod_perl;
	
	#We are giving a last chance for ubuntu as App::Info::HTTPD::Apache
	# doesn't seems to detect reallay good modules
	return _has_mod_apsx_support("mod_perl");
}

=head2 is_installed_and_has_php_support()

Returns true if Apache id installed and has php support as a static or shared module, 
false otherwise.

=cut

sub is_installed_and_has_php_support {
	use App::Info::HTTPD::Apache;
	my $apache = App::Info::HTTPD::Apache->new;
	
	eval {
		foreach ($apache->static_mods){
			return 1 if ($_ =~ /libphp5/);		
		}
		foreach ($apache->shared_mods){
			return 1 if ($_ =~ /libphp5/);		
		}
	};
	
	#Still last chance for Ubuntu ...
	return _has_mod_apsx_support("libphp5");
}

=head2 is_current_interpreter()

Returns true iff the Perl interpreter we're currently running under is
a mod_perl belonging to this object's I<App::CamelPKI::SysV::Apache>
instance.

=cut

# UNIMPLEMENTED - In order to do this, we could do add a PerlSetVar
# with some UUID to the config file, and check that it is set below.
sub is_current_interpreter { undef }

=head2 is_running_under()

Returns true iff the Perl interpreter currently running is mod_perl.
Contrary to L</is_current_interpreter>, this method returns true even
if called from within B<another> Apache container; in other words it
doesn't look at $self, and indeed it can be called as a class method
too.

=cut

sub is_running_under {
    # We test not only that a version-discriminating subroutine
    # exists, but also that it is implemented in C (as an XSUB), hence
    # the magic with the B package. Thus we don't get fooled with
    # ::bootstrap getting defined as a side effect of Apache::DB
    # loading, or something.
    my @discriminating_symbols =
        (
         2 => "ModPerl::Util::exit",
         1.99 => "ModPerl::Const::compile",
         1 => "Apache::ModuleConfig::bootstrap",
        );
      require B;
      while(my ($version, $discrimsymbol) =
            splice(@discriminating_symbols, 0, 2)) {
          no strict "refs"; my $ref = \&{$discrimsymbol};
          next if (!defined $ref); # Does not seem to ever
          # happen in Perl, but you never know.
          my $bref = B::svref_2object($ref);
          next if (! defined $bref);
          next if (! $bref->XSUB());
          return $version;
      }
      return undef;
}

=head2 async_timeout()

=head2 async_timeout($timeout)

Gets or sets the maximum time (in seconds) that L</start> and L</stop>
will wait for the Apache server to come up (resp. down).  The default
value is 20 seconds; it does B<not> get persisted, and therefore must
be set by caller code after each L</load>.

=cut

sub async_timeout {
    my ($self, @set) = @_;
    ($self->{async_timeout}) = @set if (@set);
    return ( $self->{async_timeout} ||= 120);
}

=head2 tail_error_logfile()

Returns the amount of text that was appended to the error log file
since the object was created since the previous call to
I<tail_eror_logfile()> (or barring that, to L</load>).  Returns undef
if the log file does not exist (yet).

=cut

sub tail_error_logfile {
    my ($self) = @_;
    my $log = new IO::File($self->_error_log_filename);
    $self->{offset} = 0, return if (! defined $log);

    my $retval;
    if (defined wantarray) {
        $log->seek($self->{offset}, SEEK_CUR)
            or throw App::CamelPKI::Error::IO
                ("cannot seek", -IOfile => $self->_error_log_filename);
        $retval = join('', $log->getlines);
    } else { # Notamment à la construction
        $log->seek(0, SEEK_END)
            or throw App::CamelPKI::Error::IO
                ("cannot seek to end of file",
                 -IOfile => $self->_error_log_filename);
    }

    $self->{offset} = $log->tell();
    return $retval;
}

=head1 TODO

In B<App::CamelPKI::Apache>'s current implementation, only Apache 2 for
Ubuntu Edgy is supported.  However, the encapsulation of the class
makes it easy to support other environments, without changing anything
in the rest of Camel-PKI.

=begin internals

=head1 INTERNAL METHODS

=head2 _apache_bin()

Returns the path to Apache's binary.

=cut

sub _apache_bin { "/usr/sbin/apache2" }

=head2 _has_module_built_in($module_shortname)

Returns true if apache has $module_shortname (e.g. "mime") built-in.

=cut

use File::Slurp;
sub _has_module_built_in {
	my ($class, $modulename) = @_;
	my $bin = read_file($class->_apache_bin);
	if ($bin =~ m/mod_$modulename/) {
		return 1;
	}
	return 0;
}

=head2 _pid_filename()

Returns the path to this Apache daemon's PID file.

=cut

sub _pid_filename { catfile(shift->{homedir}, "apache.pid") }

=head2 _config_filename()

Returns the path to this daemon's configuration file (which is
automagically generated by L</_write_config_file>).

=cut

sub _config_filename { catfile(shift->{homedir}, "httpd-DO-NOT-EDIT.conf") }


=head2 _error_log_filename()

Returns the path to this Apache dameon's error log file.

=cut

sub _error_log_filename { catfile(shift->{homedir}, "error.log") }

=head2 _certificate_filename()

Returns the path to this Apache daemon's SSL server certificate file.

=cut

sub _certificate_filename { catfile(shift->{homedir}, "webserver.crt") }

=head2 _key_filename()

Returns the path to this Apache daemon's SSL private key.

=cut

sub _key_filename { catfile(shift->{homedir}, "webserver.key") }

=head2 _ca_bundle_filename()

Returns the path to the file that contains the concatenated PEM
certificates in the certification chain.

=cut

sub _ca_bundle_filename { catfile(shift->{homedir}, "ca-bundle.crt") }

=head2 _port_ready()

=head2 _port_ready($port)

Returns true iff TCP port $port is open on IPv4 localhost (127.0.0.1).
$port is L</https_port> by default.

Note that the check is performed by attempting to connect to the port
on 127.0.0.1, and closing the port right away.  A strange error log
message may ensue.

=cut

sub _port_ready {
    my ($self, $port) = @_;
    $port ||= $self->https_port;
    defined(IO::Socket::INET->new(PeerHost => "127.0.0.1",
                                  PeerPort => $port));
}

=head2 _process_ready()

Returns true (specifically, the PID of the parent Apache process) iff
the file pointed to by L</_pid_filename> contains the PID of a live
process whose name is "apache" (ou "apache2" ou "httpd", depending on
the distribution).

=cut

sub _process_ready {
    my ($self) = @_;
    return if ! -f $self->_pid_filename;
    chomp(my $pid = read_file($self->_pid_filename));
    my $cmdline = readlink("/proc/$pid/exe"); # No catfile() jazz,
    # /proc is not portable anyway
    return $pid if (defined($cmdline) && $cmdline eq $self->_apache_bin);
    return;
}

=head2 _wait_for($sub)

Waits until $sub, a CODE reference called without arguments in scalar
context, returns true; but waits no more than L</async_timeout>
seconds.  Returns whatever $sub returned the last time it was called.

=cut

sub _wait_for {
    my ($self, $sub) = @_;
    my $retval;
    for(1 .. $self->async_timeout) {
        last if $retval = $sub->();
        sleep(1);
    }
    return $retval;
}

=head2 _write_config_file()

Writes the configuration file into the path returned by
L</_config_file>.

=cut

sub _write_config_file {
    my ($self) = @_;

    # TODO: refrain from overwriting the file when it is more recent
    # than App/PKI/SysV/Apache.pm, so as to cut some slack to wise-guy
    # sysadmins.

    my $banner = <<'BANNER';
# Automatically generated Apache configuration file.
# Do not edit - Your changes will be lost.  Repeat:
#  ____                      _              _ _ _   _
# |  _ \  ___    _ __   ___ | |_    ___  __| (_) |_| |
# | | | |/ _ \  | '_ \ / _ \| __|  / _ \/ _` | | __| |
# | |_| | (_) | | | | | (_) | |_  |  __/ (_| | | |_|_|
# |____/ \___/  |_| |_|\___/ \__|  \___|\__,_|_|\__(_)
#
# See "perldoc App::CamelPKI::SysV::Apache".
BANNER

    my $homedir   = $self->{homedir};
    my $port      = $self->https_port;
    my $pidfile   = $self->_pid_filename;
    my $certfile  = $self->_certificate_filename;
    my $keyfile   = $self->_key_filename;
    my $ca_bundle = $self->_ca_bundle_filename;
    my $error_log = $self->_error_log_filename;

    # Propagate -Iblib/lib to the Apache server, so that it can load
    # Camel-PKI from the build directory if needed.
    my $perlswitches;
    if (my @blibs = grep { m/\bblib\W+lib\b/ } @INC) {
        my $perlincs = join(" ", map { "-I$_" } @blibs);
        $perlswitches = <<"PERLSWITCHES";
# As seen on http://www.catalystframework.org/calendar/2005/7:
PerlSwitches $perlincs
PERLSWITCHES
    }

    # FIXME: this is Gentoo- and  Edgy-specific.
    #TODO : refactor for using the App::Info::HTTP :)
    my %module_paths =
        (alias => "/usr/lib/apache2/modules/mod_alias.so",
         perl => "/usr/lib/apache2/modules/mod_perl.so",
         php5 => "/usr/lib/apache2/modules/libphp5.so",
         ssl  => "/usr/lib/apache2/modules/mod_ssl.so",
         mime  => "/usr/lib/apache2/modules/mod_mime.so",
        );
    my @mods_to_configure = grep { $self->_has_module_built_in($_) }
   		(keys %module_paths);
    push @mods_to_configure, qw(perl ssl); # Unconditionally needed

    my $phpstuff = "";
    if (is_installed_and_has_php_support()) {
    	if (defined(my $phpdir = $self->test_php_directory)) {
        	push(@mods_to_configure, "php5", "alias", "mime");
        	$phpstuff = <<"PHPSTUFF";
#### PHP test directory
Alias /t/php "$phpdir"
<location /t/php>
  AddType application/x-httpd-php .php
</location>
PHPSTUFF
    	}
    }

    my $modmime= "";
    if (grep { $_ eq "mime" } @mods_to_configure) {
    	$modmime = <<"MODMIME";
### Attic: mod_mime boilerplate configuration
# We basically don't use this, unfortunately both Ubuntu's
# and Gentoo's Apaches have default configurations that do
# not match the actual filesystem layout :-(
TypesConfig /etc/mime.types
MODMIME
    }

    my $loadmodules = join("", map { <<"LOADMODULE" }
LoadModule ${_}_module ${\$module_paths{$_}}
LOADMODULE
	    (grep { ! $self->_has_module_built_in("$_") }
             @mods_to_configure));

    my $catalyststuff = "";
    $catalyststuff = <<"CATALYST_STUFF" if $self->has_camel_pki();
#### Main application configuration
PerlModule App::CamelPKI
<LocationMatch "^(?!/t/)">
        SetHandler          modperl
        PerlResponseHandler App::CamelPKI
</LocationMatch>
CATALYST_STUFF

    write_file($self->_config_filename, <<"CONFIG");
$banner

$loadmodules

ServerName     Camel-PKI
ServerRoot     $homedir

Listen $port

#### Files
PidFile               $pidfile
SSLCertificateFile    $certfile
SSLCertificateKeyFile $keyfile
SSLCACertificateFile  $ca_bundle
ErrorLog              $error_log
LockFile              $homedir/httpd.lock
ScoreBoardFile        $homedir/httpd.scoreboard

#### SSL configuration
SSLEngine on
# Dissect SSL connection info into \$r->subprocess_env:
SSLOptions +StdEnvVars +ExportCertData
#Minor Bug in Firefox 3.0 :
SSLProtocol all -TLSv1
# Ask for a certificate every time, but do not barf if none is given:
SSLVerifyClient optional
# Work around some of the rampant OpenSSL braindamage:
SSLVerifyDepth 250
# Loads all digests into OpenSSL by side effect, thereby allowing mod_ssl
# to grok SHA-256 certificates (which it normally doesn't):
PerlModule Crypt::OpenSSL::CA

$phpstuff

$perlswitches
$catalyststuff

$modmime

CONFIG
}

=head2 _try_and_parse_config_file()

Retrieves persistent information from the configuration file
(e.g. port number and PHP directory) and populates this object's
fields accordingly.  Returns true if the parsing was successful.
Returns false if there was no configuration file to parse.  Throws an
exception in any other case.

=cut

sub _try_and_parse_config_file {
    my ($self) = @_;
    return if ! -f $self->_config_filename();
    my $configtext = read_file($self->_config_filename());
    (($self->{https_port}) = $configtext =~ m/Listen (\d+)/ )
        or throw App::CamelPKI::Error::State
            ("Configuration file was tampered with",
             -config_file => $self->_config_filename());
    ($self->{test_php_directory}) =
        $configtext =~ m|Alias /t/php "(.*)"|; # Optional
    $self->{has_camel_pki} =
        ($configtext =~ m/PerlModule App::CamelPKI/) ? 1 : 0;
    return 1;
}

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use Fatal qw(mkdir);
use File::Slurp;
use File::Spec::Functions qw(catdir catfile);
use LWP::Simple ();
use Crypt::OpenSSL::CA;
use App::CamelPKI::Error;
use App::CamelPKI::Time;
use App::CamelPKI::Certificate;
use App::CamelPKI::PrivateKey;
use App::CamelPKI::CRL;
use App::CamelPKI::Sys qw(fork_and_do);
use App::CamelPKI::Test qw(%test_entity_certs %test_keys_plaintext
                      %test_rootca_certs);

=head2 Prologue

According to L</SYNOPSIS>, the Apache server needs a home directory, a
certificate, a private key, a certification chain and a CRL.

=cut

my $rootcacert = App::CamelPKI::Certificate->parse
    ($test_rootca_certs{rsa1024});
my $rootcakey = App::CamelPKI::PrivateKey->parse
    ($test_keys_plaintext{rsa1024});
my $crl = new Crypt::OpenSSL::CA::X509_CRL();
$crl->set_issuer_DN($rootcacert->get_subject_DN);
$crl->set_extension("crlNumber", "0x01", -critical => 1);
my $now = App::CamelPKI::Time->now;
$crl->set_lastUpdate($now->advance_days(-1));
$crl->set_nextUpdate($now->advance_days(+1));
$crl = App::CamelPKI::CRL->parse
    ($crl->sign($rootcakey->as_crypt_openssl_ca_privatekey, "sha256"));
ok(! $crl->is_member($rootcacert), "test CRL OK");

=head3 fresh_directory()

Returns a fresh, empty directory for tests.

=cut

{
    my $unique = 0;
    sub fresh_directory {
        mkdir(my $retval = catdir(My::Tests::Below->tempdir(),
                                  "apache" . $unique++));
        return $retval;
    }
}

=head3 make_apache_operational($in_directory)

Instruments $in_directory for use as an Apache home directory, that
is, the C<$directory> parameter to L</load>.  The various
cryptographic materials and configuration files will be set up if they
aren't already, and a new, unused port will be allocated.  Returns
$in_directory.

=cut

{
    my $freshport = 12346;
    sub make_apache_operational {
        my ($directory) = @_;
        mkdir($directory) unless -d $directory;

        my $apache = load App::CamelPKI::SysV::Apache($directory);
        return if $apache->is_operational;

        $apache->set_keys
            (-certificate => App::CamelPKI::Certificate->parse
             ($test_entity_certs{rsa1024}),
             -key => App::CamelPKI::PrivateKey->parse
             ($test_keys_plaintext{rsa1024}),
             -certification_chain => [ $rootcacert ]);
        $apache->https_port($freshport++);

        return $directory;
    }
}

=pod

=head2 Tests proper

=cut

my $directory = fresh_directory;
END { App::CamelPKI::SysV::Apache->load($directory)->stop()
    if defined $directory; }

SKIP: {
	use App::CamelPKI; 
	my $webserver = App::CamelPKI->model("WebServer")->apache;
	
	skip "Apache is not installed or Key Ceremony has not been done", 13 
		unless ($webserver->is_installed_and_has_perl_support);

	
test "Quiet state" => sub {
    my $apache = load App::CamelPKI::SysV::Apache($directory);
    is($apache->https_port, 3443, "We probably aren't root");
    ok($apache->has_camel_pki);
    is($apache->test_php_directory, undef);
    ok(! $apache->is_started);
    ok($apache->is_stopped);
    ok(! $apache->is_operational);
    ok(! $apache->is_wedged);
};

test "synopsis" => sub {
    	App::CamelPKI::SysV::Apache->load($directory)->stop();

    	my $cert = App::CamelPKI::Certificate->parse($test_entity_certs{rsa1024});
    	my $key = App::CamelPKI::PrivateKey->parse($test_keys_plaintext{rsa1024});
    	my $opcacert = $rootcacert; # Heh.
    	my $code = My::Tests::Below->pod_code_snippet("synopsis");
    	ok($code =~ s/\bmy /our /g);
    	ok($code =~ s/443/12345/g); # Since we are not root
    	eval "package Synopsis; $code"; die $@ if $@;
    	is($Synopsis::apache->https_port, 12345, "port number was remembered");
    	ok($Synopsis::apache->is_operational);
};

make_apache_operational($directory);

test "->start() and ->stop() idempotent" => sub {
    App::CamelPKI::SysV::Apache->load($directory)->stop();

    my $apache = load App::CamelPKI::SysV::Apache($directory);
    ok(! $apache->is_started());
    $apache->start();
    ok($apache->is_started());
    $apache->start();
    ok($apache->is_started(), "->start() idempotent");
    $apache->stop();
    ok(! $apache->is_started());
    $apache->stop();
    ok(! $apache->is_started(), "->stop() idempotent");
};

test "IPC and persistence" => sub {
    App::CamelPKI::SysV::Apache->load($directory)->stop();

    my $apache = load App::CamelPKI::SysV::Apache($directory);
    is($apache->https_port, 12345, "port number was persisted");
    ok($apache->is_operational, "key material was persisted");

    ok(! $apache->is_started);
    waitpid(fork_and_do {
        my $apache = load App::CamelPKI::SysV::Apache($directory);
        $apache->start();
    }, 0);
    ok($apache->is_started, "started/stopped status was persisted");
    $apache->stop();
    ok(! $apache->is_started, "can stop from another process than "
       . "the one that started");
};

test "->tail_error_logfile" => sub {
    App::CamelPKI::SysV::Apache->load($directory)->stop();

    my $apache = load App::CamelPKI::SysV::Apache($directory);
    is($apache->tail_error_logfile(), "");
    $apache->start();
    like($apache->tail_error_logfile(), qr/resuming normal operations/i);
    is($apache->tail_error_logfile(), "");
};

test "->is_wedged()" => sub {
    App::CamelPKI::SysV::Apache->load($directory)->stop();

    my $apache = load App::CamelPKI::SysV::Apache($directory);
    ok(! $apache->is_wedged());
    $apache->start();
    ok(! $apache->is_wedged());
    chomp(my $pid = read_file($apache->_pid_filename()));
    like($pid, qr/^\d+$/);
    unlink($apache->_pid_filename());
    ok($apache->is_wedged());

    ok(kill(TERM => $pid), "manual corrective action");
    ok($apache->_wait_for(sub { ! $apache->is_wedged }), "unwedged");
};

test "->is_running_under returns false in a normal Perl" => sub {
    ok(! App::CamelPKI::SysV::Apache->is_running_under);
};

SKIP: {
	use App::CamelPKI;
	my $webserver = App::CamelPKI->model("WebServer")->apache;
	
	skip "Key Ceremony has not been done", 1 
		unless $webserver->is_operational; 
		
	test "App::CamelPKI service" => sub {
    	my $webserver = App::CamelPKI::SysV::Apache->load($directory);
    	$webserver->start();
    	my $ca = LWP::Simple::get("https://localhost:12345/ca/certificate_pem");
    	like($ca, qr/BEGIN CERTIFICATE/)
        	or warn $webserver->tail_error_logfile;
	}
};

mkdir(my $phpdir = catdir(My::Tests::Below->tempdir, "php"));
SKIP: {
	use App::CamelPKI; 
	my $webserver = App::CamelPKI->model("WebServer")->apache;
		skip "modphp is not installed", 2
			unless ($webserver->is_installed_and_has_php_support);

	test "PHP pages in t/php" => sub {
    	my $webserver = App::CamelPKI::SysV::Apache->load($directory);
    	is($webserver->test_php_directory, undef);
    	$webserver->test_php_directory($phpdir);
    	$webserver->stop(); $webserver->start();
    	$webserver = App::CamelPKI::SysV::Apache->load($directory);
    	is($webserver->test_php_directory, $phpdir,
       		"test_php_directory persistent");
    	write_file(catfile($phpdir, "phpinfo.php"), <<"PHPINFO");
<?php
phpinfo();
?>
PHPINFO
	    my $phpinfo = LWP::Simple::get
    	    ("https://localhost:12345/t/php/phpinfo.php");
    	like($phpinfo, qr/www\.php\.net/);
	};

	use IO::Socket::SSL;
	use LWP::UserAgent;
	use App::CamelPKI::Test qw(http_request_prepare http_request_execute);
	test "SSL client w/ certificate" => sub {
    	my $webserver = App::CamelPKI::SysV::Apache->load($directory);
    	unless ($webserver->test_php_directory) {
        	$webserver->test_php_directory($phpdir);
        	$webserver->stop();
    	}
    	$webserver->start();

    	write_file(catfile($phpdir, "ssl_vars.php"), <<'PHP_SSL_VARS');
$_SERVER["HTTPS"]             = <?php print $_SERVER["HTTPS"] ?>

$_SERVER["SSL_CLIENT_VERIFY"] = <?php print $_SERVER["SSL_CLIENT_VERIFY"] ?>

$_SERVER["SSL_CLIENT_S_DN"]   = <?php print $_SERVER["SSL_CLIENT_S_DN"] ?>

PHP_SSL_VARS

	    my $req = http_request_prepare
    	    ('https://localhost:12345/t/php/ssl_vars.php');
    	my $response = http_request_execute($req);
    	die $response->content unless $response->is_success;
    	like($response->content, qr/HTTPS.* = on/);
    	like($response->content, qr/SSL_CLIENT_VERIFY.* = NONE/);

    	my %opts = (-certificate => $test_entity_certs{"rsa1024"},
                	-key => $test_keys_plaintext{"rsa1024"});
    	$req = http_request_prepare
        	('https://localhost:12345/t/php/ssl_vars.php', %opts);
    	$response = http_request_execute($req, %opts);
    	die $response->content unless $response->is_success;
    	like($response->content, qr/HTTPS.* = on/);
    	like($response->content, qr/SSL_CLIENT_VERIFY.* = SUCCESS/);
    	like($response->content, qr/SSL_CLIENT_S_DN.* = .*CN=John Doe/);
	};
};

use App::CamelPKI::Test qw(certificate_chain_ok);
use App::CamelPKI::CertTemplate;

=head2 SHA-256 authentication failure regression suite

Trying to authenticate to an I<App::CamelPKI::SysV::Apache> instance using
SHA256 client certificates used to elicit a cryptic error message.
This is because mod_ssl only knows about the hash algorithms from the
TLsv1 suite out of the box (and SHA256 is not one of these).  The
following two tests exercise that.

The current solution is to add a "PerlModule Crypt::OpenSSL::CA" that
calls C<OpenSSL_add_all_digests()> as a side effect, but we need to
find a better way lest every server in Camel-PKI have to contain a
mod_perl just for that.

=cut

sub make_bogus_keypair_using_hash {
    my ($hash, $admincertfile, $adminkeyfile) = @_;

    write_file($adminkeyfile, $test_keys_plaintext{"rsa1024"});
    my $qualifier = ($hash =~ m/sha.*256/i) ? "_sha256" : "";
    write_file($admincertfile, $test_entity_certs{"rsa1024$qualifier"});
}

sub ok_connect_no_hiccups {
    my ($webserver, $admincertfile, $adminkeyfile) = @_;
    $webserver->tail_error_logfile;
    local @LWP::Protocol::http::EXTRA_SOCK_OPTS;
    @LWP::Protocol::http::EXTRA_SOCK_OPTS =
        (SSL_use_cert => 1,
         SSL_cert_file => $admincertfile, SSL_key_file => $adminkeyfile);
    my $ua = new LWP::UserAgent;
    my $port = $webserver->https_port;
    my $response = $ua->get("https://localhost:$port/no/such/uri");
    is($response->code, 404, "500 would be bad") or
        diag $response->content;
    unlike($webserver->tail_error_logfile,
           qr/certificate signature failure/, <<"EXPLANATION");
``certificate signature failure'' is the message one gets when mod_ssl
attempts to validate a certificate whose hash algorithm it doesn't
know about.
EXPLANATION
}

my $sha256directory = fresh_directory;
END { App::CamelPKI::SysV::Apache->load($sha256directory)->stop()
    if defined $sha256directory; }

test "witness experiment: authenticating with hand-made".
    " sha1 client certificates" => sub {
    make_apache_operational($sha256directory);
    my $webserver = App::CamelPKI::SysV::Apache->load($sha256directory);
    $webserver->has_camel_pki(0);
    $webserver->start();

    mkdir(my $keysdir = catdir(My::Tests::Below->tempdir, "sha1keys"));
    my $admincertfile = catfile($keysdir, "admin.pem");
    my $adminkeyfile = catfile($keysdir, "admin.key");
    make_bogus_keypair_using_hash("sha1", $admincertfile, $adminkeyfile);
    ok_connect_no_hiccups($webserver, $admincertfile, $adminkeyfile);
};

test "REGRESSION: authenticating with sha256 client certificates" => sub {
    make_apache_operational($sha256directory);
    my $webserver = App::CamelPKI::SysV::Apache->load($sha256directory);
    $webserver->has_camel_pki(0);
    $webserver->start();

    mkdir(my $keysdir = catdir(My::Tests::Below->tempdir, "sha256keys"));
    my $admincertfile = catfile($keysdir, "admin.pem");
    my $adminkeyfile = catfile($keysdir, "admin.key");
    make_bogus_keypair_using_hash("sha256", $admincertfile, $adminkeyfile);
    ok_connect_no_hiccups($webserver, $admincertfile, $adminkeyfile);
};
};
=end internals

=cut
