package My::Utility;
use strict;
use warnings;
use base qw(Exporter);

our @EXPORT_OK = qw(check_config_script check_prebuilt_binaries check_src_build find_PNG_dir find_file sed_inplace);
use Config;
use File::Spec::Functions qw(splitdir catdir splitpath catpath rel2abs);
use File::Find qw(find);
use File::Copy qw(cp);
use Cwd qw(realpath);

#### packs with prebuilt binaries
# - all regexps has to match: arch_re ~ $Config{archname}, cc_re ~ $Config{cc}, os_re ~ $^O
# - the order matters, we offer binaries to user in the same order (1st = preffered)
my $prebuilt_binaries = [
    {
      title    => "Binaries Win/32bit PNG-1.2.40 (20100328) RECOMMENDED",
      url      => 'http://froggs.de/libpng/Win32_libpng-1.2.40_bin-20100328.zip',
      sha1sum  => 'f414f5c5d3cb8cafb4fec7f4bdf2ab4146da9630',
      arch_re  => qr/^MSWin32-x86-multi-thread$/,
      os_re    => qr/^MSWin32$/,
      cc_re    => qr/gcc/,
    },
 ];

#### tarballs with source codes
my $source_packs = [
## the first set for source code build will be a default option
  {
    title   => "Source code build: PNG-1.4.1",
    members => [
#      {
#        pack => 'zlib',
#        dirname => 'zlib-1.2.4',
#        url => 'http://www.zlib.net/zlib-1.2.4.tar.gz',
#        sha1sum  => '22965d40e5ca402847f778d4d10ce4cba17459d1',
#      },
      {
        pack => 'libpng',
        dirname => 'libpng-1.4.1',
        url => 'http://downloads.sourceforge.net/libpng/libpng-1.4.1.tar.gz',
        sha1sum  => '7a3488f5844068d67074f2507dd8a7ed9c69ff04',
      },
    ],
  },
];

sub check_config_script
{
  my $script = shift || 'libpng-config';
  print "Gonna check config script...\n";
  print "(scriptname=$script)\n";
  my $devnull = File::Spec->devnull();
  my $cflags  = `$script --cflags 2>$devnull`;
  $cflags =~ s/^-I//;
  $cflags =~ s/[\s\n\r]*$//;
  my ($version) = find_PNG_dir($cflags);
  return if($? >> 8);
  my $prefix = `$script --prefix 2>$devnull`;
  return if($? >> 8);
  $version =~ s/[\r\n]*$//;
  $prefix =~ s/[\r\n]*$//;
  #returning HASHREF
  return {
    title     => "Already installed PNG-$version path=$prefix",
    buildtype => 'use_config_script',
    script    => $script,
    prefix    => $prefix,
  };
}

sub check_prebuilt_binaries
{
  print "Gonna check availability of prebuilt binaries ...\n";
  print "(os=$^O cc=$Config{cc} archname=$Config{archname})\n";
  my @good = ();
  foreach my $b (@{$prebuilt_binaries}) {
    if ( ($^O =~ $b->{os_re}) &&
         ($Config{archname} =~ $b->{arch_re}) &&
         ($Config{cc} =~ $b->{cc_re}) ) {
      $b->{buildtype} = 'use_prebuilt_binaries';
      push @good, $b;
    }
  }
  #returning ARRAY of HASHREFs (sometimes more than one value)
  return \@good;
}

sub check_src_build
{
  print "Gonna check possibility for building from sources ...\n";
  print "(os=$^O cc=$Config{cc})\n";
  foreach my $p (@{$source_packs}) {
    $p->{buildtype} = 'build_from_sources';
  }
  return $source_packs;
}

sub find_file {
  my ($dir, $re) = @_;
  my @files;
  $re ||= qr/.*/;
  find({ wanted => sub { push @files, rel2abs($_) if /$re/ }, follow => 1, no_chdir => 1 , follow_skip => 2}, $dir);
  return @files;
}

sub find_PNG_dir {
  my $root = shift;
  my ($version, $prefix, $incdir, $libdir);
  return unless $root;

  # try to find png.h
  my ($found) = find_file($root, qr/png\.h$/i ); # take just the first one
  return unless $found;

  # get version info
  open(DAT, $found) || return;
  my @raw=<DAT>;
  close(DAT);
  my ($v_maj) = grep(/^#define[ \t]+PNG_LIBPNG_VER_MAJOR[ \t]+[0-9]+/, @raw);
  $v_maj =~ s/^#define[ \t]+PNG_LIBPNG_VER_MAJOR[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_min) = grep(/^#define[ \t]+PNG_LIBPNG_VER_MINOR[ \t]+[0-9]+/, @raw);
  $v_min =~ s/^#define[ \t]+PNG_LIBPNG_VER_MINOR[ \t]+([0-9]+)[.\r\n]*$/$1/;
  my ($v_pat) = grep(/^#define[ \t]+PNG_LIBPNG_VER_RELEASE[ \t]+[0-9]+/, @raw);
  $v_pat =~ s/^#define[ \t]+PNG_LIBPNG_VER_RELEASE[ \t]+([0-9]+)[.\r\n]*$/$1/;
  return if (($v_maj eq '')||($v_min eq '')||($v_pat eq ''));
  $version = "$v_maj.$v_min.$v_pat";

  # get prefix dir
  my ($v, $d, $f) = splitpath($found);
  my @pp = reverse splitdir($d);
  shift(@pp) if(defined($pp[0]) && $pp[0] eq '');
  shift(@pp) if(defined($pp[0]) && $pp[0] =~ /libpng\d+/);
  if(defined($pp[0]) && $pp[0] eq 'include') {
    shift(@pp);
    @pp = reverse @pp;
    return (
      $version,
      catpath($v, catdir(@pp), ''),
      catpath($v, catdir(@pp, 'include'), ''),
      catpath($v, catdir(@pp, 'lib'), ''),
    );
  }
}

sub sed_inplace {
  # we expect to be called like this:
  # sed_inplace("filename.txt", 's/0x([0-9]*)/n=$1/g');
  my ($file, $re) = @_;
  if (-e $file) {
    cp($file, "$file.bak") or die "###ERROR### cp: $!";
    open INPF, "<", "$file.bak" or die "###ERROR### open<: $!";
    open OUTF, ">", $file or die "###ERROR### open>: $!";
    binmode OUTF; # we do not want Windows newlines
    while (<INPF>) {
     eval( "$re" );
     print OUTF $_;
    }
    close INPF;
    close OUTF;
  }
}

1;
