package Cluster::Init;
#

#
# The Design 
# ==========
#
# A collection of event-driven DFA or finite state machines; each machine 
# is its own object.
#
# Daemon machine started first, daemon starts group machines, group machines
# start process machines, process machines start and stop processes.
#
# Client talks to daemon via UNIX domain socket.
#
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp::Assert;
use IO::Socket;
use POSIX qw(:signal_h :errno_h :sys_wait_h);
use IPC::LDT qw(              
  LDT_OK
  LDT_CLOSED
  LDT_READ_INCOMPLETE
  LDT_WRITE_INCOMPLETE
);
use Cluster::Init::DB;
use Cluster::Init::Conf;
use Cluster::Init::Util qw(debug);
use Cluster::Init::Daemon;
use base qw(Cluster::Init::Util);

our $VERSION     = "0.215";

my $debug=$ENV{DEBUG} || 0;

my $cltab="/etc/cltab";


=head1 NAME

Cluster::Init - Clusterwide "init", spawn cluster applications

=head1 SYNOPSIS

  use Cluster::Init;

  unless (fork())
  {
    Cluster::Init->daemon;
    exit 0;
  }

  my $client = Cluster::Init->client;

  # spawn all apps for resource group "foo", runlevel "run"
  $client->tell("foo","run");

  # spawn all apps for resource group "foo", runlevel "runmore"
  # (this stops everything started by runlevel "run")
  $client->tell("foo","runmore");

  # spawn all apps for resource group "bar", runlevel "3"
  # (this does *not* stop or otherwise affect anything in "foo")
  $client->tell("bar",3);

=head1 DESCRIPTION

This module provides basic B<init> functionality, giving you a single
inittab-like file to manage initialization and daemon startup across a
cluster or collection of machines.  

This module is used by B<OpenMosix::HA>, for instance, to provide high
availability with failure detection, automatic migration, and restart
of applications running in a cluster.  B<OpenMosix::HA> provides you
with the ability to build 24x7 mission-critical, high-performance
server farms using only commodity hardware.  See L<OpenMosix::HA>.

I wrote the original version of this module to provide a more flexible
interface between IBM's AIX HACMP cluster manager and managed
applications.  This provided a cleaner configuration, much faster
configuration changes, and respawn ability for individual daemons.

Other uses are possible, including non-cluster environments -- use
your imagination.  Generically, what you get in this package is an
application-level "init" written in Perl, with added ability to
configure resource groups, status file output, and a 'test' runmode
(see below).  

Commercial support for this module is available: see L</SUPPORT>.

=head1 QUICK START

See L<http://www.Infrastructures.Org> for cluster management
techniques, including clean ways to install, replicate, and update
nodes.

See L</CONCEPTS> for an explanation of terms.

Much of the following work is done for you if you're running
B<OpenMosix::HA> on an openMosix cluster -- see L<OpenMosix::HA>.

To use B<Cluster::Init> (without B<OpenMosix::HA>) to manage your
cluster-hosted processes, on either a high-throughput computing
cluster or a high-availability cluster:

=over 4

=item *

Install B<Cluster::Init> on each node.  

=item *

Create L<"/etc/cltab">.

=item * 

Replicate L<"/etc/cltab"> to all nodes.

=item * 

Run 'C<clinit -d>' on each node.  Putting this in F</etc/inittab> as a
"respawn" process would be a good idea, or you could have it started
as a managed process under HACMP, VCS, Linux-HA etc.

=item * 

Run 'C<clinit my_group my_level>' on each node where you want resource
group I<my_group> to be running at runlevel I<my_level>.  

=item * 

Check current status in L<"/var/run/clinit/clstat"> on each node.  (Or
use B<OpenMosix::HA>, which collates this for you across all nodes.)

=back

=head1 INSTALLATION

Use Perl's normal sequence:

  perl Makefile.PL
  make
  make test
  make install

You'll need to install this module on each node in the cluster.  

This module includes a script, L</clinit>, which will be installed when
you run 'make install'.  See the output of C<perl -V:installscript> to
find out which directory the script is installed in.

=head1 CONCEPTS

=over 4

=item Cluster

A group of machines administered as a single unit and offering a
common set of services.  See I<enterprise cluster>,
I<high-availability cluster>, and I<high-throughput cluster>.

=item Computing Cluster

See I<High-Throughput Cluster>.

=item Enterprise Cluster

