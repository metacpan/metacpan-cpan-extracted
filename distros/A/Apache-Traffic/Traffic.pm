package Apache::Traffic;

require 5.004;

use constant USE_DBM  => 1;

use constant SHMKEY   => 'hits';
use constant SEMKEY   => 1971;
use constant DBPATH   => '/tmp/traffic';
use constant MODE     => 0644;
use constant ONEDAY   => 60 * 60 * 24;

use strict;
use vars qw( $VERSION @ISA @EXPORT @EXPORT_OK %ROOTCACHE %OWNERCACHE 
             $TODAY $TOMORROW %STATS $KNOT $ERRMSG $SEMID );
use Time::Local;
use IPC::SysV qw( IPC_CREAT SEM_UNDO );
use IPC::Shareable;
use DB_File;
use Storable qw( freeze thaw );
use Apache::Constants qw( :common );

require Exporter;
require AutoLoader;

@ISA = qw(Exporter AutoLoader);
@EXPORT = qw();
@EXPORT_OK = qw( fetch remove error );

$VERSION = sprintf("%d.%02d", q$Revision: 1.2 $ =~ /(\d+)\.(\d+)/o);

# $IPC::Shareable::Debug = 1;

sub logger {
  my $r = shift;
  my($bytes, $uid, $server, $ref);

  ($bytes = $r->bytes_sent) || return OK;
  if ($uid = $r->dir_config('Owner')) { # WHO OWNS THIS DIRECTORY?
    unless ($uid =~ /^\d+$/) { 
      $OWNERCACHE{$uid} = (getpwnam $uid)[2] || $uid
        unless (defined $OWNERCACHE{$uid});
      $uid = $OWNERCACHE{$uid};
    }
  } else {
    $server = $r->server;
    if ($server->is_virtual) { # WHO OWNS THIS VIRTUAL SERVER?
      unless (defined($uid = $ROOTCACHE{ $r->document_root })) {
        $uid = $ROOTCACHE{ $r->document_root } = (stat $r->document_root)[4]; 
      }
    } else { # WHO OWNS THIS FILE? 
      $uid = (stat $r->filename)[4];
    }
  }
  (defined $uid) or ($uid = '-');
  unless (defined $SEMID) {
    unless (defined($SEMID = semget(SEMKEY, 1, MODE | IPC_CREAT))) {
      error("unable to obtain semaphore for locking: $!");
      return DECLINED;
    }
  }
  unless (semop($SEMID, pack "s*", 0, 0, 0, 0, 1, SEM_UNDO)) {
    error("unable to obtain lock: $!");
    return DECLINED;
  }
  unless (defined $KNOT) { # THE TIE IS PERSISTENT
    unless ($KNOT = tie(%STATS, 'IPC::Shareable', SHMKEY, 
                        { create => 1, mode => MODE })) {
      error("unable to tie to shared memory: $!");
      return DECLINED;
    }
  }
  if (time >= $TOMORROW) { 
    $TODAY = timegm(0, 0, 0, (localtime)[3..5]); # START OF TODAY
    $TOMORROW = $TODAY + ONEDAY;
    # SEE THE "Thingy Referenced Is Initially True" SECTION OF
    # IPC::Shareable.  WE DO THIS TO MINIMIZE THE NUMBER OF SHARED
    # MEMORY SEGMENTS USED. 
    unless (exists $STATS{$TODAY}) {
      $STATS{$TODAY} = { $uid => { hits => 0, bytes => 0 }};
    } 
    # MOVE DATA FROM SHARED MEMORY INTO DBM FILE IF > 1 DAY INFO
    if ((keys %STATS > 1) and (USE_DBM)) { 
      unless (_move_shm_to_dbm($r)) {
        unless (semop($SEMID, pack "s*", 0, -1, SEM_UNDO)) {
          error("unable to release lock: $!");
        }
        return DECLINED;
      }
    }
  }
  $ref = $STATS{$TODAY};
  $$ref{$uid}{hits} += 1;
  $$ref{$uid}{bytes} += $bytes;
  $STATS{$TODAY} = $ref;
  unless (semop($SEMID, pack "s*", 0, -1, SEM_UNDO)) {
    error("unable to release lock: $!");
    return DECLINED;
  }
  OK; 
}

