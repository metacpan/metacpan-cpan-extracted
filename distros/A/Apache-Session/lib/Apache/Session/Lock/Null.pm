############################################################################
#
# Apache::Session::Lock::Null
# Pretends to provide locking for Apache::Session
# Copyright(c) 1998, 1999, 2000 Jeffrey William Baker (jwbaker@acm.org)
# Distribute under the Perl License
#
############################################################################

package Apache::Session::Lock::Null;

use strict;
use vars qw($VERSION);

$VERSION = '1.01';

#This package is fake.  It fulfills the API that Apache::Session
#outlines but doesn't actually do anything, least of all provide
#serialized access to your data store.

sub new {
    my $class = shift;
    
    return bless {}, $class;
}

sub acquire_read_lock  {1}
sub acquire_write_lock {1}
sub release_read_lock  {1}
sub release_write_lock {1}
sub release_all_locks  {1}

1;


=pod

=head1 NAME

Apache::Session::Lock::Null - Does not actually provides mutual exclusion

=head1 SYNOPSIS

 use Apache::Session::Lock::Null;

 my $locker = new Apache::Session::Lock::Null;

 $locker->acquire_read_lock($ref);
 $locker->acquire_write_lock($ref);
 $locker->release_read_lock($ref);
 $locker->release_write_lock($ref);
 $locker->release_all_locks($ref);

=head1 DESCRIPTION

Apache::Session::Lock::Null fulfills the locking interface of 
Apache::Session, without actually doing any work.  This is the module to use
if you want maximum performance and don't actually need locking.

=head1 AUTHOR

This module was written by Jeffrey William Baker <jwbaker@acm.org>.

=head1 SEE ALSO

L<Apache::Session>
