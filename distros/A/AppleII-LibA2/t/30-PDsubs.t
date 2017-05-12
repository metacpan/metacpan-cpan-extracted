# Before `./Build install' is performed this script should be runnable with
# `./Build test'. After `./Build install' it should work as `perl 30_subs.t'
#---------------------------------------------------------------------
# 30_PDsubs.t
# Copyright 2006 Christopher J. Madsen
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See either the
# GNU General Public License or the Artistic License for more details.
#
# Test subroutines in the AppleII::ProDOS module
#---------------------------------------------------------------------

use strict;
use Test::More tests => 5;
BEGIN { use_ok('AppleII::ProDOS', qw(pack_date unpack_date)) }

# For dumping raw dates:
sub ds { my $x = unpack('H*', $_[0]); $x =~ s/(..)/\\x$1/g; print qq'"$x"\n' }

#=====================================================================
my @date = (2005, 12, 31, 0, 0);

my $d = pack_date(@date);

is($d, "\x9f\x0b\x00\x00", 'packed 2005-12-31 12am');

is_deeply(\@date, [unpack_date $d], "2005-12-31 12am round-trip");

#---------------------------------------------------------------------
@date = (2004, 2, 29, 14, 37);

$d = pack_date(@date);

is($d, "\x5d\x08\x25\x0e", 'packed 2004-02-29 14:37');

is_deeply(\@date, [unpack_date $d], "2004-02-29 14:37 round-trip");

#---------------------------------------------------------------------
# Local Variables:
# mode: perl
# End:
