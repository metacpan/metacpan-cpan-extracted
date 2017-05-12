#!/usr/bin/perl

use ArrayHashMonster;
# Hi.  What am I for?
# I provide a reference that looks like a reference to an array and
# like a reference to a hash at the same time.
# If $z is an ArrayHashMonster object, then you can ask for either of
# $z->{foo} or $z->[7].  
#
# Some sample demonstration uses follow.

# Tests start here.
print "\n\nTest set 1:\n";
my $x = new ArrayHashMonster sub {"Array $_[0]"}, sub {"Hash $_[0]"};
print $x->[2], "\n";
print $x->{jan}, "\n";
print $x->{February}, "\n";
print $x->[4], "\n";

################################################################

print "\n\nTest set 2:\n";
my @fmo = qw(xx 
             janvier f<E9>vrier mars avril 
             mai juin juillet ao<FB>t 
             septembre octobre novembre d<E9>cembre);

my @emo = qw(xx
             January February March April
             May June July August
             September October November December);

my %e2f;

for ($i = 1; $i <= 12; $i++) {
  my $abbr = substr($emo[$i], 0, 3);
  $e2f{lc $emo[$i]} = $e2f{lc $abbr} = $fmo[$i];
}
my $y = new ArrayHashMonster sub {$fmo[$_[0]]}, sub {$e2f{lc $_[0]}};
print $y->[2], "\n";
print $y->{jan}, "\n";
print $y->{February}, "\n";
print $y->[4], "\n";


################################################################

print "\n\nTest set 3:\n";
opendir T, '.' or exit 0;
my $start = telldir T;
sub fileinfo { my $file = shift; 
	       my @stat = stat $file;
	       $stat[2] = sprintf "%o", $stat[2];
	       $stat[2] =~ s/^4/ d/;
	       $stat[2] =~ s/^10/ f/;
	       $stat[2] =~ s/(\w)0/$1 /;
	       sprintf "File %-32s Size %8d Owner %6d Mode %6s\n", 
	       $file, @stat[7,4,2];
	     }
sub filenumber { my $index = shift;
		 seekdir T, $start;
		 my $i = 1;
		 while ($i++ < $index) {
		   readdir T;
		 }
		 return readdir T;
	       }

my $z = new ArrayHashMonster \&filenumber, \&fileinfo or die;
my $n = 1;
for (;;) {
  my $filename = $z->[$n];
  last unless defined $filename;
  print $z->{$filename};
  $n++;
}
