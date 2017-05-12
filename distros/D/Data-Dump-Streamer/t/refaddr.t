use Data::Dump::Streamer qw(refaddr);
use vars qw($t $y $x *F $v $r);
use Symbol qw(gensym);

#$Id: refaddr.t 26 2006-04-16 15:18:52Z demerphq $#

# Ensure we do not trigger and tied methods
tie *F, 'MyTie';

print "1..13\n";

my $i = 1;
foreach $v (undef, 10, 'string') {
  print "not " if refaddr($v);
  print "ok ",$i++,"\n";
}

foreach $r ({}, \$t, [], \*F, sub {}) {
  my $addr = $r + 0;
  print "not " unless refaddr($r) == $addr;
  print "ok ",$i++,"\n";
  my $obj = bless $r, 'FooBar';
  print "not " unless refaddr($r) == $addr;
  print "ok ",$i++,"\n";
}

package FooBar;

use overload  '0+' => sub { 10 },
		'+' => sub { 10 + $_[1] };

package MyTie;

sub TIEHANDLE { bless {} }
sub DESTROY {}

sub AUTOLOAD {
  warn "$AUTOLOAD called";
  exit 1; # May be in an eval
}
