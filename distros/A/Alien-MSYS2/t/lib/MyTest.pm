package MyTest;

use strict;
use warnings;
use base qw( Exporter );
use File::Path qw( mkpath rmtree );
use Archive::Tar;
use File::Spec;
use Cwd qw( getcwd );

our @EXPORT = qw( my_chdir my_extract_dontpanic my_cleanup );

my $tar_filename = File::Spec->rel2abs(
  File::Spec->catfile(qw( corpus dontpanic-1.00.tar ))
);

my $start = getcwd();
my_cleanup();

sub my_chdir
{
  chdir($_[0]) || die "unable to chdir $_[0] $!";
}

sub my_extract_dontpanic
{
  my $dir = File::Spec->catdir($start, @_);
  mkpath $dir, 0, 0700 unless -d $dir;
  my_chdir($dir);
  my $tar = Archive::Tar->new;
  $tar->read($tar_filename);
  $tar->extract;
  chdir 'dontpanic-1.00';
}

sub my_cleanup
{
  chdir $start;
  my $tmp = File::Spec->catfile($start, qw( t tmp ));
  rmtree( $tmp, 0, 0)
    if -d $tmp;
}

1;
