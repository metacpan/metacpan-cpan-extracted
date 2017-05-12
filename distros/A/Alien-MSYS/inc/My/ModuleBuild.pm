package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use File::Path qw( mkpath );
use File::Spec;
use Env qw( @PATH );
use FindBin ();
use File::Temp qw( tempdir );

sub ACTION_build
{
  my $self = shift;

  return $self->SUPER::ACTION_build(@_)
    if $^O ne 'MSWin32' || do {
      require lib;
      lib->import('lib');
      require Alien::MSYS;
      # TODO: this means on a re-install we have to re-download
      # if it has been a long time since the last version, this may
      # not be a bad thing.  If we end up having lots of revisions
      # this could be highly annoying.
      do { no warnings 'redefine'; *Alien::MSYS::_my_dist_dir = sub {} };
      defined Alien::MSYS::msys_path();
    };

  return $self->SUPER::ACTION_build(@_)
    if $^O ne 'MSWin32' || $ENV{PERL_ALIEN_MSYS_BIN} || -d 'C:/MinGW/msys/1.0/bin';

  require HTTP::Tiny;
  my $http = HTTP::Tiny->new;
  
  my $url = 'http://sourceforge.net/projects/mingw/files/Installer/mingw-get/';
  my $index = $http->get($url);
  
  $index->{status} =~ /^2..$/ || die join(' ', $index->{status}, $index->{reason}, $url);
  
  my $link;
  
  for($index->{content} =~ m{"/(projects/mingw/files/Installer/mingw-get/mingw-get-.*?-(\d\d\d\d\d\d\d\d)-(\d+))/"})
  {
    if(!defined $link || ($link->{date} <= $2 && $link->{num} < $3))
    {
      $link = {
        url  => "http://sourceforge.net/$1",
        date => $2,
        num  => $2,
      };
    }
  }

  die "couldn't find mingw-get in index" unless $link;

  $url = $link->{url};
  $index = $http->get($url);
  
  $index->{status} =~ /^2..$/ || die join(' ', $index->{status}, $index->{reason}, $url);

  die "couldn't find mingw-get in download index"
    unless $index->{content} =~ m{"(https?://.*/(mingw-get-.*?-bin.zip)/download)"};
    
  $url = $1;
  my $zipname = $2;
  print "url = $url\n";
  print "zip = $zipname\n";
  my $download = $http->get($url);

  $download->{status} =~ /^2..$/ || die join(' ', $download->{status}, $download->{reason}, $url);

  require Archive::Zip;
  
  my $dir = File::Spec->catdir($FindBin::Bin, qw( share ));
  mkpath($dir, 1, 0755);
  
  chdir $dir;
  
  my $zip = Archive::Zip->new;
  $zip->read(do {
    my $fn = File::Spec->catdir(tempdir(CLEANUP => 0), $zipname);
    open my $fh, '>', $fn;
    binmode $fh;
    print $fh $download->{content};
    close $fh;
    print "fn = $fn\n";
    $fn;
  });
  $zip->extractTree();
  
  my $dh;
  opendir($dh, File::Spec->catdir($dir, qw( libexec mingw-get )));
  foreach my $file (readdir $dh)
  {
    next unless $file =~ /\.dll$/;
    eval { chmod 0755, $file };
  }
  closedir $dh;
  
  _cdup();

  push @PATH, File::Spec->catdir($dir, qw( bin ));
  system 'mingw-get', 'install', 'msys';

  $self->SUPER::ACTION_build(@_);
}

sub _cdup
{
  chdir(File::Spec->updir);
}

1;
