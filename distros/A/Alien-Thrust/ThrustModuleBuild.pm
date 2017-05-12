package ThrustModuleBuild;

use strict;

use File::Spec::Functions qw(splitpath);
use IO::File;
use IO::Uncompress::Unzip qw($UnzipError);
use File::Path qw(mkpath);

use parent 'Module::Build';


my $thrust_version = '0.7.6';
my $thrust_archive = 'thrust.zip';


sub ACTION_build {
  my $self = shift;

  $self->download_zip_file();

  $self->extract_zip_file();

  $self->SUPER::ACTION_build;
}



sub ACTION_install {
  my $self = shift;

  if ($^O =~ /darwin/i) {
    ## ExtUtils::Install appears to break ThrustShell.App - maybe doesn't copy some meta-data or something?

    $self->depends_on('build'); ## So that the parent class ACTION_install won't invoke it again

    print "WARNING: Due to Mac OS X lameness, we are removing the thrust shell binaries from the blib directory before install. You will have to to re-build if you want to use this local blib.\n";

    system("rm -rf blib/lib/auto/share/dist/Alien-Thrust/");

    $self->SUPER::ACTION_install;

    my $share_install_dir = $self->install_map->{'blib/lib'} . "/auto/share/dist/Alien-Thrust/";

    system('mkdir', '-p', $share_install_dir);
    system('unzip', '-oqq', $thrust_archive, '-d', $share_install_dir);
  } else {
    $self->SUPER::ACTION_install;
  }
}



sub download_zip_file {
  my $self = shift;

  my ($os, $arch);

  if ($^O =~ /linux/i) {
    $os = 'linux';
    $arch = length(pack("P", 0)) == 8 ? 'x64' : 'ia32';

    if ($arch eq 'ia32') {
      die "32bit linux is not supported";
    }

  } elsif ($^O =~ /darwin/i) {
    $os = 'darwin';
    $arch = 'x64';
  } elsif ($^O =~ /mswin/i) {
    $os = 'win32';
    $arch = 'ia32';

    die "windows is not yet supported, see https://github.com/hoytech/Thrust/issues/1  (but we think we're close)";
  } else {
    die "Your platform is currently not supported by Thrust";
  }

  my $thrust_zipfile_url = "https://github.com/breach/thrust/releases/download/v$thrust_version/thrust-v$thrust_version-$os-$arch.zip";

  if (-e $thrust_archive) {
    print "$thrust_archive already exists, skipping download\n";
  } else {
    print "Downloading $thrust_zipfile_url (be patient)\n";

    if (system(qw/wget -c -O/, "$thrust_archive.partial", $thrust_zipfile_url)) {
      if (-e "$thrust_archive.partial") {
        ## wget started the download but probably user hit control-c
        die "download failed, aborting";
      }

      print "unable to run wget, trying LWP::UserAgent\n";

      unlink("$thrust_archive.partial");
      require LWP::UserAgent;

      my $ua = new LWP::UserAgent;
      my $res = $ua->get($thrust_zipfile_url, ':content_file' => "$thrust_archive.partial");

      if (!$res->is_success) {
        die "Failed to download $thrust_zipfile_url : " . $res->status_line;
      }
    }

    rename("$thrust_archive.partial", $thrust_archive) || die "unable to rename $thrust_archive.partial to $thrust_archive ($!)";
  }
}



sub extract_zip_file {
  my $self = shift;

  system("mkdir -p blib/lib/auto/share/dist/Alien-Thrust/"); ## FIXME: portability

  if ($^O =~ /darwin/i) {
    ## Archive::Extract appears to break ThrustShell.App - maybe doesn't extract some meta-data or something?
    system("unzip -oqq $thrust_archive -d blib/lib/auto/share/dist/Alien-Thrust/");
  } else {
    unzip($thrust_archive, 'blib/lib/auto/share/dist/Alien-Thrust/');
    chmod(0755, 'blib/lib/auto/share/dist/Alien-Thrust/thrust_shell');
  }
}




## The following unzip() routine is by Daniel S. Sterling (from https://gist.github.com/eqhmcow/5389877)
## "licensed under GPL 2 and/or Artistic license; aka free perl software"

=pod

IO::Uncompress::Unzip works great to process zip files; but, it doesn't include a routine to actually
extract an entire zip file.

Other modules like Archive::Zip include their own unzip routines, which aren't as robust as IO::Uncompress::Unzip;
eg. they don't work on zip64 archive files.

So, the following is code to actually use IO::Uncompress::Unzip to extract a zip file.

=cut

=head2 unzip

Extract a zip file, using IO::Uncompress::Unzip.

Arguments: file to extract, destination path

    unzip('stuff.zip', '/tmp/unzipped');

=cut

sub unzip {
    my ($file, $dest) = @_;

    die 'Need a file argument' unless defined $file;
    $dest = "." unless defined $dest;

    my $u = IO::Uncompress::Unzip->new($file)
        or die "Cannot open $file: $UnzipError";

    my $status;
    for ($status = 1; $status > 0; $status = $u->nextStream()) {
        my $header = $u->getHeaderInfo();
        my (undef, $path, $name) = splitpath($header->{Name});
        my $destdir = "$dest/$path";

        unless (-d $destdir) {
            mkpath($destdir) or die "Couldn't mkdir $destdir: $!";
        }

        if ($name =~ m!/$!) {
            last if $status < 0;
            next;
        }

        my $destfile = "$dest/$path/$name";
        my $buff;
        my $fh = IO::File->new($destfile, "w")
            or die "Couldn't write to $destfile: $!";
        while (($status = $u->read($buff)) > 0) {
            $fh->write($buff);
        }
        $fh->close();
        my $stored_time = $header->{'Time'};
        utime ($stored_time, $stored_time, $destfile)
            or die "Couldn't touch $destfile: $!";
    }

    die "Error processing $file: $!\n"
        if $status < 0 ;

    return;
}


1;
