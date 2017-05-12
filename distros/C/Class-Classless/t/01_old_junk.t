
# Time-stamp: "2004-12-29 20:12:14 AST"

use Test;
BEGIN { plan tests => 8; }

use Class::Classless 1.1;

ok 1;
print "# Perl v$], Class::Classless $Class::Classless::VERSION\n";


###########################################################################

#$Class::Classless::Debug = 2;

sub nodelist { join '.', map { "" . $_->{'NAME'} . ""} @_ }
my %nodes;
sub mknew {
  use strict;
  my($sym, @rest) = @_;
  die "Already seen $sym" if ($nodes{$sym} || 0);
  @rest = map { $nodes{$_} || die "$_ not seen" } @rest;

  my $prime = @rest ? shift(@rest) : $Class::Classless::ROOT;
  #print "Cloning $prime\n";
  my $x = $prime->polyclone(@rest);
  #print "Clone: $x\n";
  $x->{'NAME'} = uc($sym);
  $nodes{$sym} = $x;
}

my $root_list = nodelist( $Class::Classless::ROOT->ISA_TREE );
print "# root_list: $root_list\n";
ok $root_list, 'ROOT';

mknew('a');
mknew('b', 'a');
mknew('c', );
mknew('d', );
mknew('e', 'a', 'c' );
mknew('f', 'e');
mknew('h', 'b');
mknew('g', 'f');
mknew('i', 'd');
mknew('j', 'h', 'g', 'i');

###########################################################################

my $j_list = nodelist( $nodes{'j'}->ISA_TREE );
print "# j_list: $j_list\n";
ok $j_list, 'J.H.B.G.F.E.A.C.I.D.ROOT';

###########################################################################

my $x = 0;
$nodes{'b'}{'METHODS'}{'zaz'} = sub { $x = 1; return; };
$nodes{'j'}->zaz;
ok $x;

$nodes{'j'}{'METHODS'}{'const1'} = 'konwun';
$nodes{'h'}{'METHODS'}{'const2'} =
  do {my $x = 'kontoo'; bless \$x, '_deref_scalar'};
$nodes{'b'}{'METHODS'}{'const3'} =
  bless ['foo','bar','baz'], '_deref_array';
$nodes{'g'}{'METHODS'}{'const4'} = undef;


ok $nodes{'j'}->const1, 'konwun';

ok $nodes{'j'}->const2, 'kontoo';
ok join('~', $nodes{'j'}->const3), 'foo~bar~baz';

ok (not defined($nodes{'j'}->const4));



__END__

