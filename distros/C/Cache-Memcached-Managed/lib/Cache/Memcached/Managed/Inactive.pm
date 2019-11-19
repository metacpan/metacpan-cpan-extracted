package Cache::Memcached::Managed::Inactive;

# Make sure we have version info for this module

$VERSION= '0.26';

#--------------------------------------------------------------------------
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

# Singleton object

my $self;

# At compile time
#  Create accessors returning undef

BEGIN {
    *$_ = sub { undef } foreach qw(
 add
 data
 decr
 delete
 delete_group
 delimiter
 directory
 expiration
 flush_all
 flush_interval
 get
 incr
 namespace
 replace
 reset
 set
 start
 stop
    );

#  Create accessors returning hash ref

    *$_ = sub { {} } foreach qw(
 errors
 get_group
 get_multi
 grab_group
 group
 stats
 version
    );

#  Create accessors returning list or hash ref

    *$_ = sub { wantarray ? () : {} } foreach qw(
 dead
 group_names
 servers
    );
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
#      2..N hash with parameters
# OUT: 1 instantiated object

sub new { $self ||= bless {},shift } #new

#---------------------------------------------------------------------------
#
# Object methods
#
#---------------------------------------------------------------------------
# inactive
#
#  IN: 1 instantiated object
# OUT: 1 true

sub inactive { 1 } #inactive

#---------------------------------------------------------------------------

__END__

=head1 NAME

Cache::Memcached::Managed::Inactive - inactive Cache::Memcache::Managed object

=head1 SYNOPSIS

 use Cache::Memcached::Managed::Inactive;

 my $cache = Cache::Memcached::Managed::Inactive->new;

=head1 DESCRIPTION

Provides the same API as L<Cache::Memcached::Managed>, but doesn't do anything.

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
