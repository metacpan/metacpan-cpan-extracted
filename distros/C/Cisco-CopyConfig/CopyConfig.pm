#!/usr/bin/perl -w
###
### $Id: CopyConfig.pm,v 1.3 2004/11/04 22:23:19 aaronsca Exp aaronsca $
###
### -- Manipulate running-config of devices running IOS
###

package Cisco::CopyConfig;
use strict;
use Socket;
use Net::SNMP;
$Cisco::CopyConfig::VERSION = sprintf "%d.%02d", q$Revision: 1.3 $ =~ /(\d+)/g;

sub new {
###
### -- Create a new CopyConfig object

  my($class)	= shift;				## - Object class
  my($self)	= bless {
    'err'	=> '',					## - Error message
    'host'	=> '',					## - Default host
    'comm'	=> '',					## - Default community
    'tmout'	=> 2,					## - Default timeout
    'retry'	=> 2					## - Default retries
  }, $class;
  $self->_newarg(@_);					## - Parse arguments
  srand(time() ^ ($$ + ($$ << 15)));			## - Seed random number
  $self->{'snmp'} = $self->open();			## - Get SNMP object
  $self;
}

sub open {
###
### -- Create SNMP session and return object

  my($self)	= shift;

  $self->_newarg(@_);					## - Parse arguments
  unless(defined($self->{'host'}) && defined($self->{'comm'})){
    $self->{'err'} = 'missing hostname or community string';
    return undef;
  }
  $self->{'snmp'} = Net::SNMP->session(			## - Create SNMP object
    Hostname	=> $self->{'host'},
    Community	=> $self->{'comm'},
    Timeout	=> $self->{'tmout'},
    Retries	=> $self->{'retry'},
    Version	=> 1
  );
}

sub close {
###
### -- Shut down SNMP session and destroy SNMP object

  my($self)	= shift;
  my($status)	= $self->{'snmp'}->close();

  $self->{'snmp'} = undef;
  $status;
}

sub copy {
###
### -- Copy a running-config to a tftp server file

  my($self)	= shift;
  my($addr)	= shift || return undef;
  my($file)	= shift || return undef;

  unless($self->_cktftp($addr, $file)){
    return undef;
  }
  $self->{'rand'} = int(rand(1 << 24));
  $self->_xfer(
    $self->ccCopyProtocol(1),
    $self->ccCopySourceFileType(4),
    $self->ccCopyDestFileType(1),
    $self->ccCopyServerAddress($addr),
    $self->ccCopyFileName($file),
    $self->ccCopyEntryRowStatus(4)
  );
}

sub merge {
###
### -- Merge a tftp server file into a running-config

  my($self)	= shift;
  my($addr)	= shift || return undef;
  my($file)	= shift || return undef;

  unless($self->_cktftp($addr, $file)){
    return undef;
  }
  $self->{'rand'} = int(rand(1 << 24));
  $self->_xfer(
    $self->ccCopyProtocol(1),
    $self->ccCopySourceFileType(1),
    $self->ccCopyServerAddress($addr),
    $self->ccCopyFileName($file),
    $self->ccCopyDestFileType(4),
    $self->ccCopyEntryRowStatus(4)
  );
}

sub error {
###
### -- Return last error message

  my($self)	= shift;

  defined($self->{err}) ? $self->{err} : '' ;
}

sub _newarg {
###
### -- Parse new object arguments

  my($self)	= shift;
  my(%arg)	= @_;

  foreach(keys %arg){
    $self->{'host'}  = $arg{$_}, next if /^Host$/oi;	## - SNMP host
    $self->{'comm'}  = $arg{$_}, next if /^Comm$/oi;	## - SNMP community 
    $self->{'tmout'} = $arg{$_}, next if /^tmout$/oi;	## - SNMP timeout
    $self->{'retry'} = $arg{$_}, next if /^Retry$/oi;	## - SNMP timeout
  }
}

