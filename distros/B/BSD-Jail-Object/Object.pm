
package BSD::Jail::Object;
use strict;
use warnings;
use vars qw/ @ISA @EXPORT_OK /;
use Exporter;

our $VERSION = '0.02';
@ISA         = qw/ Exporter /;
@EXPORT_OK   = qw/ jids /;

use Inline C       => 'DATA',
           NAME    => 'BSD::Jail::Object',
           VERSION => '0.02';

sub new
{
    my ( $class, $opts ) = @_;

    my $self = {};
    bless $self, $class;
    return $self unless $opts;

    if ( ref $opts eq 'HASH' ) {

        # create a new jail

        if ( $< ) {
            $@ = "jail() requires root";
            return;
        }

        unless ( $opts->{'path'}     &&
                 $opts->{'hostname'} &&
                 $opts->{'ip'} ) {
            $@ = "Missing arguments to create() - need 'path', 'hostname', and 'ip'";
            return;
        }

        my $jid = _create( $opts->{'path'}, $opts->{'hostname'}, $opts->{'ip'} )
            or return;

        $self->{'_data'} = [
            $jid, $opts->{'ip'}, $opts->{'hostname'}, $opts->{'path'}
        ];
    
        return $self;
    }
    else {

        # this object should be linked to an existing jail
        return $self->_init( $opts );

    }
}

sub _init
{
    my $self = shift;
    my $key  = shift;

    return unless $key;

    my ( @data, $type );
    if ( $key =~ /^\d+$/ ) {
        $type = 'jid';
        @data = _find_jail( 0, $key );
    }
    elsif ( $key =~ /^\d+\.\d+\.\d+\.\d+$/ ) {
        $type = 'ip';
        @data = _find_jail( 1, $key );
    }
    else {
        $type = 'hostname';
        @data = _find_jail( 2, $key );
    }

    unless ( scalar @data ) {
        $@ = "No such jail $type: $key";
        return;
    }

    $self->{'_data'} = \@data;
    return $self;
}

sub jid       { shift()->{'_data'}->[0] }
sub ip        { shift()->{'_data'}->[1] }
sub hostname  { shift()->{'_data'}->[2] }
sub path      { shift()->{'_data'}->[3] }

sub attach
{
    my $self = shift;
    return unless $self->jid;

    if ( $< ) {
        $@ = "jail_attach() requires root";
        return;
    }

    return _attach( $self->jid );
}

sub jids
{
    return if ref $_[0]; # shouldn't be used as an object method

    my %opts = @_;

    my @jids = _find_jids();
    return @jids unless $opts{'instantiate'};

    map { $_ = __PACKAGE__->new( $_ ) } @jids;
    return @jids;
}

1;

__DATA__

=pod

=head1 DESCRIPTION

This is an object oriented wrapper around the FreeBSD jail subsystem.

A 5.x or higher FreeBSD system is required.

=head1 SYNOPSIS

Here is an exact replica of the 'jls' utility in just a few lines of perl:

 use BSD::Jail::Object 'jids';

 print "   JID  IP Address      Hostname                      Path\n";
 printf "%6d  %-15.15s %-29.29s %.74s\n",
        $_->jid, $_->ip, $_->hostname, $_->path foreach jids( instantiate => 1 );

And here's 'jexec' (actually, a jexec that lets you optionally select by
something other than jid):

 my $j = BSD::Jail::Object->new( $ARGV[0] ) or die $@;
 $j->attach && chdir('/') && exec $ARGV[1] or exit;

=head1 EXAMPLES

=over 4

=item B<Create a new jail>

 $options = {
     path     => '/tmp',
     ip       => '127.0.0.1',
     hostname => 'example.com'
 };

 $j = BSD::Jail::Object->new( $options ) or die $@;

=item B<Attach to an existing jail>

 $j = BSD::Jail::Object->new( 'example.com' );
 $j->attach;

=item B<Do something in all jails>

 foreach $j ( jids(instantiate => 1) ) {

     if ( fork ) {
         $j->attach;

         #
         # do something exciting
         #

         exit;
     }
 }

=item B<Get information on a jail>

(See the B<SYNOPSIS> section above)

=back

=head1 OBJECT METHODS

=head2 new()

Instantiate a new BSD::Jail::Object object, either by associating
ourselves with an already running jail, or by creating a new one from
scratch.

To associate with an already active jail, I<new()> accepts a jid,
hostname, or ip address.  Errors are placed into $@.

 # existing jail, find by jid
 $j = BSD::Jail::Object->new( 23 ) or die $@;

 # existing jail, find by hostname
 $j = BSD::Jail::Object->new( 'example.com' ) or die $@;

 # existing jail, find by ip address
 $j = BSD::Jail::Object->new( '127.0.0.1' ) or die $@;

Note that if you're selecting a jail by hostname or IP, those aren't
always unique values.  Two jails could be running with the same hostname
or IP address - this module will always select the highest numbered jid
in that case.  If you need to be sure you're in the 'right' jail when
there are duplicates, select by JID.

