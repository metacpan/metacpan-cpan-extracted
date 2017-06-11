package My::Builder;

use strict;
use warnings;
use base 'Module::Build';

use lib "inc";
use File::Spec::Functions qw(catfile rel2abs);
use ExtUtils::Command;
use LWP::Simple qw(getstore head);
use File::Find;
use File::Glob qw(bsd_glob);
use File::Path qw();
use File::ShareDir;
use File::Temp qw(tempdir tempfile);
use Digest::SHA qw(sha1_hex);
use Archive::Extract;
use Config;
use Text::Patch;
use IPC::Run3;

sub ACTION_install {
  my $self = shift;
  my $sharedir = eval {File::ShareDir::dist_dir('Alien-IUP')} || '';

  if ( -d $sharedir ) {
    print STDERR "Removing the old '$sharedir'\n";
    File::Path::rmtree($sharedir);
    File::Path::mkpath($sharedir);
  }

  return $self->SUPER::ACTION_install(@_);
}

sub ACTION_code {
  my $self = shift;

  if ( ! -e 'build_done' ) {
    my $inst = $self->notes('already_installed_lib');
    if (defined $inst) {
      $self->config_data('config', { LIBS   => $inst->{lflags},
                                     INC    => $inst->{cflags},
                                   });
    }
    else {
      # some questions before we start
      my $dbg = !$ENV{TRAVIS} ? $self->prompt("\nDo you want to see debug info + all messages during 'make' (y/n)?", 'n') : 'n';
      $self->notes('build_msgs',       lc($dbg) eq 'y' ? 1 : 0);
      $self->notes('build_debug_info', lc($dbg) eq 'y' ? 1 : 0);
      #my $large_imglib = $ENV{TRAVIS} ? 'y' : lc($self->prompt("Do you wanna compile built-in images with large (48x48) size? ", "y"));
      my $large_imglib = 'y'; #forcing large icons
      $self->notes('build_large_imglib', lc($large_imglib) eq 'y' ? 1 : 0);

      # important directories
      my $download = 'download';
      my $patches = 'patches';
      my $build_src = 'build_src';
      # we are deriving the subdir name from VERSION as we want to prevent
      # troubles when user reinstalls the newer version of Alien package
      my $share_subdir = $self->{properties}->{dist_version};
      if ($self->notes('is_devel_cvs_version')) {
        my ($sec,$min,$hour,$mday,$mon,$year,$wday,$yday,$isdst) = localtime(time);
        $share_subdir .= sprintf("_CVS_%02d%02d%02d_%02d%02d",$year+1900-2000,$mon+1,$mday,$hour,$min);
      }
      my $build_out = catfile('sharedir', $share_subdir);
      $self->add_to_cleanup($build_out);

      # store info into CofigData
      $self->config_data('iup_url', $self->notes('iup_url'));
      $self->config_data('im_url', $self->notes('im_url'));
      $self->config_data('cd_url', $self->notes('cd_url'));

      # prepare sources
      my $unpack;
      $unpack = (-d "$build_src/iup") && !$ENV{TRAVIS} ? $self->prompt("\nDir '$build_src/iup' exists, wanna replace with clean sources?", "n") : 'y';
      if (lc($unpack) eq 'y') {
        File::Path::rmtree("$build_src/iup") if -d "$build_src/iup";
        $self->prepare_sources($self->notes('iup_url'), $self->notes('iup_sha1'), $download, $build_src);
        if ($self->notes('iup_patches')) {
          $self->apply_patch("$build_src/iup", $_)  foreach (@{$self->notes('iup_patches')});
        }
      }

      $unpack = (-d "$build_src/im") && !$ENV{TRAVIS} ? $self->prompt("\nDir '$build_src/im'  exists, wanna replace with clean sources?", "n") : 'y';
      if (lc($unpack) eq 'y') {
        File::Path::rmtree("$build_src/im") if -d "$build_src/im";
        $self->prepare_sources($self->notes('im_url'), $self->notes('im_sha1'), $download, $build_src);
        if ($self->notes('im_patches')) {
          $self->apply_patch("$build_src/im", $_)  foreach (@{$self->notes('im_patches')});
        }
      }

      $unpack = (-d "$build_src/cd") && !$ENV{TRAVIS} ? $self->prompt("\nDir '$build_src/cd'  exists, wanna replace with clean sources?", "n") : 'y';
      if (lc($unpack) eq 'y') {
        File::Path::rmtree("$build_src/cd") if -d "$build_src/cd";
        $self->prepare_sources($self->notes('cd_url'), $self->notes('cd_sha1'), $download, $build_src);
        if ($self->notes('cd_patches')) {
          $self->apply_patch("$build_src/cd", $_)  foreach (@{$self->notes('cd_patches')});
        }
      }

      $unpack = (-d "$build_src/zlib") && !$ENV{TRAVIS} ? $self->prompt("\nDir '$build_src/zlib'  exists, wanna replace with clean sources?", "n") : 'y';
      if ($self->notes('zlib_url') && !$self->config_data('syszlib_lflags') && lc($unpack) eq 'y') {
        File::Path::rmtree("$build_src/zlib") if -d "$build_src/zlib";
        $self->prepare_sources($self->notes('zlib_url'), $self->notes('zlib_sha1'), $download, $build_src);
        if ($self->notes('zlib_patches')) {
          $self->apply_patch("$build_src/zlib", $_)  foreach (@{$self->notes('zlib_patches')});
        }
      }

      $unpack = (-d "$build_src/freetype") && !$ENV{TRAVIS} ? $self->prompt("\nDir '$build_src/freetype'  exists, wanna replace with clean sources?", "n") : 'y';
      if ($self->notes('freetype_url') && !$self->config_data('sysfreetype_lflags') && lc($unpack) eq 'y') {
        File::Path::rmtree("$build_src/freetype") if -d "$build_src/freetype";
        $self->prepare_sources($self->notes('freetype_url'), $self->notes('freetype_sha1'), $download, $build_src);
        if ($self->notes('freetype_patches')) {
          $self->apply_patch("$build_src/freetype", $_)  foreach (@{$self->notes('freetype_patches')});
        }
      }

      $unpack = (-d "$build_src/ftgl") && !$ENV{TRAVIS} ? $self->prompt("\nDir '$build_src/ftgl'  exists, wanna replace with clean sources?", "n") : 'y';
      if ($self->notes('ftgl_url') && lc($unpack) eq 'y') {
        File::Path::rmtree("$build_src/ftgl") if -d "$build_src/ftgl";
        $self->prepare_sources($self->notes('ftgl_url'), $self->notes('ftgl_sha1'), $download, $build_src);
        if ($self->notes('ftgl_patches')) {
          $self->apply_patch("$build_src/ftgl", $_)  foreach (@{$self->notes('ftgl_patches')});
        }
      }

      ### XXX hack for handling github tarballs
      unless (-d "$build_src/cd" && -d "$build_src/im" && -d "$build_src/iup") {
        for my $f (bsd_glob("$build_src/*")) {
          if ($f =~ m!^\Q$build_src\E/.*?(im|cd|iup).*$!) {
            print "renaming: $f $build_src/$1\n";
            rename ($f, "$build_src/$1");
          }
        }
      }

      # go for build
      my $success = $self->build_binaries($build_out, $build_src);
      my $done    = $self->config_data('info_done');
      my $iuplibs = $self->config_data('iup_libs');
      if ($self->notes('build_debug_info')) {
        print STDERR "Build result: $done->{$_} - $_\n" foreach (sort keys %$done);
        print STDERR "Output libs : $iuplibs->{$_} - $_\n" foreach (sort keys %$iuplibs);
      }
      die "###BUILD FAILED### essential libs (iup/im/cd) not built!" unless $done->{"iup:iup"} && $done->{"iup:iupim"} && $done->{"iup:iupcd"};
      die "###BUILD FAILED###" unless $success;
      #DEBUG: die intentionally at this point if you want to see build details from cpan testers
      print STDERR "RESULT: OK!\n";

      # store info about build to ConfigData
      $self->config_data('share_subdir', $share_subdir);
      $self->config_data('config', { PREFIX => '@PrEfIx@',
                                     LIBS   => '-L' . $self->quote_literal('@PrEfIx@/lib') .
                                               ' -l' . join(' -l', @{$self->config_data('linker_libs')}) .
                                               ' ' . $self->config_data('extra_lflags'),
                                     INC    => '-I' . $self->quote_literal('@PrEfIx@/include') .
                                               ' ' . $self->config_data('extra_cflags'),
                                   });
    }
    # mark sucessfully finished build
    $self->touchfile('build_done');
  }
  $self->SUPER::ACTION_code;
}

