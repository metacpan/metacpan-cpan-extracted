use strict;
use warnings;
use HTTP::Tiny;
use JSON::PP qw( encode_json );
use File::Spec;
use File::Path qw( mkpath );
use File::Basename qw( dirname basename );

# this is somewhat brittle, but is low on dependencies.
# it is very specific to pkgconf, and reuse only at your
# own risk!

my $status_filename = File::Spec->catfile('_alien', '02fetch.json');
exit if -e $status_filename;

my @dirs = (
  [ '_alien', 'tar' ],
  [ '_alien', 'build', 'static' ],
  [ '_alien', 'build', 'dll' ],
);

mkpath $_, 0, 0700 for grep { ! -d $_ } map { File::Spec->catdir(@$_) } @dirs;

if($ENV{ALIEN_PKGCONF_TARBALL})
{
  # hack to test other parts until a usable version is available
  # on the website.
  my $fn  = basename $ENV{ALIEN_PKGCONF_TARBALL};
  my $dir = dirname $ENV{ALIEN_PKGCONF_TARBALL};
  print "fetch file://localhost/$ENV{ALIEN_PKGCONF_TARBALL}\n";
  print "write _alien/tar/$fn";
  system 'cp', "$dir/$fn", "_alien/tar/$fn";
  open my $fh, '>', $status_filename;
  print $fh encode_json({ filename => "_alien/tar/$fn" });
  close $status_filename;
  exit;
}

my $url = 'http://distfiles.dereferenced.org/pkgconf';
my $ua = HTTP::Tiny->new;

print "fetch $url\n";
my $res = $ua->get($url);

unless($res->{success})
{
  print "error retrieving $url\n";
  print STDERR "status = ", $res->{status}, "\n";
  print STDERR "reason = ", $res->{reason}, "\n";
  exit 2;
}

sub vercmp
{
  my($a,$b) = @_;
  my @a = @$a;
  my @b = @$b;
  return 0 if @a == 0 && @b == 0;
  if($a[0] == $b[0])
  {
    shift @a; shift @b;
    return vercmp(\@a, \@b);
  }
  $a[0] <=> $b[0];
}

sub extcmp
{
  my($a,$b) = @_;
  # prefer .gz, then .bz2, finally .xz
  my %ext = (
    # as of 1.2.1 pkgconf comes as a .gz
    # again, meaning we shouldn't need
    # Alien::xz anymore.
    #xz  => 1,
    bz2 => 2,
    gz  => 3,
  );
  $a =~ s/^.*\.//g;
  $b =~ s/^.*\.//g;
  ($ext{$a} || 0) <=> ($ext{$b} || 0);
}

my $filename;

$url = do {

  my @list;

  while($res->{content} =~ /\<a href=\"(pkgconf-([0-9\.]+)\.tar.*)\"/g)
  {
    my $path = $1;
    my @version = split /\./, $2;
    push @version, 0, 0 if @version == 1;
    push @version, 0    if @version == 2;
    push @list, [ $path, \@version ];
  }

  ($filename) = reverse 
                  map { $_->[0] } 
                  sort { 
                    vercmp($a->[1], $b->[1]) || extcmp($a->[0], $b->[0]);
                  } @list;

  die "unable to find filename in HTML" unless $filename;
  
  "$url/$filename";
};

print "fetch $url\n";
$res = $ua->get($url);

unless($res->{success})
{
  print "error retrieving $url\n";
  print STDERR "status = ", $res->{status}, "\n";
  print STDERR "reason = ", $res->{reason}, "\n";
  exit 2;
}

my $tar_filename = File::Spec->catfile(@{ $dirs[0] }, $filename);

print "write $tar_filename\n";
open my $fh, '>', $tar_filename;
binmode $fh;
print $fh $res->{content};
close $fh;

open $fh, '>', $status_filename;
print $fh encode_json({ filename => $tar_filename });
close $fh;