A well-administered B<enterprise infrastructure> (see
L<http://www.Infrastructures.Org>), in which each machine, whether
desktop or server, provides scalable commodity services.  Any machine
  or group of machines can be easily and quickly replaced, with
minimal user impact, without restoring from backups, with no advance
notice or unique preparation.  May include elements of both I<high
availability> and I<high throughput> clusters.  

=item High-Availability Cluster

(Also B<HA Cluster>.)  A cluster of machines optimized for providing
high uptime and minimal user impact in case of hardware failure, in
return for increased per-node expense and complexity.  Normally
includes shared disk, unattended failover of filesystem mounts and IP
and MAC addresses, and automatic daemon restart on the surviving
node(s).  Suitable for applications such as NFS and database servers,
and other services which normally cannot be replicated easily.

Examples of HA cluster platforms include OpenMosix::HA, Linux-HA, AIX
HACMP, and Veritas VCS.

Due to the expense of providing the per-node redundancy required for
high availability, HA clusters are normally not scalable to the
hundreds of nodes typically needed for high-throughput applications.
OpenMosix::HA is the exception to this rule; it provides an HA layer
on top of a high-throughput openMosix cluster.

=item High-Throughput Cluster

A cluster of machines optimized for cheaply delivering large
quantities of work in a short time, in return for reduced per-process
reliability.  May include features such as process checkpointing and
migration, high-speed interconnects, or distributed shared memory.
Some high-throughput clusters are optimized for scavenging unused
cycles on desktop machines.  Most high-throughput clusters are
suitable for supercomputing-class applications which can be
parallellized across dozens, hundreds, or even thousands of nodes.

Examples of high-throughput cluster platforms include OpenMosix::HA,
openMosix itself, Linux Beowulf, and Condor.

Due to the internode dependencies inherent in distributed shared
memory or migration of interactive processes, high-throughput clusters
normally do not meet the needs of high availability -- they are
intended for brute-force problem solving where the death of a single
process out of thousands is not significant.  High-throughput clusters
are not typically designed to provide mission-critical interactive
services to the public.  

The one (known) exception is OpenMosix::HA -- it provides high
availability for both interactive and batch processes running on a
high-throughput openMosix cluster. 

=item Resource Group

A collection of applications and physical resources (like filesystem
mounts) which need to execute together on the same cluster node.
Resource groups allow easy migration of applications between nodes.

Cluster::Init supports resource groups explicitly.  Resource groups
are configured in L<"/etc/cltab">.

For example, B<sendmail>, F</etc/sendmail.cf>, and the
F</var/spool/mqueue> directory might make up a resource group -- they
all need to be present on the same node.  From L<"/etc/cltab">, you
could spawn the scripts which update F<sendmail.cf>, mount F<mqueue>,
and then start B<sendmail> itself.  

Another example; Apache, a virtual IP address, and the filesystem
containing the HTML document tree might together constitute a resource
group.  To start this resource group, you might need to mount the
filesystem, ifconfig the virtual IP, and start httpd.  This sequence
can easily be specified in F</etc/cltab>.

=back

=head1 UTILITIES

=head2 clinit

Cluster::Init includes B<clinit>, a script which is intended to be a
bolt-in cluster init tool.  The script is called like C<init> or
C<telinit>, with the addition of a new "resource group" argument.  See
the output of C<clinit -h>.  

The first time you execute B<clinit> you will need to use the C<-d>
flag only, to start the B<Cluster::Init> daemon.  This flag does not
automatically background the daemon though -- this is so it will work
as a "respawn" entry in F</etc/inittab>.  If you're testing from the
command line or running from a shell script, use 'C<clinit -d &>'.

Once you have the daemon running, use B<clinit> I<without> the C<-d>
flag.  This will cause it to run as a client only, talking to the
daemon via a UNIX domain socket.  At this point you will use B<clinit>
in roughly the same way you would use the UNIX B<telinit>, in this
case commanding resource groups to switch to different runlevels.
That's it! 

Use the C<-k> flag to tell the daemon and all child processes to shut
down gracefully.

=head1 PUBLIC METHODS

=head2 daemon()

  # start a Cluster::Init server daemon
  Cluster::Init->daemon (
      'cltab' => '/etc/cltab',
      'socket' => '/var/run/clinit/clinit.s'
      'clstat' => '/var/run/clinit/clstat'
			  );

The server-side constructor.  You'll likely want to fork before
calling this method -- it does not return until you issue a
L</shutdown> from a L</client()> process.  See the L</clinit> source code
for an example.  

Accepts an optional hash containing the paths to the configuration
file, socket, and status output file.  You can also specify 'socket'
and 'clstat' locations in L</"/etc/cltab>.

The daemon opens and listens on a UNIX domain socket,
L</"/var/run/clinit/clinit.s"> by default.  The L</client()> will
communicate with the daemon via this socket.  

=cut

sub daemon
{
  my $class = shift;
  my $self = {@_};
  bless $self, $class;
  my $conf = $self->getconf(context=>'server',@_);
  Cluster::Init::Daemon->new(conf=>$conf);
  $self->loop();
  return 1;
}

=head2 client()

  # create a Cluster::Init client object
  my $client = Cluster::Init->client (
      'cltab' => '/etc/cltab',
      'socket' => '/var/run/clinit/clinit.s'
      'clstat' => '/var/run/clinit/clstat'
			  );

The client-side constructor.  

Accepts an optional hash containing the paths to the configuration
file, socket, and status output file.  You can also specify 'socket'
and 'clstat' locations in L</"/etc/cltab>.

Returns a B<Cluster::Init> object.  You'll normally call the resulting
object's L</tell()> method one or more times after this.  See the
L</clinit> source code for example usage.  

The client looks for the L</daemon()> on a UNIX domain socket,
L</"/var/run/clinit/clinit.s"> by default.  

=cut

sub client
{
  my $class = shift;
  my $self = {@_};
  bless $self, $class;
  my $conf = $self->getconf(context=>'client',@_);
  $self->{'socket'} = $conf->get('socket');
  return $self;
}

=head2 tell()

  # tell resource group "mygroup" to change to runlevel "newlevel"
  $client->tell("mygroup", "newlevel");

  # cause Cluster::Init daemon to re-read cltab
  $client->tell(":::ALL:::", ":::REREAD:::");

Tells a running L</daemon()> to change a resource group to a new runlevel.
Called as a method on an object returned by L</client()>.  See the
L</clinit> source code for example usage.  

At this time, this method returns a string containing a success or
failure message.  I don't use this string in B<OpenMosix::HA>, so it
isn't very refined -- it doesn't give you much you can use to detect
failure programmatically, for example.   For a better solution, see
L</status()>.

The C<tell(":::ALL:::", ":::REREAD:::")> usage is only a convention;
in fact, any call to C<tell()> with true values for group and level
will cause a re-read, regardless of whether the values provided match
any actual group or runlevel. 

=cut


sub tell
{
  my $self=shift;
  my $group = shift;
  my $level = shift;
  my $socket = $self->{'socket'};
  affirm { $socket };
  affirm { -S $socket };
  my $client = new IO::Socket::UNIX 
  (
    Peer => $socket,
    Type => SOCK_STREAM
  ) || die $!;
  my $ldt=new IPC::LDT(handle=>$client, objectMode=>1);
  # send command
  debug "sending command $group $level";
  $ldt->send({group=>$group,level=>$level}) || warn $ldt->{'msg'};
  debug "command sent";
  # get response
  my $res;
  until (($res)=$ldt->receive)
  {
    die $ldt->{msg} if $ldt->{rc} == LDT_CLOSED;
  }
  return $res->{msg};
}


=head2 status()

  # return status of all running groups
  my $text=$client->status();

  # filter by group and level
  my $text=$client->status(group=>'foo',level=>'bar');

  # provide nonstandard path to clstat
  my $text=$client->status(group=>'foo',level=>'bar',clstat=>'/tmp/clstat');

This method will read L<"/var/run/clinit/clstat"> for you, dumping it
to stdout.  All arguments are optional.  If you provide 'group' or
'level', then output will be filtered accordingly.  If you specify
'clstat', then the status file at the given pathname will be read
(this is handy if you need to query multiple Cluster::Init status
files in a shared cluster filesystem, and is what B<OpenMosix::HA>
does).

In addition to the usual $obj->status() syntax, the status() method
can also be called as a class function, as in
Cluster::Init::status(clstat=>'/tmp/clstat').   The 'clstat' argument
is required in this case.  Again, this is handy if you want to query a
running Cluster::Init on another machine via a shared filesystem, without
creating an Cluster::Init object or daemon here.  

=cut

sub status
{
  my $self=shift;
  my %parm = @_;
  # allow this to be called as Cluster::Init->status(...)
  $self=bless({},$self) unless ref($self);
  my $group = $parm{'group'} if $parm{'group'};
  my $level = $parm{'level'} if defined($parm{'level'});
  my $clstat = $parm{'clstat'} || $self->conf('clstat');
  die "need to specify clstat" unless $clstat;
  return "" unless -f $clstat;
  my $out ="";
  open(CLSTAT,"<$clstat") || die $!;
  while(<CLSTAT>)
  {
    chomp;
    my ($obj,$name,$stlevel,$state)=split;
    next unless $obj eq "Cluster::Init::Group";
    if ($group)
    {
      next unless $group eq $name;
    }
    if (defined($level))
    {
      next unless $level eq $stlevel;
    }
    $out.="$name " unless $group;
    $out.="$stlevel " unless $level;
    $out.=$state;
    $out.="\n" unless $group && $level;
  }
  return $out;
}

=head2 shutdown()

  # tell daemon to gracefully stop all child processes and exit
  $client->shutdown();

Causes daemon to stop all child processes and exit.  Processes will be
sent SIGINT, SIGTERM, then SIGKILL at intervals of several seconds;
the daemon will not exit until the last process has stopped -- this
method will always return sooner.

=cut

sub shutdown
{
  my $self=shift;
  return $self->tell(":::ALL:::",":::SHUTDOWN:::");
}

sub getconf
{
  my $self=shift;
  $cltab=$self->{cltab} if $self->{cltab};
  $self->{conf} = Cluster::Init::Conf->new(cltab=>$cltab,@_);
  my $conf = $self->{conf};
  return $conf;
}

sub conf
{
  my $self=shift;
  my $var=shift;
  die "can't set conf here" if @_;
  my $conf = $self->{conf};
  return $conf->get($var);
}

sub loop
{
  my $rc=Event::loop();
  debug $rc if $rc;
}

=head1 FILES

=head2 /etc/cltab

The main B<Cluster::Init> configuration file.  Identical in format to
F</etc/inittab>, with a new "resource group" column added.  See
F<t/cltab> in the B<Cluster::Init> distribution for an example.  

The path and name of this file can be changed: see L</daemon()> and
L</client()>.

This file must be replicated across all hosts in the cluster by some
means of your own.  On openMosix clusters, B<OpenMosix::HA> will
replicate this file for you.  See L<http://www.Infrastructures.Org>
for ways to do this in other environments.

You can specify tests to be performed during startup of a resource
group:  In addition to the init-style runmodes of 'once', 'wait',
'respawn', and 'off', B<Cluster::Init> supports a 'test' runmode.  If
the return code of a 'test' command is anything other than zero, then
the resource group as a whole is marked as 'FAILED' in
L</"/var/run/clinit/clstat">.  For example, the 'test' runmode is used by
B<OpenMosix::HA> to test a node for eligibility before attempting to
start a resource group there.

You can specify different locations for L</"/var/run/clinit/clinit.s"> 
and L</"/var/run/clinit/clstat"> in L</"/etc/cltab>, like this:
  
  # location of socket
  :::socket:/tmp/clinit.s
  # location of status file
  :::clstat:/tmp/clstat

Settings found in L</"/etc/cltab> override those found in the
L</daemon()> or L</client()> constructor arguments.

=head2 /var/run/clinit/clstat

Plain-text file showing the status of all running resource groups.
Any time B<Cluster::Init> changes the runlevel of a resource group, it
will update this file.  This file can be read directly or via the
L</status()> method.

The path and name of this file can be changed: see L</daemon()>,
L</client()>, and L</"/etc/cltab">.

=head2 /var/run/clinit/clinit.s

A UNIX domain socket used by L</client()> to communicate with
L</daemon()>.

The path and name of this file can be changed: see L</daemon()>,
L</client()>, and L</"/etc/cltab">.

=head1 BUGS

See TODO file for a more comprehensive and current list.  The most
significant outstanding bugs right now are:

=over 4

=item *

Perl 5.8 incompatibility -- blows chunks with a scalar dereference
error.  This module won't work at all on 5.8 until I get a chance to
fix this.

=item *

Runlevel of '0' (zero) is broken right now; groups named '0' will
probably never be supported either.  If you pass a '0' as an argument
to tell() (either group or level), then whatever you intended to
happen is not going to happen.  

If you're just trying to force a re-read of cltab, then use some
nonexistent group and level; I use C<tell('::ALL::','::REREAD::')> or
somesuch, as mentioned in L</tell()>.

If you're just trying to shut a single group off, use something like
C<tell("realgroupname",999)>.  This will stop all of that group's
processes gracefully, assuming that there is no real runlevel '999'
configured for that group.

=item *

Deleting a group from cltab without stopping it first will cause the
group's processes to be sent SIGKILL -- they will not be stopped
gracefully with SIGINT or SIGTERM.  Better to send
C<tell("group",999)> to stop it gracefully first, as mentioned above.

=item *

Duplicate tags in cltab are detected but not enough useful
exceptions are generated.

=item *

Intermittent failure line 35 t/0232stop.t -- indicator error as far as
I can tell; just re-run C<make test> for now.

=back 

=head1 SUPPORT

Commercial support for this module is available at
L<http://clusters.TerraLuna.Org>.  On that web site, you'll also find
pointers to the latest version, a community mailing list, other
cluster management software, etc.  You can also find help for general
infrastructure (and cluster) administration at
L<http://www.Infrastructures.Org>.

=head1 AUTHOR

	Steve Traugott
	CPAN ID: STEVEGT
	stevegt@TerraLuna.Org
	http://www.stevegt.com

=head1 COPYRIGHT

Copyright (c) 2003 Steve Traugott. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=head1 SEE ALSO

L<OpenMosix::HA>, 
L<http://clusters.TerraLuna.Org>, 
L<http://www.Infrastructures.Org>,
B<init(8)>,
B<telinit(8)>,
B<perl(1)>.

=cut

1; 

__END__