sub handler { shift->post_connection(\&logger) }

1;

__END__

sub error {
  my($error, $package, $line, $r);

  if (@_) {
    ($package, $line) = (caller)[0,2];
    $ERRMSG = join('', "$package [$line]: ", @_);
    eval { $r = Apache->request };
    unless ($@) {
      $r->log_error($ERRMSG);
    }
    return undef;
  } else {
    return $ERRMSG;
  }
}

sub fetch {
  my($start, $end, $wantuid, $all, @users) = @_;
  my(%hash, %uids, $uid, $db_obj, %db, $ref);

  $start = timegm(0, 0, 0, (localtime($start))[3..5]); # START OF DAY
  $end   = timegm(0, 0, 0, (localtime($end))[3..5]);
  tie(%STATS, 'IPC::Shareable', SHMKEY, { create => 'no' })
    or return error("unable to tie to shared memory: $!");
  if (-e DBPATH) { # DBM FILE WON'T EXIST UNTIL HANDLER HAS RUN FOR > 1 DAY
    $db_obj = tie %db, 'DB_File', DBPATH, O_RDONLY, MODE
      or return error("unable to open dbm file: $!");
  }
  @users = () if ($all);
  foreach(@users) {
    # LOOKUP THE USERNAME IF WE WERE PASSED A UID
    $_ = (getpwuid $_)[0] || $_ if ($_ =~ /^\d+$/);
    # LOOKUP THE UID
    (defined($uid = (getpwnam $_)[2])) || ($uid = $_);
    # STORE THE USERNAME INDEXED BY UID (unless $wantuid is true)
    $uids{$uid} = ($wantuid ? $uid : $_);
  }
  while($start <= $end) {
    unless ($all) {
      foreach(keys %uids) { # MAKE SURE WE RETURN VALUES FOR EVERY USER
        $hash{$start}{ $uids{$_} } = { bytes => 0, hits => 0 };
      }
    }
    if (exists $STATS{$start}) {
      $ref = $STATS{$start};
    } elsif ((defined $db_obj) and (exists $db{$start})) {
      $ref = thaw($db{$start});
    } else {
      $start += ONEDAY;
      next;
    }
    if ($all) {
      foreach(keys %$ref) {
        unless (defined $uids{$_}) {
          $uids{$_} = $_;
          if ((/^\d+$/) and (! $wantuid)) {
            $uids{$_} = (getpwuid $_)[0] || $_;
          }
        }
      }
    } 
    foreach(keys %uids) {
      next unless (exists $ref->{$_});
      $hash{$start}{ $uids{$_} }{bytes} = $ref->{$_}{bytes};
      $hash{$start}{ $uids{$_} }{hits}  = $ref->{$_}{hits};
    }
    $start += ONEDAY;
  }
  return \%hash;
}

sub remove {
  my($start, $end) = @_;
  my(%db, $db_obj);

  $start = timegm(0, 0, 0, (localtime($start))[3..5]); # START OF DAY
  $end   = timegm(0, 0, 0, (localtime($end))[3..5]);
  tie(%STATS, 'IPC::Shareable', SHMKEY, { create => 'no' })
    or return error("unable to tie to shared memory");
  if (-e DBPATH) {
    $db_obj = tie %db, 'DB_File', DBPATH, O_RDWR, MODE
      or return error("unable to tie dbm file: $!");
  }
  (defined($SEMID = semget(SEMKEY, 1, MODE))) 
    or return error("unable to obtain semaphore for locking: $!");
  semop($SEMID, pack "s*", 0, 0, 0, 0, 1, SEM_UNDO)
    or return error("unable to obtain lock: $!");
  while($start <= $end) {
    delete $STATS{$start};
    delete $db{$start} if (defined $db_obj);
    $start += ONEDAY;
  }
  $db_obj->sync if (defined $db_obj);
  semop($SEMID, pack "s*", 0, -1, SEM_UNDO)
    or return error("unable to release lock: $!");
  1;
}

