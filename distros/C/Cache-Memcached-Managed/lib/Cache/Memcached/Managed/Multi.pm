package Cache::Memcached::Managed::Multi;

# Make sure we have version info for this module

$VERSION= '0.25';

BEGIN { # We're fooling the Kwalitee checker into thinking we're strict
use strict;
}

#--------------------------------------------------------------------------
# No, we're NOT using strict here.  There are several reasons, the most
# important is that we're doing a lot of nasty stuff here.
# If you _do_ want stricture as a developer of this module, simply activate
# the line below here
#--------------------------------------------------------------------------
#use strict;

# At compile time
#  Create list with method names

BEGIN {
    my @method = qw(
 add
 data
 dead
 decr
 delete
 delete_group
 delimiter
 directory
 errors
 expiration
 flush_all
 flush_interval
 get
 get_group
 get_multi
 grab_group
 group
 group_names
 inactive
 incr
 namespace
 replace
 reset
 servers
 set
 start
 stats
 stop
 version
    );

#  Create a method for each of the methods which
#   Obtains the list of objects
#   If called in list context
#    Call the methods in list context and return list of list refs
#   Elseif called in scalar context
#    Call the methods in scalar context and return list ref of values
#   Call the methods in void context

    eval <<SUB foreach @method;
sub $_ {
    my \$objects = shift;
    if (wantarray) {
        return map { [\$_->$_( \@_ )] } \@{\$objects};
    } elsif (defined wantarray) {
        return [map { scalar \$_->$_( \@_ ) } \@{\$objects}];
    }
    \$_->$_( \@_ ) foreach \@{\$objects};
} #$_
SUB
} #BEGIN

# Satisfy -require-

1;

#---------------------------------------------------------------------------
#
# Class methods
#
#---------------------------------------------------------------------------
# new
#
# Return instantiated object
#
#  IN: 1 class
#      2..N list of Cache::Memcached::Managed (compatible) objects
# OUT: 1 instantiated object

sub new { my $class = shift; bless \@_,$class } #new

#---------------------------------------------------------------------------
#
# Object methods
#
#---------------------------------------------------------------------------
# objects
#
#  IN: 1 instantiated object
# OUT: 1..N objects of which this object consists

sub objects { @{$_[0]} } #objects

#---------------------------------------------------------------------------

__END__

=head1 NAME

Cache::Memcached::Managed::Multi - multiple Cache::Memcache::Managed objects

=head1 SYNOPSIS

 use Cache::Memcached::Managed::Multi;

 my $multi = Cache::Memcached::Managed::Multi->new( @managed );

=head1 DESCRIPTION

Provides the same API as L<Cache::Memcached::Managed>, but applies all methods
called to all of the objects specified, except for L<new> and L<objects>.

=head1 CONTEXT

All methods are called on all of the L<Cache::Memcached::Managed> objects
in the same context (list, scalar or void) in which the method is called on
the L<Cache::Memcached::Managed::Multi> object.  The return value differs in
format depending on the context also:

=over 2

=item scalar

 my $listref = $multi->method;
 print "Result: @{$listref}\n";

When called in scalar context, a list ref with scalar values is returned in
the same order in which the objects are used (which is determined by the
order in which they were supplied with L<new> and returned by L<objects>..

=item list

 my @listref = $multi->method;
 print "Result $_: @{$listref[$_]}\n" foreach 0..$#listref;

When called in list context, a list of list references is returned in
the same order in which the objects are used (which is determined by the
order in which they were supplied with L<new> and returned by L<objects>.

=item void

 $multi->method;

When called in void context, nothing is returned (not strangely enough ;-).

=back

=head1 SPECIFIC CLASS METHODS

There is only one specific class method.

=head2 new

 my $multi = Cache::Memcached::Managed::Multi->new( @managed );

Create an object containing multiple L<Cache::Memcached::Managed> objects.
Returns the instantiated object.

=head1 SPECIFIC INSTANCE METHODS

=head2 objects

 my @managed = $multi->objects;

Returns the list of instantiated L<Cache::Memcached::Managed> objects that
the object is a proxy for.

=head1 AUTHOR

 Elizabeth Mattijsen

=head1 COPYRIGHT

(C) 2005 - 2006 BOOKINGS
(C) 2007 BOOKING.COM

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation; either version 2 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.

=cut