sub prepare_sources {
  my ($self, $url, $sha1, $download, $build_src) = @_;
  my $archive = $self->fetch_file( url=>$url, sha1=>$sha1, localdir=>$download );
  #XXX hack
  if ($archive !~ /\.(tar.gz|tgz|tar|zip|tbz|tar.bz2)$/) {
    rename($archive, "$archive.$$.tgz");
    $archive = "$archive.$$.tgz";
  }
  my $ae = Archive::Extract->new( archive => $archive );
  die "###ERROR### Cannot extract tarball ", $ae->error unless $ae->extract(to => $build_src);
}

sub fetch_file {
  my ($self, %args) = @_;

  my $url = $args{url};
  my $sha1 = $args{sha1};
  my $localdir = $args{localdir};
  my $localfile = $args{localfile};
  die "###ERROR### fetch_file: undefined url\n" unless $url;

  # create $localdir if necessary
  File::Path::mkpath($localdir) unless $localdir && -d $localdir;

  # handle redirects
  my $head = head($url);
  $url = $head->request->uri if defined $head;

  # download destination
  unless ($localfile) {
   $localfile = $url;
   $localfile =~ s/^.*?([^\\\/]+)$/$1/; #skip all but file part of URL
   $localfile =~ s/\?.*$//; #skip URL params
  }
  $localfile = File::Spec->catfile($localdir, $localfile) if $localdir;

  # check existing file
  if (-f $localfile) {
    if ($sha1) {
      if ($self->check_sha1sum($localfile, $sha1)) {
	return rel2abs($localfile);
      }
      else {
	warn "Checksum FAILURE";
      }
    }
    unlink $localfile; # if sha1 not given we force re-download
  }

  # download
  warn "Fetching '$url'...\n";
  my $rv = getstore($url, $localfile);
  die "###ERROR### fetch_file: download error - return code '$rv'\n" unless $rv == 200;
  die "###ERROR### fetch_file: download error - '$localfile' not saved\n" unless -f $localfile;

  # checksum
  if ($sha1) {
    die "###ERROR### fetch_file: checksum failed" unless $self->check_sha1sum($localfile, $sha1);
  }

  return rel2abs($localfile);
}