sub _cktftp {
###
### -- Check tftp arguments

  my($self)	= shift;
  my($addr)	= shift;
  my($file)	= shift;

  if ($addr !~ /^[\d\.]+$/ || !defined(inet_aton($addr))) {
    $self->{err} = 'invalid tftp server address';
    return 0;
  }
  1;
}

sub _xfer {
###
### -- Do actual tftp transfer

  my($self)	= shift;
  my(@oids)	= @_;					## - OIDs to use
  my($snmp)	= $self->{'snmp'};			## - Net::SNMP subclass
  my($answer)	= '';					## - SNMP answer
  my($status)	= 0;					## - SNMP xfer status

  $snmp->set_request(@oids);				## - Start xfer
  if ($snmp->error()) {
    $self->{'err'} = $snmp->error();
    return 0;
  }
  while($status <= 2){
    $answer	= $snmp->get_request($self->ccCopyState());
    $status	= $answer->{$self->ccCopyState()};
    if ($status == 3) {					## Xfer succeeded
      last;
    }
    if ($status == 4) {					## Xfer failed
      $answer	= $snmp->get_request($self->ccCopyFailCause());
      $status	= $answer->{$self->ccCopyFailCause()};

      $self->{'err'}	= 'unknown error'	if $status == 1;
      $self->{'err'}	= 'file access error'	if $status == 2;
      $self->{'err'}	= 'tftp timeout'	if $status == 3;
      $self->{'err'}	= 'out of memory'	if $status == 4;
      $self->{'err'}	= 'no configuration'	if $status == 5;
      return 0;
    }
    sleep(2);
  }
  $snmp->set_request($self->ccCopyEntryRowStatus(6)); 	## - Clear entry row
  1;
}

### -- OIDs taken from CISCO-CONFIG-COPY-MIB-V1SMI.my
###
sub ccCopyProtocol       {
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.2.'  . $_[0]->{'rand'}, INTEGER, $_[1])
}
sub ccCopySourceFileType {
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.3.'  . $_[0]->{'rand'}, INTEGER, $_[1])
}
sub ccCopyDestFileType   {
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.4.'  . $_[0]->{'rand'}, INTEGER, $_[1])
}
sub ccCopyServerAddress  {
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.5.'  . $_[0]->{'rand'}, IPADDRESS, $_[1])
}
sub ccCopyFileName       {
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.6.'  . $_[0]->{'rand'}, OCTET_STRING, $_[1])
}
sub ccCopyEntryRowStatus {
  ('1.3.6.1.4.1.9.9.96.1.1.1.1.14.' . $_[0]->{'rand'}, INTEGER, $_[1])
}
sub ccCopyState          { 
  '1.3.6.1.4.1.9.9.96.1.1.1.1.10.'  . $_[0]->{'rand'}
}
sub ccCopyFailCause      { 
  '1.3.6.1.4.1.9.9.96.1.1.1.1.13.'  . $_[0]->{'rand'}
}
1;							## - Needed for module

__END__

=head1 NAME

Cisco::CopyConfig - IOS running-config manipulation

=head1 SYNOPSIS

use Cisco::CopyConfig ();

see METHODS section below

=head1 DESCRIPTION

Cisco::CopyConfig provides methods for manipulating the running-config of 
devices running IOS via SNMP directed TFTP.  This module is essentially a 
wrapper for Net::SNMP and the CISCO-CONFIG-COPY-MIB-V1SMI.my MIB schema. 

=head1 PREPERATION

A read-write SNMP community needs to be defined on each device, which allows
the setting of parameters to copy or merge a running-config. Below is an 
example configuration that attempts to restrict read-write access to only the 
10.0.1.3 host (a less guessable community than 'public' would be wise):

    access-list 10 permit host 10.0.1.3
    access-list 10 deny any
    !
    snmp-server tftp-server-list 10
    snmp-server view backup ciscoMgmt.96.1.1.1.1 included
    snmp-server community public view backup RW 10
    end

