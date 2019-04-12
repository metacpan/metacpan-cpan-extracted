use ExtUtils::Depends;
use Data::Dumper qw(Dumper);
use IO::All;
use File::Spec;
use ExtUtils::PkgConfig;

my %gimpcfg = ExtUtils::PkgConfig->find("gimp-2.0");
my $gimppath = File::Spec->catdir(ExtUtils::PkgConfig->variable("gimp-2.0", "exec_prefix"), "bin");
my $gimptool = File::Spec->catfile($gimppath, "gimptool-2.0");
my ($plugindir, $pluginlibs) = split /\n/, `$gimptool --gimpplugindir --libs`;

my $gimpbinname = ExtUtils::PkgConfig->modversion("gimp-2.0");
$gimpbinname =~ s/^(\d\.\d).*/$1/; # strip off minor versions
die "Need GIMP version at least 2.8.0\n" unless $gimpbinname >= 2.8;

sub ag_getconfig {
  my %cfg = (
    gimp => File::Spec->catfile($gimppath, "gimp-" . $gimpbinname),
    gimptool => $gimptool,
    gimpplugindir => File::Spec->catdir($plugindir, "plug-ins"),
  );
  \%cfg;
}

sub ag_getbuild {
  +{
    cflags => $gimpcfg{cflags},
    pluginlibs => $pluginlibs,
  };
}

sub ag_getversion {
  '0.08';
}

1;