# MOVE ALL DATA IN SHARED MEMORY INTO DBM FILE, _EXCEPT_ FOR CURRENT DAY
sub _move_shm_to_dbm {
  my $r = shift;
  my(%db);

  tie %db, 'DB_File', DBPATH, O_CREAT | O_RDWR, MODE
    or return error("unable to tie dbm file: $!");
  foreach (keys %STATS) {
    next if ($_ == $TODAY);
    $db{$_} = freeze($STATS{$_})
      or return error("error writing dbm: $!");
    delete $STATS{$_};
  }
  untie %db;
  1;
}

=head1 NAME

Apache::Traffic - Tracks hits and bytes transferred on a per-user basis 

=head1 SYNOPSIS

  # Place this in your Apache's httpd.conf file
  PerlLogHandler Apache::Traffic

=head1 DESCRIPTION

This module tracks the total number of hits and bytes transferred per
day by the Apache web server, on a per-user basis.  This allows for
real-time statistics without having to parse the log files.

After installation, add this to your Apache's httpd.conf file and restart 
the server:

	PerlLogHandler	Apache::Traffic

The statistics are then available through the 'traffic' script,
which is included in this distribution.  See the section VIEWING
STATISTICS for more details.

=head1 PREREQUISITES

You need to have compiled mod_perl with the LogHandler hook in order
to use this module. Additionally, the following modules are required:

	o IPC::Shareable
	o IPC::SysV
	o DB_File
	o Date::Parse 

Your OS must also support SysV IPC (shared memory and semaphores).
If this is not the case, this module will be useless to you.

=head1 INSTALLATION

To install this module, move into the directory where this file is
located and type the following:

        perl Makefile.PL
        make
        make test
        make install

This will install the module into the Perl library directory. 

Once installed, you will need to modify your web server's configuration
file so it knows to use Apache::Traffic during the logging phase:

	PerlLogHandler Apache::Traffic

Restart your web server.

As of this writing, there is a problem with IPC::Shareable 
which will cause segmentation faults in httpd processes if
Apache::Traffic is run long enough (at least this is the case
under Linux).  This distribution contains a patch named 'share.patch',
which will fix the problem. 
 