Create a new jail by passing a hash reference.  Required keys are
'hostname', 'ip', and 'path'.  See the I<jail(8)> man page for specifics
on these keys.

 # create a new jail under /tmp
 $j = BSD::Jail::Object->new({
        hostname => 'example.com',
        ip       => '127.0.0.1',
        path     => '/tmp'
 }) or die $@;

=head2 jid()

Get the current jail identifier.  JIDs are assigned sequentially from
the kernel.

=head2 hostname()

Get the current jail hostname.

=head2 path()

Get the root path the jail was bound to.

=head2 attach()

Imprison ourselves within a jail.  Note that this generally requires
root access, and is a one way operation.  Once the script process
is imprisioned, there is no way to perform a jailbreak!  You'd need
to I<fork()> if you intended to attach to more than one jail.  See
I<EXAMPLES>.

=head1 EXPORTABLE METHODS

=head2 jids()

Returns an array of active JIDs.  Can also return them as
pre-instantiated objects by passing 'instantiate => 1' as an argument.

 my @jail_jids    = jids();
 my @jail_objects = jids( instantiate => 1 );

Only exported upon request.

=head1 ACKNOWLEDGEMENTS

Most of the jail specific C code was based on work 
by Mike Barcroft <mike@freebsd.org> and Poul-Henning Kamp <phk@freebsd.org>
for the FreeBSD Project.

=head1 AUTHOR

Mahlon E. Smith I<mahlon@martini.nu> for Spime Solutions Group
I<(www.spime.net)>

=cut

__C__

#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>

#include <arpa/inet.h>
#include <errno.h>
#include <limits.h>

#include <sys/param.h>
#include <sys/jail.h>

size_t
sysctl_len()
{
    size_t len;
    if ( sysctlbyname( "security.jail.list", NULL, &len, NULL, 0 ) == -1 ) return 0;

    return len;
}

// get jail structure from kernel
struct xprison
*get_xp()
{
    struct xprison *sxp, *xp;
    size_t len;

    len = sysctl_len();
    if ( len <= 0 ) return NULL;

    sxp = xp = malloc(len);
    if ( sxp == NULL ) return NULL;

    // populate the xprison list
    if ( sysctlbyname( "security.jail.list", xp, &len, NULL, 0 ) == -1 ) {
        if (errno == ENOMEM) {
            free( sxp );
            return NULL;
        }
        return NULL;
    }

    // check if kernel and userland is in sync
    if ( len < sizeof(*xp) || len % sizeof(*xp) ||
            xp->pr_version != XPRISON_VERSION ) {
        warn("%s", "Kernel out of sync with userland");
        return NULL;
    }

    free( sxp );
    return xp;
}

// fetch a specific jail's information
void
_find_jail( int compare, char *string )
{ 
    struct xprison *xp;
    struct in_addr in;
    size_t i, len;
    Inline_Stack_Vars;

    Inline_Stack_Reset;
    xp  = get_xp();
    len = sysctl_len();

    /*
       compare == 0    jid
       compare == 1    ip address
       compare == 2    hostname
    */

    for (i = 0; i < len / sizeof(*xp); i++) {
        in.s_addr = ntohl(xp->pr_ip);
        if (
                ( compare == 0 && xp->pr_id == atoi(string) )
                ||
                ( compare == 1 && strcmp( string, inet_ntoa(in) ) == 0 )
                ||
                ( compare == 2 && strcmp( string, xp->pr_host ) == 0 )
           ) {
            Inline_Stack_Push( sv_2mortal( newSViv( xp->pr_id ) ));
            Inline_Stack_Push( sv_2mortal( newSVpvf( inet_ntoa(in) ) ));
            Inline_Stack_Push( sv_2mortal( newSVpvf( xp->pr_host ) ));
            Inline_Stack_Push( sv_2mortal( newSVpvf( xp->pr_path ) ));
            break;
        }
        else {
            xp++;
        }
    }

    Inline_Stack_Done;
}

// return an array of all current jail ids
void
_find_jids()
{ 
    struct xprison *xp;
    size_t i, len;
    Inline_Stack_Vars;

    Inline_Stack_Reset;
    xp  = get_xp();
    len = sysctl_len();

    for (i = 0; i < len / sizeof(*xp); i++) {
        Inline_Stack_Push( sv_2mortal( newSViv( xp->pr_id ) ));
        xp++;
    }

    Inline_Stack_Done;
}

// attach to a jail
int
_attach( int jid )
{
    return ( jail_attach(jid) == -1 ? 0 : 1 );
}

// create a new jail
int
_create( char *path, char *hostname, char *ipaddr )
{
    struct in_addr ip;
    struct jail    j;
    int            jid;

    if ( inet_aton( ipaddr, &ip ) == 0 ) return 0;
    
    j.path      = path;
    j.hostname  = hostname;
    j.ip_number = ntohl( ip.s_addr );
    j.version   = 0;

    if ( (jid = jail( &j )) == -1 ) return 0;

    return jid;
}

