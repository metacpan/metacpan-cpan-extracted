use strict;
use warnings;
use File::Spec;

my $libnova_dir = shift;
die if not defined $libnova_dir or not -d $libnova_dir;

my $code = do {local $/=undef; <DATA>};

my $dir = File::Spec->catdir($libnova_dir, 'src');

use File::Find 'find';

find(
  sub {
    my $file = $_;
    return if not -f $file or not $file =~ /\.(?:hh?|cc?|cpp)$/i;
    my $contents = do {
      local $/=undef;
      open my $fh, "<", $file or die "Cannot open file '$file' for reading: $!";
      <$fh>
    };

    if ($contents =~ s/(\#ifdef\s*HAVE_LIBsunmath.*)\#endif/$1$code/s) {
      open my $fh, '>', $file or die "Cannot open file '$file' for writing: $!";
      print $fh $contents;
      close $fh;
    }
  },
  $dir
);

open my $fh, '>', File::Spec->catfile($libnova_dir, '.cosl_patched') or die $!;
close $fh;

__DATA__

#else
#ifndef cosl
#define cosl(phi) cos(phi)
#endif
#ifndef sinl
#define sinl(phi) sin(phi)
#endif
#ifndef tanl
#define tanl(phi) tan(phi)
#endif
#ifndef acosl
#define acosl(phi) acos(phi)
#endif
#ifndef asinl
#define asinl(phi) asin(phi)
#endif
#ifndef atanl
#define atanl(phi) atan(phi)
#endif
#ifndef atan2l
#define atan2l(y,x) atan2(y,x)
#endif
#endif

