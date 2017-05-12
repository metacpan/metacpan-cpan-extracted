package My::Builder;

use strict;
use warnings;

use base 'Module::Build';

use Archive::Extract;
use Config;
use Digest::SHA qw(sha1_hex);
use ExtUtils::Command;
use File::chdir;
use File::Basename;
use File::Copy qw/copy/;
use File::Fetch;
use File::Path qw/make_path/;
use File::Spec::Functions qw(catfile rel2abs);
use File::Temp qw(tempdir tempfile);
use File::ShareDir;
use Text::Patch;

sub ACTION_install {
  my $self = shift;
  my $sharedir = eval {File::ShareDir::dist_dir('Alien-AntTweakBar')};
  $self->clean_dir($sharedir) if $sharedir; # remove previous versions
  return $self->SUPER::ACTION_install(@_);
}

sub ACTION_code {
  my $self = shift;

  unless (-e 'build_done') {
    $self->add_to_cleanup('build_done');
    my $inst = $self->notes('installed_tidyp');
    if (defined $inst) {
      $self->config_data('config', {
          LIBS   => $inst->{lflags},
          INC    => $inst->{cflags},
      });
    }
    else {
      # important directories
      my $download = 'download';
      my $patches = 'patches';
      my $build_src = '_build_src';
      # we are deriving the subdir name from VERSION as we want to prevent
      # troubles when user reinstalls the newer version of Alien::AntTweakBar
      my $build_out = catfile('sharedir', $self->{properties}->{dist_version});
      $self->add_to_cleanup($build_out);
      $self->add_to_cleanup($build_src);

      # get sources
      my $tarball = $self->args('srctarball');
      my $sha1 = $self->notes('sha1');
      my $url = $self->notes('src_url');
      $self->notes('src_dir', "$build_src/AntTweakBar/src");
      my $archive;
      if ($tarball && -f $tarball) {
        $archive = $tarball;
        $self->check_sha1sum($archive, $sha1)
            || die "###ERROR### Checksum failed '$archive'";
      }
      elsif ($tarball && $tarball =~ /^[a-z]+:\/\//) {
        warn "Downloading from explicit URL: '$tarball'\n" if $tarball;
        $archive = $self->fetch_file([$tarball], $sha1, $download)
            || die "###ERROR### Download failed\n";
      }
      elsif ($tarball) {
        die "###ERROR### Wrong value of --srctarball option (non existing file or invalid URL)\n";
      }
      else {
        $archive = $self->fetch_file([$url], $sha1, $download)
            || die "###ERROR### Download failed\n";
      }
      print STDERR "Checking checksum '$archive'...\n";

      #extract source codes
      my $extract_src = 'y';
      if (lc($extract_src) eq 'y') {
        my $ae = Archive::Extract->new( archive => $archive );
        $ae->extract(to => $build_src) || die "###ERROR### Cannot extract tarball ", $ae->error;
        die "###ERROR### Cannot find expected dir='",$self->notes('src_dir'),"'"
             unless -d $self->notes('src_dir');
      }

      $self->prebuild if $self->can('prebuild');
      $self->build_binaries if $self->can('build_binaries');
	  $self->preinstall_binaries($build_out);

      $self->config_data('share_subdir', $self->{properties}->{dist_version});
      $self->config_data('config', {
          PREFIX => '@PrEfIx@',
          libs   => '-L' . $self->quote_literal('@PrEfIx@/lib') . ' -lAntTweakBar',
          cflags => '-I' . $self->quote_literal('@PrEfIx@/include'),
      });
    }
    # mark sucessfully finished build
    local @ARGV = ('build_done');
    ExtUtils::Command::touch;
  }
  $self->SUPER::ACTION_code;
}

sub fetch_file {
  my ($self, $url_list, $sha1sum, $download) = @_;
  die "###ERROR### _fetch_file undefined url\n" unless $url_list;
  die "###ERROR### _fetch_file undefined sha1sum\n" unless $sha1sum;
  for my $url (@$url_list) {
    my $ff = File::Fetch->new(uri => $url);
    my $fn = catfile($download, $ff->file);
    if (-e $fn) {
      print STDERR "Checking checksum for already existing '$fn'...\n";
      return $fn if $self->check_sha1sum($fn, $sha1sum);
      unlink $fn; #exists but wrong checksum
    }
    print STDERR "Fetching '$url' ...\n";
    my $fullpath = $ff->fetch(to => $download);
    if ($fullpath && -e $fullpath && $self->check_sha1sum($fullpath, $sha1sum)) {
      print STDERR "Download OK (filesize=".(-s $fullpath).")\n";
      return $fullpath;
    }
    warn "###WARNING### Unable to fetch '$url'\n";
  }
  return;
}

