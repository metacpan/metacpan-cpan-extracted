use strict;
use warnings;
use File::Spec;
use JSON::PP qw( encode_json decode_json );
use File::Copy qw( cp );
use File::Path qw( mkpath );

my $status_filename = File::Spec->catfile('_alien', '05stage.json');
exit if -e $status_filename;

my %status;

my $share_dir = File::Spec->catdir(qw( blib lib auto share dist Alien-pkgconf ));

foreach my $type (qw( dll static ))
{
  my $build = do {
    my $fn = File::Spec->catfile('_alien', "04build_$type.json");
    open my $fh, '<', $fn;
    my $json = decode_json(do { local $/; <$fh> });
    close $fh;
    $json;
  };

  next if $build->{skip};

  recurse(
    File::Spec->catdir($build->{destdir}, @{ $build->{prefix} }),
    [],
    $share_dir,
  );

  if($type eq 'static')
  {
    local $ENV{PKG_CONFIG_PATH} = File::Spec->catdir($build->{destdir}, @{ $build->{prefix} }, qw( lib pkgconfig ));
    print "PKG_CONFIG_PATH = $ENV{PKG_CONFIG_PATH}\n";
    my $pkgconf = File::Spec->catfile($build->{destdir}, @{ $build->{prefix} }, qw( bin pkgconf ));
    print "pkgconf = $pkgconf\n";
    $status{cflags} = `$pkgconf --cflags libpkgconf`;
    die "unable to probe for cflags" if $?;
    chomp $status{cflags};
    $status{libs}   = `$pkgconf --libs   libpkgconf`;
    die "unable to probe for libs" if $?;
    chomp $status{libs};
    $status{version} = `$pkgconf --modversion libpkgconf`;
    die "unable to probe for version" if $?;
    chomp $status{version};
    $status{install_type} = 'share';
  }
  elsif($type eq 'dll')
  {
    my $dir = File::Spec->catdir($build->{destdir}, @{ $build->{prefix} }, 'dll');
    my $dh;
    opendir $dh, $dir;
    while(my $fn = readdir $dh)
    {
      next if $fn =~ /^\.\.?$/;
      my $path = File::Spec->catfile($dir, $fn);
      next if -l $path;
      if($fn =~ /^lib.*\.so/
      || $fn =~ /\.dll$/
      || $fn =~ /\.(dylib|bundle)$/)
      {
        $status{dll} = $fn;
      }
    }
    closedir $dh;
  }
}

{
  my $filename = File::Spec->catfile($share_dir, 'status.json');
  open my $fh, '>', $filename;
  print $fh JSON::PP->new->utf8->canonical->encode(\%status);
  close $fh;
}

{
  open my $fh, '>', $status_filename;
  print $fh JSON::PP->new->utf8->canonical->encode(\%status);
  close $fh;
}

{
  my $dir = File::Spec->catdir(qw( blib arch auto Alien pkgconf ));
  my $fn  = File::Spec->catfile($dir, 'pkgconf.txt');
  mkpath $dir, 0, 0744;
  open my $fh, '>', $fn;
  print $fh "Alien based distribution with architecture specific file in share\n";
  close $fh;
}

sub recurse
{
  my($root, $path, $shae_dir) = @_;
  my $dir = File::Spec->catdir($root, @$path);
  my $dh;
  opendir $dh, $dir;
  while(my $fn = readdir $dh)
  {
    next if $fn =~ /^\.\.?$/;
    if(-d File::Spec->catdir($dir, $fn))
    {
      recurse($root, [@$path, $fn]);
    }
    else
    {
      print "stage ", File::Spec->catfile(@$path, $fn), "\n";
      my $from = File::Spec->catfile($dir, $fn);
      my $sdir = File::Spec->catdir ($share_dir, @$path);
      my $to   = File::Spec->catfile($share_dir, @$path, $fn);
      mkpath $sdir, 0, 0744;

      if(-l $from)
      {
        my $target = readlink $from;
        symlink $target, $to;
      }
      else
      {
        cp($from, $to) || die "Copy $from => $to failed $!";
        # Perl 5.8 and 5.10 cp doesn't preserve perms apparently
        eval { chmod 0755, $to } if -x $from && $] < 5.012;
      }
    }
  }
  closedir $dh;
}
