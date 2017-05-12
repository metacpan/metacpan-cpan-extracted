
package DateTimeX::Lite::TimeZone::UTC;

use strict;

use DateTimeX::Lite::TimeZone;
use base 'DateTimeX::Lite::TimeZone';

sub new
{
    my $class = shift;

    return bless { name => 'UTC' }, $class;
}

sub is_dst_for_datetime { 0 }

sub offset_for_datetime { 0 }
sub offset_for_local_datetime { 0 }

sub short_name_for_datetime { 'UTC' }

sub category { undef }

sub is_utc { 1 }


1;

__END__

=head1 NAME

DateTimeX::Lite::TimeZone::UTC - The UTC time zone

=head1 SYNOPSIS

  my $utc_tz = DateTimeX::Lite::TimeZone::UTC->new;

=head1 DESCRIPTION

This class is used to provide the DateTimeX::Lite::TimeZone API needed by
DateTime.pm for the UTC time zone, which is not explicitly included in
the Olson time zone database.

The offset for this object will always be zero.

=head1 USAGE

This class has the same methods as a real time zone object, but the
C<category()> method returns undef and C<is_utc()> returns true.

=head1 AUTHOR

Dave Rolsky, <autarch@urth.org>

=head1 COPYRIGHT & LICENSE

Copyright (c) 2003-2008 David Rolsky.  All rights reserved.  This
program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

The full text of the license can be found in the LICENSE file included
with this module.

=cut