sub check_sha1sum {
  my ($self, $file, $sha1sum) = @_;
  my $sha1 = Digest::SHA->new;
  my $fh;
  open($fh, $file) or die "###ERROR## Cannot check checksum for '$file'\n";
  binmode($fh);
  $sha1->addfile($fh);
  close($fh);
  my $rv = ($sha1->hexdigest eq $sha1sum) ? 1 : 0;
  warn "###WARN## sha1 mismatch: got      '", $sha1->hexdigest , "'\n",
       "###WARN## sha1 mismatch: expected '", $sha1sum, "'\n",
       "###WARN## sha1 mismatch: filesize '", (-s $file), "'\n", unless $rv;
  return $rv;
}

sub clean_dir {
  my( $self, $dir ) = @_;
  if (-d $dir) {
    File::Path::rmtree($dir);
    File::Path::mkpath($dir);
  }
}

sub quote_literal {
  # this can be be overriden in My::Builder::<platform>
  my ($self, $path) = @_;
  return $path;
}

# pure perl implementation of patch functionality
sub apply_patch {
  my ($self, $dir_to_be_patched, $patch_file) = @_;
  my ($src, $diff);

  undef local $/;
  open(DAT, $patch_file) or die "###ERROR### Cannot open file: '$patch_file'\n";
  $diff = <DAT>;
  close(DAT);
  $diff =~ s/\r\n/\n/g; #normalise newlines
  $diff =~ s/\ndiff /\nSpLiTmArKeRdiff /g;
  my @patches = split('SpLiTmArKeR', $diff);

  print STDERR "Applying patch file: '$patch_file'\n";
  foreach my $p (@patches) {
    my ($k) = map{$_ =~ /\n---\s*([\S]+)/} $p;
    # doing the same like -p1 for 'patch'
    $k =~ s|\\|/|g;
    $k =~ s|^[^/]*/(.*)$|$1|;
    $k = catfile($dir_to_be_patched, $k);
    print STDERR "- gonna patch '$k'\n" if $self->notes('build_debug_info');

    open(SRC, $k) or die "###ERROR### Cannot open file: '$k'\n";
    $src  = <SRC>;
    close(SRC);
    $src =~ s/\r\n/\n/g; #normalise newlines

    my $out = eval { Text::Patch::patch( $src, $p, { STYLE => "Unified" } ) };
    if ($out) {
      open(OUT, ">", $k) or die "###ERROR### Cannot open file for writing: '$k'\n";
      print(OUT $out);
      close(OUT);
    }
    else {
      warn "###WARN### Patching '$k' failed: $@";
    }
  }
}

sub build_binaries {
	my $self = shift;
    print STDERR "Running make ...\n";
    {
        local $CWD = rel2abs( $self->notes('src_dir') );
        #search PATH for c++ compiler
        my $cxx = $self->search_env_path(qw/c++ g++ gpp aCC CC cxx cc++ cl FCC KCC RCC xlC_r xlC/);
        my @cmd = ($self->_get_make);
        push @cmd, "CXX=$cxx" if $cxx;
        printf("(cmd: %s)\n", join(' ', @cmd));
        $self->do_system(@cmd) or die "###ERROR### [$?] during make ... ";
    }
    return 1;
}

sub _get_make {
  my ($self) = @_;

  return $Config{make} if $^O =~ /^(cygwin|MSWin32)$/;

  my @try = ('make', $Config{gmake}, 'gmake', 'make', $Config{make});
  my %tested;
  print "Gonna detect default system make:\n";
  foreach my $name ( @try ) {
    next unless $name;
    next if $tested{$name};
    $tested{$name} = 1;
    print "- testing: '$name'\n";
    if ($self->_is_make($name)) {
      print "- found: '$name'\n";
      return $name
    }
  }
}

sub _is_make {
  my ($self, $name) = @_;
  my $devnull = File::Spec->devnull();
  my $ver = `$name --version 2> $devnull`;
  if ($ver =~ /make/i) {
    return 1;
  }
  return 0;
}

sub search_env_path {
  my $self = shift;
  my $sep = $Config{path_sep};
  my $ext = $Config{exe_ext};
  for my $exe (@_) {
    for my $dir (split /\Q$sep\E/,$ENV{PATH}) {
      return $exe if -x "$dir/$exe$ext";
    }
  }
}

sub preinstall_binaries {
    my ($self, $out) = @_;
    print STDERR "doing local installation ...\n";
    make_path("$out/lib", "$out/include");
    my $src_dir = rel2abs( $self->notes('src_dir') );
    my %intalled_files = (
        "$src_dir/../include/AntTweakBar.h"   => "$out/include/",
        "$src_dir/../lib/libAntTweakBar.a"    => "$out/lib/",
    );
    while (my ($from, $to_dir) = each %intalled_files) {
        my $to = $to_dir . basename($from);
        copy($from, $to) or die("can't copy $from -> $to: $!");
    }
	return 1;
}

1;