sub check_sha1sum {
  my ($self, $file, $sha1sum) = @_;
  return 1 if $sha1sum eq 'DO_NOT_CHECK_SHA1';
  warn "Checking checksum for '$file'...\n";
  my $sha1 = Digest::SHA->new;
  my $fh;
  open($fh, $file) or die "###ERROR## Cannot check checksum for '$file'\n";
  binmode($fh);
  $sha1->addfile($fh);
  close($fh);
  my $file_sha1sum = $sha1->hexdigest;
  my $rv = ($file_sha1sum eq $sha1sum) ? 1 : 0;
  warn "###WARN## sha1 mismatch: got      '", $file_sha1sum , "'\n",
       "###WARN## sha1 mismatch: expected '", $sha1sum, "'\n",
       "###WARN## sha1 mismatch: filesize ", (-s $file) unless $rv;
  return $rv;
}

sub build_binaries {
  die "###ERROR### My::Builder is not able to build, use rather My::Builder::<platform>";
}

sub quote_literal {
  # this needs to be overriden in My::Builder::<platform>
  my ($self, $path) = @_;
  return $path;
}

sub check_installed_lib {
  my ($self) = @_;

  #xxxTODO
  #we not only need to detect the presence we also need to exactly know what libs are there - necessary for havelib() function
  print STDERR "\nNOTICE:\nDetection of preinstalled iup+cd+im is disabled since v0.115!\nPlease contact the module author if you are missing this feature.\n\n";
  return 0;

  my $idir = $ENV{IUP_DIR} || '';
  my @candidates;
  push(@candidates, { L => "$idir/lib", I => "$idir/include" }) if -d $idir;
  push(@candidates, { L => '', I => '' });
  push(@candidates, { L => '', I => $Config{usrinc} }) if -d $Config{usrinc};
  push(@candidates, { L => '/usr/local/lib', I => '/usr/local/include' }) if -d '/usr/local/lib' && -d '/usr/local/include';
  push(@candidates, { L => '/usr/lib', I => '/usr/include' }) if -d '/usr/lib' && -d '/usr/include';

  print STDERR "Checking iup+im+cd already installed on your system ...\n";
  foreach my $i (@candidates) {
    my $lflags = $i->{L} ? '-L'.$self->quote_literal($i->{L}) : '';
    my $cflags = $i->{I} ? '-I'.$self->quote_literal($i->{I}) : '';
    #xxx does not work with MSVC compiler
    #xxx $lflags = ExtUtils::Liblist->ext($lflags) if($Config{make} =~ /nmake/ && $Config{cc} =~ /cl/); # MSVC compiler hack
    print STDERR "- testing: $cflags $lflags\n";
    my $rv1 = $self->check_header( [ 'iup.h', 'im.h', 'cd.h' ], $cflags);
    #xxx maybe we need to link with more libs
    if ($self->check_lib( [ 'iup', 'im', 'cd' ], $cflags, $lflags)){
      print STDERR "- iup+im+cd FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liup -lim -lcd", cflags => $cflags } );
      return 1;
    }
    elsif ($self->check_lib( [ 'iupwin', 'im', 'cdwin' ], $cflags, $lflags)) {
      print STDERR "- iupwin+im+cdwin FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liupwin -lim -lcdwin", cflags => $cflags } );
      return 1;
    }
    elsif ($self->check_lib( [ 'iupgtk', 'im', 'cdgdk' ], $cflags, $lflags)) {
      print STDERR "- iupgtk+im+cdgdk FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liupgtk -lim -lcdgdk", cflags => $cflags } );
      return 1;
    }
    elsif ($self->check_lib( [ 'iupmot', 'im', 'cdx11' ], $cflags, $lflags)) {
      print STDERR "- iupmot+im+cdx11 FOUND!\n";
      $self->notes('already_installed_lib', { lflags => "$lflags -liupmot -lim -lcdx11", cflags => $cflags } );
      return 1;
    }
  }
  print STDERR "- iup+im+cd not found (we have to build it from sources)!\n";
  return 0;
}

