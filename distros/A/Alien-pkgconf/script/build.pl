use strict;
use warnings;
use Config;
use File::Spec;
use File::Path qw( rmtree );
use JSON::PP qw( encode_json decode_json );
use if $^O eq 'MSWin32', 'Alien::MSYS';
use Env qw( @PATH );

unshift @PATH, Alien::MSYS->msys_path if $^O eq 'MSWin32';

sub _catdir
{
  my $path = File::Spec->catdir(@_);
  $path =~ s{\\}{/}g if $^O eq 'MSWin32';
  $path;
}

sub _rootdir
{
  $^O eq 'MSWin32' ? () : File::Spec->rootdir;
}

my $type = shift @ARGV;

unless(defined $type && $type =~ /^(static|dll)$/)
{
  print STDERR "usage: $0 [static|dll]\n";
  exit 2;
}

my $status_filename = File::Spec->catfile('_alien', "04build_$type.json");
exit if -e $status_filename;

if($type eq 'dll')
{
  # This IF is the logic we use to determine if we should skip the
  # dynamic lib build.  For example if we know it is unsupported.
  if($^O eq 'cygwin')
  {
    my $fh;
    open($fh, '>', $status_filename) || die "unable to write $status_filename $!";
    print $fh encode_json({ skip => 1 });
    close $fh;
    exit;
  }
}

my $src_dir = do {
  my $fn = File::Spec->catfile('_alien', '03extract.json');
  open my $fh, '<', $fn;
  my $json = decode_json(do {local $/; <$fh> });
  close $fn;
  $json->{src_dir};
};

my $probe = do {
  my $fn = File::Spec->catfile('_alien', '01probe.json');
  open my $fh, '<', $fn;
  my $json = decode_json(do {local $/; <$fh> });
  close $fn;
  $json;
};

$ENV{DESTDIR} = File::Spec->rel2abs(_catdir('_alien', 'build', $type));

print "destd $ENV{DESTDIR}\n";

chdir($src_dir) || die "unable to chdir $src_dir $!";

sub run
{
  print "+run+ @_\n";
  system(@_);
  die "failed" if $?;
}

my @prefix = @{ $probe->{prefix} };
my @configure_flags = (
  '--with-pic',
  '--prefix=' . _catdir(_rootdir, @prefix),
  '--with-pkg-config-dir='    .  join($Config{path_sep}, @{ $probe->{pkg_config_dir}     }),
  '--with-system_libdir='     .  join($Config{path_sep}, @{ $probe->{system_libdir}      }),
  '--with-system_includedir=' .  join($Config{path_sep}, @{ $probe->{system_includedir}  }),
);

if($type eq 'static')
{
  unshift @configure_flags,
    '--disable-shared',
    '--enable-static';
}
elsif($type eq 'dll')
{
  unshift @configure_flags,
    '--libdir=' . _catdir(_rootdir, @prefix, 'dll'),
    '--enable-shared',
    '--disable-static';
}

if(-e 'Makefile')
{
  run 'make', 'distclean';
}

if($^O eq 'solaris')
{
  outer:
  foreach my $dir (@PATH, '/usr/gnu/bin')
  {
    foreach my $try (map { File::Spec->catfile($dir, $_) } qw( gnm nm ))
    {
      if(-x $try)
      {
        my($line) = `$try --version`;
        if($? == 0 && $line =~ /GNU nm/)
        {
          print "+setenv+ NM = $try\n";
          $ENV{NM} = $try;
          last outer;
        }
      }
    }
  }
}

run 'sh', 'configure', @configure_flags;
run 'make', 'V=1';
run 'make', 'install';

my @cleanup = (
  ['share'],
);

if($type eq 'dll')
{
  unshift @cleanup, ['bin'];
  unshift @cleanup, ['dll', 'pkgconfig'];
  unshift @cleanup, ['include'];
}

foreach my $cleanup (@cleanup)
{
  rmtree(_catdir($ENV{DESTDIR}, @prefix, @$cleanup), 0, 0);
}

chdir(_catdir(File::Spec->updir, File::Spec->updir, File::Spec->updir));

my $fh;
open($fh, '>', $status_filename) || die "unable to write $status_filename $!";
print $fh JSON::PP->new->utf8->canonical->encode({ destdir => $ENV{DESTDIR}, prefix => \@prefix, skip => 0 });
close $fh;
