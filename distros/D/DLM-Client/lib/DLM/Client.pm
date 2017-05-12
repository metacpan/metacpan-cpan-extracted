package DLM::Client;

use 5.008008;
use strict;
use warnings;
use Carp;

require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use DLM::Client ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	lock_resource
    unlock_resource
    DLM_LOCKSPACE_LEN
	DLM_LSFL_FS
	DLM_LSFL_NEWEXCL
	DLM_LSFL_NODIR
	DLM_LSFL_TIMEWARN
	DLM_LVB_LEN
	DLM_RESNAME_MAXLEN
	DLM_SBF_ALTMODE
	DLM_SBF_DEMOTED
	DLM_SBF_VALNOTVALID
	ECANCEL
	EINPROG
	EUNLOCK
	LKF_ALTCW
	LKF_ALTPR
	LKF_CANCEL
	LKF_CONVDEADLK
	LKF_CONVERT
	LKF_EXPEDITE
	LKF_FORCEUNLOCK
	LKF_HEADQUE
	LKF_IVVALBLK
	LKF_NODLCKBLK
	LKF_NODLCKWT
	LKF_NOORDER
	LKF_NOQUEUE
	LKF_NOQUEUEBAST
	LKF_ORPHAN
	LKF_PERSISTENT
	LKF_QUECVT
	LKF_TIMEOUT
	LKF_VALBLK
	LKF_WAIT
	LKM_CRMODE
	LKM_CWMODE
	LKM_EXMODE
	LKM_NLMODE
	LKM_PRMODE
	LKM_PWMODE
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );


