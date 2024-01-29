package Apache::Session::Lock::MariaDB;

use strict;
use warnings;

use base 'Apache::Session::Lock::MySQL';

1;

=pod

=head1 NAME

Apache::Session::Lock::MariaDB - Provides mutual exclusion using MariaDB

=head1 SYNOPSIS

 use Apache::Session::Lock::MariaDB;

 my $locker = Apache::Session::Lock::MariaDB->new();

 $locker->acquire_read_lock($ref);
 $locker->acquire_write_lock($ref);
 $locker->release_read_lock($ref);
 $locker->release_write_lock($ref);
 $locker->release_all_locks($ref);

=head1 DESCRIPTION

This is based on L<Apache::Session::Lock::MySQL> but for
L<Apache::Session::MariaDB>.

=head1 AUTHOR

Best Practical Solutions, LLC E<lt>modules@bestpractical.comE<gt>

=head1 SEE ALSO

L<Apache::Session::Lock::MySQL>, L<Apache::Session>