=head1 METHODS

=over 8

=item I<new>

Create a new Cisco::CopyConfig object.

    $config = Cisco::CopyConfig->new(
               Host  => $ios_device_hostname,
               Comm  => $community_string,
            [ Tmout  => $snmp_timeout_in_seconds, ]
            [ Retry  => $snmp_retries_on_failure, ]
    );

=item I<copy>

Copy the running-config to a file via TFTP:

    $config->copy($tftp_address, $tftp_file);

=item I<merge>

Merge a configuration file into the running-config via TFTP:

    $config->merge($tftp_address, $tftp_file);

=item I<error>

Return the last error message, if any.  This is a convenience method
that simply returns the value of $config->{'err'}:

    $config->error();

=back

=head1 EXAMPLE

Using 10.0.1.3 as a TFTP server, the following example merges a
configuration file into the running-config of lab-router-a, and 
then copies the entire config of lab-router-a to a file:

    use Cisco::CopyConfig;

    $|		= 1; # autoflush output
    $tftp	= '10.0.1.3';
    $merge_f	= 'new-config.upload';
    $copy_f	= 'lab-router-a.config';
    $host	= 'lab-router-a';
    $comm	= 'public';
    $config	= Cisco::CopyConfig->new(
		     Host => $host,
		     Comm => $comm
    );
    $path	= "/tftpboot/${copy_f}"; 

    open(COPY_FH, "> $path") || die $!;
    close(COPY_FH); chmod 0666, $path || die $!;

    print "${tftp}:${merge_f} -> ${host}:running-config... ";
    if ($config->merge($tftp, $merge_f)) {  # merge the new config
      print "OK\n";
    } else {
      die $config->error();
    }
    print "${host}:running-config -> ${tftp}:${copy_f}... ";
    if ($config->copy($tftp, $copy_f)) {    # copy the updated config
      print "OK\n";
    } else {
      die $config->error();
    }

    ---->8---- new-config.upload file ---->8----
    alias exec example_ccout copy running-config tftp
    alias exec example_ccin copy tftp running-config
    ! configuration uploads need an 'end' statement
    end

=head1 TROUBLESHOOTING

Manipulating the running-configuration of a device running IOS can be a 
frustrating experience.  Checking the status of $config->error() is a good
starting point to debugging the problem.  Here's a short list of other things
to try before giving up:

=over 4

=item 1.

Most TFTP servers will not automatically create files. Scripts should 
create files that will be read from or copied to, and set the appropriate
permissions (usually global).  

=item 2.

Most TFTP servers change directories (usually to '/tftpboot') for security
reasons.  If it does, make sure not to prepend the TFTP directory in the 
file path passed to I<Cisco::CopyConfig>.

=item 3.

Try manually copying files to and from the TFTP server to flash.  This is 
accomplished via the "copy" command in IOS (copy ? for help).  If the files 
are able to be copied in each direction, it is probably a problem with the 
SNMP configuration.  It could also indicate a file path issue.  See above.

=item 4.

Make sure the community string in the script and the IOS device match
and that it is a read/write (RW) community.  See B<PREPERATION> above for 
an example of how to set a read/write community with reasonable restrictions.

=back

=head1 PREREQUISITES

This module requires the I<Net::SNMP> and I<Socket> modules.  

=head1 BUGS

Local file creation and permissions checking are not performed, as 
TFTP file destinations can be somewhere other than the local system.

Only SNMP v1 and v2 are currently supported in this module.  SNMP v3 
is on the TODO list.

=head1 AUTHORS

Aaron Scarisbrick <aaronsca@cpan.org>

=head1 DISCLAIMER

THIS SOFTWARE IS PROVIDED BY THE AUTHOR AND CONTRIBUTORS ``AS IS'' AND
ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
ARE DISCLAIMED.  IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE LIABLE
FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS
OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION)
HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT
LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY
OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF
SUCH DAMAGE.

=cut

### -- EOF