# check presence of header(s) specified as params
sub check_header {
  my ($self, $h, $cflags) = @_;
  $cflags ||= '';
  my @header = ref($h) ? @$h : ( $h );

  my ($fs, $src) = tempfile('tmpfileXXXXXX', SUFFIX => '.c', UNLINK => 1);
  my ($fo, $obj) = tempfile('tmpfileXXXXXX', SUFFIX => '.o', UNLINK => 1);
  my $inc = '';
  $inc .= "#include <$_>\n" foreach @header;
  syswrite($fs, <<MARKER); # write test source code
$inc
int demofunc(void) { return 0; }

MARKER
  close($fs);
  $src = $self->quote_literal($src);
  $obj = $self->quote_literal($obj);
  #Note: $Config{cc} might contain e.g. 'ccache cc' (FreeBSD 8.0)
  my $rv = run3("$Config{cc} -c -o $obj $src $cflags", \undef, \undef, \undef, { return_if_system_error => 1 } );
  return ($rv == 1 && $? == 0) ? 1 : 0;
}

# check presence of lib(s) specified as params
sub check_lib {
  my ($self, $l, $cflags, $lflags) = @_;
  $cflags ||= '';
  $lflags ||= '';
  $cflags =~ s/[\r\n]//g;
  $lflags =~ s/[\r\n]//g;
  my @libs = ref($l) ? @$l : ( $l );
  my $liblist = scalar(@libs) ? '-l' . join(' -l', @libs) : '';

  my ($fs, $src) = tempfile('tmpfileXXXXXX', SUFFIX => '.c', UNLINK => 1);
  my ($fo, $obj) = tempfile('tmpfileXXXXXX', SUFFIX => '.o', UNLINK => 1);
  my ($fe, $exe) = tempfile('tmpfileXXXXXX', SUFFIX => '.out', UNLINK => 1);
  syswrite($fs, <<MARKER); # write test source code
int main() { return 0; }

MARKER
  close($fs);
  $src = $self->quote_literal($src);
  $obj = $self->quote_literal($obj);
  $exe = $self->quote_literal($exe);
  my $output;
  #Note: $Config{cc} might contain e.g. 'ccache cc' (FreeBSD 8.0)
  my $rv1 = run3("$Config{cc} -c -o $obj $src $cflags", \undef, \$output, \$output, { return_if_system_error => 1 } );
  unless ($rv1 == 1 && $? == 0) {
    #print STDERR "OUTPUT(compile):\n$output\n" if $output;
    return 0
  }
  my $rv2 = run3("$Config{ld} $obj -o $exe $lflags $liblist", \undef, \$output, \$output, { return_if_system_error => 1 } );
  unless ($rv2 == 1 && $? == 0) {
    #print STDERR "OUTPUT(link):\n$output\n" if $output;
    return 0
  }
  return 1;
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

    if (open(SRC, $k)) {
      $src  = <SRC>;
      close(SRC);
      $src =~ s/\r\n/\n/g; #normalise newlines
    }
    else {
      $src = '';
    }

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

sub run_output_tail {
  my ($self, $limit, @cmd) = @_;
  my $output;
  print STDERR "CMD: " . join(' ',@cmd) . "\n";
  print STDERR "- running (stdout+stderr redirected)...\n";
  my $rv = run3(\@cmd, \undef, \$output, \$output, { return_if_system_error => 1 } );
  my $success = ($rv == 1 && $? == 0) ? 1 : 0;
  $output = substr $output, -$limit if defined $limit; # we want just last N chars
  if (!defined($limit)) {
    print STDERR "OUTPUT:\n", $output, "\n";
  }
  elsif ($limit>0) {
    print STDERR "OUTPUT: (only last $limit chars)\n", $output, "\n";
  }
  return $success;
}

sub run_output_on_error {
  my ($self, $limit, @cmd) = @_;
  my $output;
  print STDERR "CMD: " . join(' ',@cmd) . "\n";
  print STDERR "- running (stdout+stderr redirected)...\n";
  my $rv = run3(\@cmd, \undef, \$output, \$output, { return_if_system_error => 1 } );
  my $success = ($rv == 1 && $? == 0) ? 1 : 0;
  if ($success) {
    print STDERR "- finished successfully (output suppressed)\n";
  }
  else {
    $output = substr $output, -$limit if defined $limit; # we want just last N chars
    if (!defined($limit)) {
      print STDERR "OUTPUT:\n", $output, "\n";
    }
    elsif ($limit>0) {
      print STDERR "OUTPUT: (only last $limit chars)\n", $output, "\n";
    }
  }
  return $success;
}

sub run_output_std {
  my ($self, @cmd) = @_;
  print STDERR "CMD: " . join(' ',@cmd) . "\n";
  my $rv = run3(\@cmd, undef, undef, undef, { return_if_system_error => 1 } );
  my $success = ($rv == 1 && $? == 0) ? 1 : 0;
  print STDERR "- finished successfully\n" if ($success);
  return $success;
}

sub run_stdout2str {
  my ($self, @cmd) = @_;
  my $output;
  my $rv = run3(\@cmd, \undef, \$output, \undef, { return_if_system_error => 1 } );
  $output =~ s/[\r\n]*$//;
  return $output;
}

sub run_bothout2str {
  my ($self, @cmd) = @_;
  my $output;
  my $rv = run3(\@cmd, \undef, \$output, \$output, { return_if_system_error => 1 } );
  $output =~ s/[\r\n]*$//;
  return $output;
}

sub run_custom {
  my ($self, @cmd) = @_;
  my $rv;
  if ($self->notes('build_msgs')) {
    $rv = $self->run_output_std(@cmd);
  }
  else {
    $rv = $self->run_output_on_error($self->notes('build_msgs_limit'), @cmd);
  }
  warn "###WARN### error during run_custom()" unless $rv;
  return $rv;
}

sub find_file {
  my ($self, $dir, $re) = @_;
  my @files;
  $re ||= qr/.*/;
  {
    no warnings 'File::Find'; #hide warning "Can't opendir(...): Permission denied
    find({ wanted => sub { push @files, rel2abs($_) if /$re/ }, follow => 1, no_chdir => 1 , follow_skip => 2}, $dir);
  };
  return @files;
}

sub sort_libs {
  my ($self, @unsorted) = @_;
  my @wanted_order = qw/iupcontrols iup_pplot iup_plot iupcd iupgl iupglcontrols iup_mglplot iupim iupimglib iupole iupweb iuptuio iupwin iupmot iupgtk iup cdgl cdpdf cdwin cdx11 cdgdk cd ftgl freetype6 freetype freetype-6 pdflib im_fftw im_jp2 im_process im/;
  my @sorted;
  my %u;

  for (my $i=0; $i<scalar(@unsorted); $i++) {
    $u{$unsorted[$i]} = $i;
  }
  for (@wanted_order) {
    if (defined $u{$_}) {
      push(@sorted, $_);
      $unsorted[$u{$_}] = undef;
    }
  }
  for (@unsorted) {
    push(@sorted, $_) if defined $_;
  }

  return @sorted;
}

sub touchfile {
  my $self = shift;
  my $t    = time;
  foreach my $file (@_) {
    open(FILE,">>$file") || die "Cannot write $file:$!";
    close(FILE);
    utime($t,$t,$file);
  }
}

sub detect_sys_libs {
  die;
};

sub pkg_config {
  my ($self, $pkc, $nul) = @_;
  if ($nul && $pkc && `$pkc --version 2>$nul`) {
    warn "Checking system libraries zlib, freetype2\n";
    (my $syszlib_ver        = `$pkc zlib --modversion 2>$nul`     ) =~ s/\s*$//;
    (my $syszlib_lflags     = `$pkc zlib --libs 2>$nul`           ) =~ s/\s*$//;
    (my $syszlib_cflags     = `$pkc zlib --cflags 2>$nul`         ) =~ s/\s*$//;
    (my $sysfreetype_ver    = `$pkc freetype2 --modversion 2>$nul`) =~ s/\s*$//;
    (my $sysfreetype_lflags = `$pkc freetype2 --libs 2>$nul`      ) =~ s/\s*$//;
    (my $sysfreetype_cflags = `$pkc freetype2 --cflags 2>$nul`    ) =~ s/\s*$//;
    $self->config_data('syszlib_ver',        $syszlib_ver       );
    $self->config_data('syszlib_lflags',     $syszlib_lflags    );
    $self->config_data('syszlib_cflags',     $syszlib_cflags    );
    $self->config_data('sysfreetype_ver',    $sysfreetype_ver   );
    $self->config_data('sysfreetype_lflags', $sysfreetype_lflags);
    $self->config_data('sysfreetype_cflags', $sysfreetype_cflags);
    warn "FOUND: zlib-$syszlib_ver LF=$syszlib_lflags\n"             if $syszlib_lflags;
    warn "FOUND: freetype-$sysfreetype_ver LF=$sysfreetype_lflags\n" if $sysfreetype_lflags;
  }
};

1;
