use FindBin ();
use strict;
use warnings FATAL => 'all';
use Apache::TestRunPerl ();
use Apache::TestUtil qw(t_write_file);
use File::Path qw(rmtree);

my $dir = "$FindBin::Bin/envdir";
mkdir($dir) unless -d $dir;

if(-d "$dir/empty") { rmtree("$dir/empty") || die $!; }
mkdir("$dir/empty");

if(-d "$dir/noprefix") { rmtree("$dir/noprefix") || die $!; }
mkdir("$dir/noprefix");

for(my $i=1; $i<5; $i++) {
  open(OUT, ">$dir/TEST$i") || die $!;
  print OUT $i;
  close OUT;
  open(OUT, ">$dir/noprefix/NOPREFIX$i") || die $!;
  print OUT $i;
  close OUT;
}

Apache::TestRunPerl->new->run(@ARGV);
