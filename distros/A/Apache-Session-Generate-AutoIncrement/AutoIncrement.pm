#############################################################################
#
# Apache::Session::Generate::AutoIncrement;
# Generates session identifier tokens using a monotonically increasing number
# The current number is stored in a file.
# Copyright(c) 2001 Pascal Fleury (fleury@users.sourceforge.net)
# Distribute under the same terms as Perl itself.
#
############################################################################

package Apache::Session::Generate::AutoIncrement;

use strict;
use vars qw($VERSION);
use File::CounterFile;

$VERSION = "0.9";

our $DEFAULT_LENGTH = 10;

sub generate {
    my $session = shift;
	 
	 if (! exists $session->{args}->{CounterFile}) {
		require Carp;
		Carp::croak "You need to specify a 'CounterFile' argument to the session.";
	 }
	 my $initcount = $session->{args}->{CounterInitial};
	 my $syncfile = new File::CounterFile($session->{args}->{CounterFile}, $initcount);
	 my $count = $syncfile->inc();
	 
    my $length = $DEFAULT_LENGTH;
    if (exists $session->{args}->{IDLength}) {
        $length = $session->{args}->{IDLength};
    }
    
	 my $cntstr = '0' x $length . "$count";
    $session->{data}->{_session_id} = substr($cntstr, length($cntstr)-$length);
    

}

sub validate {
    #This routine checks to ensure that the session ID is in the form
    #we expect.  This must be called before we start diddling around
    #in the database or the disk.

    my $session = shift;
    # Check content
    if ($session->{data}->{_session_id} !~ /^[0-9]+$/) {
        die;
    }
	 #check length
    my $length = $DEFAULT_LENGTH;
    if (exists $session->{args}->{IDLength}) {
        $length = $session->{args}->{IDLength};
    }
	 if ( length($session->{data}->{_session_id})!=$length ) {
		die;
	 }
	 1; # This is for the test routines
}

1;

=pod

=head1 NAME

Apache::Session::Generate::AutoIncrement - Use monotonically increasing IDs

=head1 SYNOPSIS

 use Apache::Session::Generate::AutoIncrement;
 
 $id = Apache::Session::Generate::AutoIncrement::generate();

=head1 DESCRIPTION

This module fulfills the ID generation interface of Apache::Session.  The
IDs are generated using a monotonically increasing counter value. This
counter is file-based using the File::Counter module, so it is probably
not very efficient and fast.

This module can also examine session IDs to ensure that they are, indeed,
session ID numbers and not evil attacks.  The reader is encouraged to
consider the effect of bogus session ID numbers in a system which uses
these ID numbers to access disks and databases.

This modules takes two arguments in the usual Apache::Session style.
The first argument is IDLength, and the value, between 0 and 32, tells
this modulevwhere to truncate the session ID.  Without this argument,
the session ID will be 10 digits.
The second argument is CounterFile, which is the file in which the
counted value will reside. This parameter is given directly to the
File::Counter module.

=head1 BUGS

This module relies on File::CounterFile, so the same limitations
as that module do apply here (about locking the file).

=head1 AUTHOR

This module was written by Pascal Fleury <fleury@users.sourceforge.net>
but heavily based on Jeffrey William Baker's module.

=head1 COPYRIGHT

Copyright(c) 2001-2002 by Pascal Fleury (fleury@users.sourceforge.net)
Distribute under the same terms as Perl itself.


=head1 SEE ALSO

L<Apache::Session>, L<File::CounterFile>
