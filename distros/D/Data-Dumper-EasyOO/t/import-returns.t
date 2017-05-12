#!perl

use strict;
use Test::More (tests => 3);

=head1 test Abstract

tests return vals of import into scalar and list contexts.

=cut

use Data::Dumper::EasyOO (alias => 'EzDD');

my ($r1, $r2);
($r1,$r2) = EzDD->import(indent=>1);

is ($r1, 1, "list context returns 1 in 1st arg");
is (ref $r2, 'HASH', "list context import returns hashref in 2nd arg");

$r1 = EzDD->import(indent=>1, autoprint=>1);
is (ref $r1, 'HASH', "scalar context import returns hashref in 1st arg");
# ezdump ($r1);

__END__