our $VERSION = '0.02';

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&DLM::Client::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    
    {
	    no strict 'refs';
	    *$AUTOLOAD = sub { $val };
    }

    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('DLM::Client', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__

=head1 NAME

DLM::Client - Linux DLM(Distributed Lock Manager) Client

=head1 SYNOPSIS

    use DLM::Client qw/LKM_EXMODE/;
    my $lock_id = 0;

    if ( DLM::Client::lock_resource( 'LOCK_NAME', LKM_EXMODE, 0, $lock_id) == 0 ){
        print "Locked\n";
    }

    if ( DLM::Client::unlock_resource($lock_id) == 0 ) {
        print "Unlocked\n";
    }

=head1 DESCRIPTION

DLM::Client is a direct binding to linux distributed lock manager (DLM is part of the Linux kernel from version 2.6.19) from RedHat.

It is extremely fast and really distributed but you should configure DLM cluster before.

=head1 DLM OVERVIEW

The Distributed Lock Manager (DLM) provides advisory locking services that allow concurrent applications
running on multiple nodes in a Linux cluster to coordinate their use of shared resources. Cooperating
applications running on different nodes in a Linux cluster can share common resources without corrupting
those resources. The shared resources are not corrupted because the lock manager synchronizes (and if
necessary, serializes) access to them.

Note: All locks are advisory, that is, voluntary. The system does not enforce locking. Instead,
applications running on the cluster must cooperate for locking to work. An application that wants to
use a shared resource is responsible for first obtaining a lock on that resource before attempting to
access it.

Applications that can benefit from using the Distributed Lock Manager are transaction-oriented, such as a
database or a resource controller or manager.

The DLM provides its own mechanisms to support its locking features, such as inter-node communication to
manage lock traffic and recovery protocols to re-master locks after a node failure or to migrate locks when a
node joins the cluster. However, the DLM does not provide mechanisms to actually manage the cluster itself.

You can find aditional documentation on 

=over 4

=item * L<http://sourceware.org/cluster/dlm/>

=item * L<http://sources.redhat.com/cluster/wiki/>

=item * L<http://people.redhat.com/ccaulfie/docs/rhdlmbook.pdf>

=back

=head1  THE SIMPLE API

This provides two API calls, lock_resource() and unlock_resource(). Both of these calls block until the lock
operation has completed.

=head2 lock_resource($resource, $mode, $flags, $lockid)

      This function locks a named resource and inplace updates the $lockid if successful.
      mode may be any of:
      LKM_NLMODE LKM_CRMODE LKM_CWMODE LKM_PRMODE LKM_PWMODE LKM_EXMODE

=head3  flags 

    may be any combination of
    LKF_NOQUEUE            If the lock cannot be granted immediately, return EAGAIN rather than waiting.
    LKF_CONVERT            Convert lock to new mode. *lockid must be valid,resource name is ignored.
    LKF_QUECVT             Add conversion to the back of the convert queue - only valid for some convert operations
    LKF_PERSISTENT Don't automatically unlock this lock when the process exits (must be root).

=head3 Return codes:

    0 is returned if the call completed successfully. If not, -1 is returned and $! is set to one of the
    following:
    EINVAL                  An invalid parameter was passed to the call (eg bad lock mode or flag)
    ENOMEM                  A (kernel) memory allocation failed
    EAGAIN                  LKF_NOQUEUE was requested and the lock could not be granted
    EBUSY  The lock is currently being locked or converted
    EFAULT The userland buffer could not be read/written by the kernel (this indicates a library problem)

=head2 unlock_resource($lockid);

      Unlocks the resource.

=head3 Return codes:

      0 is returned if the call completed successfully. If not, -1 is returned and errno is set to one of the
      following:
      EINVAL                  An invalid parameter was passed to the call (eg bad lock mode or flag)
      EINPROGRESS             The lock is already being unlocked
      EBUSY                   The lock is currently being locked or converted

=head2 Example
     
      my $lockid;
      my $status = lock_resource("mylock", LKM_EXMODE, 0, $lockid);
      
      if ($status == 0) { 
          $status = unlock_resource($lockid)
      }


=head1 LOCKS

In the DLM locking model, you can request a lock from the lock manager on any lock resource. Locks have
the following properties:

=over 4

=item * A mode that defines the degree of protection provided by the lock

=item * A state that indicates whether the lock is currently granted, converting, or waiting

=back

=head2  Lock Modes


A lock mode indicates whether a process shares access to a lock resource with other processes or whether it
prevents other processes from accessing that lock resource while it holds the lock. A lock request specifies a
lock mode.

Note: The Distributed Lock Manager does not force a process to respect a lock. Processes must agree
to cooperate. They must voluntarily check for locks before accessing a resource and, if a lock
incompatible with a request exists, wait for that lock to be released or converted to a compatible mode.

=head2 Lock Mode Severity

The lock manager supports six lock modes that range in the severity of their restriction. The following table
lists the modes, in order from least severe to most severe, with the types of access associated with each mode.

                               Lock Modes
.--------------------------+----------------------+----------------------.
| Mode                     | Requesting Process   | Other Processes      |
+--------------------------+----------------------+----------------------+
| Null (NL)                | No access            | Read or write access |
| Concurrent Read (CR)     | Read access only     | Read or write access |
| Concurrent Write (CW)    | Read or write access | Read or write access |
| Protected Read (PR)      | Read access only     | Read access only     |
| Protected Write (PW)     | Read or write access | Read access only     |
| Exclusive (EX)           | Read or write access | No access            |
'--------------------------+----------------------+----------------------'

Within an application, you can determine which mode is more severe by making a simple arithmetic
comparison. Modes that are more severe are arithmetically greater than modes that are less severe.

=head2 Lock Mode Compatibility

Lock mode compatibility determines whether two locks can be granted simultaneously on a particular lock
resource. Because of their restriction, certain lock combinations are compatible and certain other lock
combinations are incompatible.
For example, because an EX lock does not allow any other user to access the lock resource, it is incompatible
with locks of any other mode (except NL locks, which do not grant the holder any privileges). Because a CR
lock is less restrictive, however, it is compatible with any other lock mode, except EX.
The following table presents a mode compatibility matrix.

                Lock Mode Compatibility
.------------+-----------------------------------.
| Requested- |      Currently Granted Lock       |
|   Lock     |                                   |
+------------+-----+-----+-----+-----+-----+-----+
| QQ         | NL  | CR  | CW  | PR  | PW  | EX  |
+------------+-----+-----+-----+-----+-----+-----+
| NL         | Yes | Yes | Yes | Yes | Yes | Yes |
| CR         | Yes | Yes | Yes | Yes | Yes | No  |
| CW         | Yes | Yes | Yes | No  | No  | No  |
| PR         | Yes | Yes | No  | Yes | No  | No  |
| PW         | Yes | Yes | No  | No  | No  | No  |
| EX         | Yes | No  | No  | No  | No  | No  |
'------------+-----+-----+-----+-----+-----+-----'



=head3 NL

NL mode locks grant no privileges to the lock holder. NL mode locks are compatible with locks of any other
mode. Applications typically use NL mode locks as place holders for later conversion requests.

=head3 CR

CR mode locks allow unprotected read operations. The read operations are unprotected because other
processes can read or write the lock resource while the holder of a CR lock is reading the lock resource. CR
mode locks are compatible with every other mode lock except EX mode.

=head3 CW

CW mode locks allow unprotected read and write operations. CW mode locks are compatible with NL mode
locks, CR read mode locks, and other CW mode locks.

=head3 PR 

PR mode locks allow a lock client to read from a lock resource knowing that no other process can write to the
lock resource while it holds the lock. PR mode locks are compatible with NL mode locks, CR mode locks,
and other PR mode locks. PR mode locks are an example of a traditional shared lock.

=head3 PW

PW mode locks allow a lock client to read or write to a lock resource, knowing that no other process can
write to the lock resource. PW mode locks are compatible with NL mode locks and CR mode locks. Other
processes that hold CR mode locks on the lock resource can read it while a lock client holds a PW lock on a
lock resource. A PW lock is an example of a traditional update lock.

=head3 EX

EX mode locks allow a lock client to read or write a lock resource without allowing access to any other mode
lock (except NL). An EX lock is an example of a traditional exclusive lock.
The following figure shows the modes in descending order from most to least severe. Note that, because CW
and PR modes are both compatible with three modes, they provide the same level of severity.


=head2 EXPORT

None by default.

=head2 Exportable constants

  DLM_LOCKSPACE_LEN
  DLM_LSFL_FS
  DLM_LSFL_NEWEXCL
  DLM_LSFL_NODIR
  DLM_LSFL_TIMEWARN
  DLM_LVB_LEN
  DLM_RESNAME_MAXLEN
  DLM_SBF_ALTMODE
  DLM_SBF_DEMOTED
  DLM_SBF_VALNOTVALID
  ECANCEL
  EINPROG
  EUNLOCK
  LKF_ALTCW
  LKF_ALTPR
  LKF_CANCEL
  LKF_CONVDEADLK
  LKF_CONVERT
  LKF_EXPEDITE
  LKF_FORCEUNLOCK
  LKF_HEADQUE
  LKF_IVVALBLK
  LKF_NODLCKBLK
  LKF_NODLCKWT
  LKF_NOORDER
  LKF_NOQUEUE
  LKF_NOQUEUEBAST
  LKF_ORPHAN
  LKF_PERSISTENT
  LKF_QUECVT
  LKF_TIMEOUT
  LKF_VALBLK
  LKF_WAIT
  LKM_CRMODE
  LKM_CWMODE
  LKM_EXMODE
  LKM_NLMODE
  LKM_PRMODE
  LKM_PWMODE

=head1 SEE ALSO

=over 4

=item * DLM::Lock::Simple

=item * L<http://sourceware.org/cluster/dlm/>

=item * L<http://sources.redhat.com/cluster/wiki/>

=item * L<http://people.redhat.com/ccaulfie/docs/rhdlmbook.pdf>

=back

=head1 TODO

Improve tests, add more examples to documentation.

Add bindings for:

=over 4

=item * dlm_lock_wait

=item * dlm_unlock_wait

=item * dlm_query_wait

=item * dlm_ls_lock_wait

=item * dlm_ls_unlock_wait

=item * dlm_ls_query_wait

=back

=head1 AUTHOR

Viktor Turskyi, E<lt>koorchik@E<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2010 by Viktor Turskyi

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.10.0 or,
at your option, any later version of Perl 5 you may have available.


=cut
