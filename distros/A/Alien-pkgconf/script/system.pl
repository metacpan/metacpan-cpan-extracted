use strict;
use warnings;
use File::Spec;
use File::Copy qw( copy );
use File::Path qw( mkpath );

my $status_filename = File::Spec->catfile('_alien', '00system.json');
exit if -e $status_filename;

my $share_dir = File::Spec->catdir(qw( blib lib auto share dist Alien-pkgconf ));
mkpath $share_dir, 0, 0744 unless -d $share_dir;

{
  my $dir = File::Spec->catdir(qw( blib arch auto Alien pkgconf ));
  my $fn  = File::Spec->catfile($dir, 'pkgconf.txt');
  mkpath $dir, 0, 0744 unless -d $dir;
  open my $fh, '>', $fn;
  print $fh "Alien based distribution with architecture specific file in share\n";
  close $fh;
}

my $from = File::Spec->catfile(qw( _alien 05stage.json ));
my $to   = File::Spec->catfile($share_dir, 'status.json');

print "write $to\n";
copy($from, $to) || die "unable to copy $from => $to $!";

$to   = File::Spec->catfile(qw( _alien 00system.json ));

copy($from, $to) || die "unable to copy $from => $to $!";