If Apache::Traffic does not appear to work correctly (look in your
server's error_log for problems), make sure the semaphore and shared
memory segments are not already allocated for another purpose.
If this is the case, you can change the constants SHMKEY, SEMKEY, and
DBPATH at the top of the Apache::Traffic module, and reinstall.

=head1 HOW IT WORKS

Each time a request is served, the Apache::Traffic log handler
is called which increments the byte and hit totals for the owner
of the resource.

The owner of the resource is determined in the following way:

  o If the Perl variable Owner has been set for the directory, its
    value is used.  For example:

	<Directory /home/root/www/mark>
	  PerlSetVar Owner mark
	</Directory>

    This would declare user mark as the owner of everything under
    the specified directory.  The value can be either the username
    or UID of the user.

    This value can also be a fake user (i.e. a username which is
    not present in the passwd file).  In this case, the username is
    stored (rather than the UID).

  o If the request is to a virtual host, the owner of the document
    root is used.

  o If neither of the above methods work, the owner of the file
    is used.

The hit and byte total information is stored in shared memory to
minimize processing.  On the first request of each day, all
previous data in shared memory is automatically moved to permanent 
storage.  This means that no more than one day's worth of information
is ever stored in shared memory, and prevents performance degradation
as data accumulates.  This separation of data is transparent from
the end-user perspective.

If you would rather not have the data moved into the dbm file, you
can set USE_DBM to 0 at the top of the Traffic.pm module and reinstall.

Shared memory segments are not preserved through reboots.  If you
reboot your machine multiple times a day, Apache::Traffic will be
of questionable value to you.  I run Linux, so of course, I only
reboot when I've upgraded the OS. ;-)  This area may be improved
in the future (at least for orderly shutdowns).

=head1 VIEWING STATISTICS

A script named 'traffic' is included in this distribution, which allows
you to view the totals for a given user.  Note that this script will
not run properly until Apache::Traffic has recorded at least
one page request.

The basic syntax for the script is:

	traffic [options] [username]

If username is not specified, the effective UID of the person running the
script is used.  By default, only data for the current day is displayed.

The following options are supported:

  -start=starting_date

	Specifies the starting date that you wish to see data for.  The
	date specifications can take any format supported by the 
        Date::Parse module.  If -end is not specified, all data between
        -start and the current day is displayed.

  -end=ending_date

	Specifies the ending date that you wish to see data for.  

  -days=num_days

	Specifies the number of days you want to see information for
        relative to the value of -start (or the current day if -start
        is not specified).  The value can be either positive
        or negative.

  -user=username

	Specifies the user you want to see data for.  Multiple
        -user specifications are allowed.  The users can also be
        specified as non-option arguments.  Both UIDs and usernames
        are allowed.

  -all

	Displays all data present within the given time period.
  
  -reverse

	If present, the information is sorted in descending order based
	on date.  

  -units=unit

	Specifies the unit to display transfer totals in.  Acceptable 
        values are 'Bytes', "Kilobytes', 'Megabytes', or 'Gigabytes'.
        Only the first character of the unit need be specified.  The
        default is Bytes.

  -summary

	If -summary is present, aggregate totals for the period 
        being viewed are displayed, rather than daily totals.

  -n

	If the -n option is present, the report displays UIDs rather than
	converting them to usernames.  In the case of a "fake" user,
        the username will still be displayed (which is a way to tell
        is a user is fake or not).

  -remove

	If the -remove option is present, all data within the specified  
        time period is permanently removed.  Only root is allowed to
	perform this operation (see the SECURITY NOTES section though).  
        The operation must be confirmed prior to being carried out.

=head1 ACCESSING INFORMATION DIRECTLY

If the supplied traffic script is not sufficient for your needs, you
may access the raw data directly.  The following functions are available
for import into your scripts.

  fetch([START], [END], [WANTUID], [ALL], [USER LIST])

	This function retrieves all data between START and END times,
        inclusive, for the users specified in USER LIST. Both START and
        END should be UTC timestamps.  The function automatically
        normalizes the timestamps to be on day boundaries.

	If WANTUID is true, usernames are not looked up.  If ALL is true,
        data for all users is returned and USER_LIST is ignored.  
        If ALL is true, data for all users is returned and
        USER_LIST is ignored. 

	On success, the function returns a complex hash reference, which 
        contains the requested data:

		use Apache::Traffic qw( fetch remove error );

		$ref = fetch(time, time, 0, 0, 'maurice');
		foreach $day (%$ref) {
		  foreach $user (%{ $ref->{$day} }) {
                    print scalar gmtime $day, " $user\n";
                    print "  BYTES: $ref->{$day}{$user}{bytes}\n";
                    print "   HITS: $ref->{$day}{$user}{hits}\n\n";
                  }
		}

	Note that the timestamps are stored internally in GM time, 
        although START and END should be in local time.  We do this
        so we don't have to worry about daylight savings.

	The function returns undef on error, in which case you can call
	the error() function to determine what went wrong.

  remove([START], [END])

        This function removes all data between the START and END times,
        inclusive.

        The fuction returns true on success and undef on error, in which
        case you can call the error() function to determine what went
        wrong.

  error()

	Returns a string describing the last error condition encountered.

=head1 SECURITY NOTES

By default, the shared memory segments, semaphores, and DBM file are created
with permissions of 0644.  However, these resources must be owned by
whatever user the server runs as (normally user 'nobody').  This means
that your users could create CGI scripts to play with the data.  For this
reason, the information maintained by Apache::Traffic should not be relied
upon for auditing purposes, and is intended mainly for use in friendly 
environments.

=head1 AUTHOR

Copyright (C) 1997, Maurice Aubrey <maurice@hevanet.com>. All rights reserved.

This module is free software; you may redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

perl(1), mod_perl(3)

=cut
