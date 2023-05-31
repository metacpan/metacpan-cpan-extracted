
use strict;
use warnings;


use Array::Unique 0.04;

print "----------------------------------\n";
my @a;
my $o;

#$o = tie @a, "Array::Unique";
$o = tie @a, "Array::Unique", 'Std';
#$o = tie @a, "Array::Unique", 'Quick';
#$o = tie @a, "Array::Unique", 'IxHash';
#require Devel::TraceMethods;
#import Devel::TraceMethods qw(Array::Unique Array::Unique::IxHash);
#import Devel::TraceMethods qw(Array::Unique Array::Unique::Std);
#print $o;
die "Could not initialize" unless (defined $o);
# ---------------------------------------------------
# create an array where there were dupplicates
# ---------------------------------------------------
@a=();
@a=qw(a b a);
#@a=qw(x y z q p r s t w);
print "@a\n";
#my @b = splice(@a, -5, 2, qw(z a x));
#my @b = splice(@a, 4, 2, qw(z a x));
#print "@b\n";
#print "@a\n";
#print $a[1], "\n";
#print $a[-1], "\n";
#print 'top index: ', $#a, "\n";
#print 'count: ', scalar @a, "\n";
#print 'content: ', @a, "\n";
#print 'content: ', @a, "\n";
#print $a[1],"\n";

#$#a=0;
#print "@a\n";

#print "$a[0]\n";
#print "$a[1]\n";

#@a=qw(a b c a d a b q a);
#ok("@a" eq "a b c d q");
#print "DEBUG: '@a'\n";

#print "z: ", $o->exists('z'), "\n";
#print "b: ", $o->exists('b'), "\n";


#@a[7, 15, 28] = qw(p q r);
#print "xDEBUG: '@a'\n";

__END__
use lib qw(blib/lib);
use Array::Unique;

my @a;
my $o = tie @a, "Array::Unique";


@a = qw(a c d o p a);

foreach my $v (@a) {
    print $v;
}


__END__



@a = qw(b c d);
$a[7]='z';
#$a[3]=x;
#undef $a[3];
print "@a\n";
print exists $a[2], "2\n";
print defined $a[2], "2\n";
print exists $a[3], "3\n";
print defined $a[3], "3\n";
print "@a\n";



