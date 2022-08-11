use strict;
use warnings;
use File::Spec;
use Archive::Tar;
use File::Path qw( rmtree mkpath );
use JSON::PP qw( encode_json decode_json );
#use Alien::xz;
use Env qw( @PATH );

my $status_filename = File::Spec->catfile('_alien', '03extract.json');
exit if -e $status_filename;

my $tar_filename = do {
  my $fn = File::Spec->catfile('_alien', '02fetch.json');
  open my $fh, '<', $fn;
  my $json = decode_json(do {local $/; <$fh> });
  close $fn;
  $json->{filename};
};

#if($tar_filename =~ /\.xz$/)
#{
#  # This module has a big warning not to use it in
#  # production code.  So.  Yeah don't do that.
#  require Alien::xz;
#  unshift @PATH, Alien::xz->bin_dir;
#
#  my $new = $tar_filename;
#  $new =~ s/\.xz$//;
#
#  system 'xz', '-d', $tar_filename;
#  die "failed to xz" if $?;
#
#  $tar_filename = $new;
#}

my $tar = Archive::Tar->new;
$tar->read($tar_filename);

my $src_dir = File::Spec->catdir( '_alien', 'src' );
rmtree $src_dir, 0, 1 if -d $src_dir;
mkpath $src_dir, 0, 0700;

print "untar $tar_filename\n";
chdir($src_dir) || die "unable to chdir $!";
$tar->extract;

if(-d "pkgconf-1.2.1" && $^O eq 'cygwin')
{
  chdir 'pkgconf-1.2.1';
  require Alien::patch;
  local $ENV{PATH} = $ENV{PATH};
  unshift @PATH, Alien::patch->bin_dir;
  system("@{[ Alien::patch->exe ]} -p1 < ../../../patch/pkgconf-cygwin-1.2.1.diff");
  die "unable to patch" if $?;
  chdir '..';
}

if(-d "pkgconf-1.3.9" && $^O eq 'solaris')
{
  chdir 'pkgconf-1.3.9';
  require Alien::patch;
  local $ENV{PATH} = $ENV{PATH};
  unshift @PATH, Alien::patch->bin_dir;
  system("@{[ Alien::patch->exe ]} -T -p1 < ../../../patch/pkgconf-solaris-1.3.9.diff");
  die "unable to patch" if $?;
  chdir '..';
}

chdir(File::Spec->catdir(File::Spec->updir, File::Spec->updir));

my $filename = do {
  my $dh;
  my @list;
  opendir($dh, $src_dir) || die "unable to open $src_dir $!";
  while(my $file = readdir $dh)
  {
    next if $file =~ /^\./;
    push @list, $file;
  }
  closedir $dh;

  die "no base directory extracted" if @list == 0;
  die "too many base directories"   if @list > 1;

  $list[0];
};

$filename = File::Spec->catdir('_alien', 'src', $filename);

print "write $filename\n";

my $fh;
open $fh, '>', $status_filename;
print $fh encode_json({ src_dir => $filename });
close $fh;
