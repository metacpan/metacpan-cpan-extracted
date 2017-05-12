package My::Builder::Unix;

use strict;
use warnings;
use base 'My::Builder';

use File::Spec::Functions qw(catdir catfile rel2abs);
use File::Spec;
use Config;

sub build_binaries {
  my ($self, $build_out, $srcdir) = @_;
  $srcdir ||= 'src';
  my $prefixdir = rel2abs($build_out);
  $self->config_data('build_prefix', $prefixdir); # save it for future ConfigData
  
  #hack - use updated config.guess + config.sub - remove when fixed in tidyp distribution
  require File::Copy;
  File::Copy::copy("patches/config.sub","$srcdir/config.sub");
  File::Copy::copy("patches/config.guess","$srcdir/config.guess");
  #end of hack

  chdir $srcdir;

  # do './configure ...'
  my $run_configure = 'y';
  $run_configure = $self->prompt("Run ./configure again? (y/n)", "n") if (-f "config.status");
  if (lc($run_configure) eq 'y') {
    my @cmd = ( './configure', '--enable-shared=no', '--disable-dependency-tracking', "--prefix=$prefixdir");
    if ($^O eq 'darwin') {
      #this is fix for https://rt.cpan.org/Ticket/Display.html?id=66382
      push @cmd, "CFLAGS=$Config{ccflags} -fPIC";
      push @cmd, "LDFLAGS=$Config{ldflags}";
    }
    else {
      #FIXME maybe use %Config values for all UNIX systems (not now, maybe in the future)
      push @cmd, 'CFLAGS=-fPIC';
    }    
    #On solaris, some tools like 'ar' are not in the default PATH, but in /usr/???/bin
    #see failure http://www.cpantesters.org/cpan/report/138b45f2-4b6f-11e0-afaf-8138785ebe45
    if ($^O eq 'solaris' && system('arx -V') < 0) {    
      for (qw[/usr/ccs/bin /usr/xpg4/bin /usr/sfw/bin /usr/xpg6/bin /usr/gnu/bin /opt/gnu/bin /usr/bin]) {
        if (-x "$_/ar") {
          push @cmd, "AR=$_/ar";
          last;
        }
      }
    }
    print STDERR "Configuring ...\n";
    print STDERR "(cmd: ".join(' ',@cmd).")\n";
    $self->do_system(@cmd) or die "###ERROR### [$?] during ./configure ... ";
  }

  # do 'make install'
  my @cmd = ($self->get_make, 'install');
  print STDERR "Running make install ...\n";
  print STDERR "(cmd: ".join(' ',@cmd).")\n";
  $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";

  chdir $self->base_dir();
  return 1;
}

sub get_make {
  my ($self) = @_;
  my $devnull = File::Spec->devnull();
  my @try = ($Config{gmake}, 'gmake', 'make', $Config{make});
  my %tested;
  print STDERR "Gonna detect GNU make:\n";

  if ($^O eq 'cygwin') {
    print STDERR "- on cygwin always 'make'\n";
    return 'make'
  }

  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print STDERR "- testing: '$name'\n";
    my $ver = `$name --version 2> $devnull`;
    if ($ver =~ /GNU Make/i) {
      print STDERR "- found: '$name'\n";
      return $name
    }
  }
  print STDERR "- fallback to: 'make'\n";
  return 'make';
}

# we are not afraid of dirnames with spaces on UNIX
# IMPORTANT: EU::MM is not properly handling -L'/path/to/lib/dir'

#sub quote_literal {
#    my ($self, $txt) = @_;
#    $txt =~ s|'|'\\''|g;
#    return "'$txt'";
#}

1;
