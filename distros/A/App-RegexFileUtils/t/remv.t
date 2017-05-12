use strict;
use warnings;
use Test::More tests => 11;
use File::Temp qw( tempdir );
use App::RegexFileUtils;
use File::Spec;

BEGIN {
  eval q{
    use Capture::Tiny qw( capture );
    1;
  } || eval q{
    sub capture { $_[0]->() }
  };
  die $@ if $@;
}

my $dir = tempdir( CLEANUP => 1);
chdir($dir) || die;

ok -d $dir, "dir = $dir";

my @orig = qw( foo01.jPg foo02.jpeg foo03.jPEG foo04.JPEG foo05.jpg );
for (@orig)
{ open my $fh, '>', $_; close $fh }

ok -e $_, "orig $_" for @orig;

capture sub { App::RegexFileUtils->main('mv', '/\.jpe?g/.jpg/i') };

ok -e "foo0$_.jpg", "after foo0$_.jpg" for (1..5);

chdir(File::Spec->updir) || die;
