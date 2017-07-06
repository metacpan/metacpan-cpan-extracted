package My::ModuleBuild;

use strict;
use warnings;
use base qw( Module::Build );
use File::Path qw( mkpath );
use File::Spec;
use Env qw( @PATH );
use FindBin ();
use File::Temp qw( tempdir );
use Cwd qw( cwd );

sub _fetch_index1
{
  require HTTP::Tiny;  
  my $url = 'http://sourceforge.net/projects/mingw/files/Installer/mingw-get/';
  my $index = HTTP::Tiny->new->get($url);
  
  $index->{status} =~ /^2..$/ || die join(' ', $index->{status}, $index->{reason}, $url);
  
  my $link;
  
  for($index->{content} =~ m{"/(projects/mingw/files/Installer/mingw-get/mingw-get-.*?-(\d\d\d\d\d\d\d\d)-(\d+))/"})
  {
    if(!defined $link || ($link->{date} <= $2 && $link->{num} < $3))
    {
      $link = {
        url  => "http://sourceforge.net/$1",
        date => $2,
        num  => $3,
      };
    }
  }

  die "couldn't find mingw-get in index" unless $link;
  $link->{url};
}

sub _fetch_index2
{
  my(undef, $url) = @_;
  require HTTP::Tiny;  
  my $index = HTTP::Tiny->new->get($url);
  
  $index->{status} =~ /^2..$/ || die join(' ', $index->{status}, $index->{reason}, $url);

  die "couldn't find mingw-get in download index"
    unless $index->{content} =~ m{"(https?://.*/(mingw-get-.*?-bin.zip)/download)"};
    
  ($1, $2);
}

sub _fetch_zip
{
  my(undef, $url) = @_;
  my $download = HTTP::Tiny->new->get($url);
  $download->{status} =~ /^2..$/ || die join(' ', $download->{status}, $download->{reason}, $url);
  $download->{content};
}

sub ACTION_build
{
  my $self = shift;

  my $override_type = $ENV{ALIEN_MSYS_INSTALL_TYPE} || $ENV{ALIEN_INSTALL_TYPE} || '';

  return $self->SUPER::ACTION_build(@_)
    if $^O ne 'MSWin32';

  if($override_type ne 'share')
  {
    return $self->SUPER::ACTION_build(@_)
      if do {
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

    foreach my $try ($ENV{PERL_ALIEN_MSYS_BIN}, 'C:/MinGW/msys/1.0/bin')
    {
      my $sh_path = File::Spec->catfile($try, 'sh.exe');
      return $self->SUPER::ACTION_build(@_) if -x $sh_path;
    }
  }

  if($override_type eq 'system')
  {
    die "requested a system install, but could not be found!";
  }

  my($url, $zipname) = __PACKAGE__->_fetch_index2(__PACKAGE__->_fetch_index1);
  my $zipcontent = __PACKAGE__->_fetch_zip($url);

  require Archive::Zip;
  
  my $dir = File::Spec->catdir($FindBin::Bin, qw( share ));
  mkpath($dir, 1, 0755);
  
  my $save = cwd();
  chdir $dir;
  
  my $zip = Archive::Zip->new;
  $zip->read(do {
    my $fn = File::Spec->catdir(tempdir(CLEANUP => 0), $zipname);
    open my $fh, '>', $fn;
    binmode $fh;
    print $fh $zipcontent;
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
  
  chdir $save;

  push @PATH, File::Spec->catdir($dir, qw( bin ));
  system 'mingw-get', 'install', 'msys';
  
  # A lot of tools also need m4
  system 'mingw-get', 'install', 'msys-m4';
  
  # A number of autotools (autoconf, automake) are
  # implemented in Perl, but when you build them
  # with Perl on windows using MSYS, they use MSYS
  # paths, like /c/ instead of c:/, so yes.  we
  # also need MSYS Perl.  *sigh*
  system 'mingw-get', 'install', 'msys-perl';

  $self->SUPER::ACTION_build(@_);
}

1;
