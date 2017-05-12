use strict;
use warnings;
use ExtUtils::MakeMaker;
use Config;
use Cwd;
use File::Copy;
use File::Path;
use File::Find;
use File::Basename;
require 5.006001;

my ($ans, @src_files);

my $prereq = {'Geo::IP' => '1.27'};
my ($libdir, $files_to_clean) = mp_copy();

push @$files_to_clean, 't/TEST';

my $name = ($libdir eq 'Apache') ? 'Apache::GeoIP' : 'Apache2::GeoIP';

my $eu_version = $ExtUtils::MakeMaker::VERSION;
my %opts = (
              NAME           => $name,
              DISTNAME       => 'Apache-GeoIP',
	      VERSION_FROM   => "$libdir/GeoIP.pm",
              PREREQ_PM      => $prereq,
	      ($] >= 5.005 ?    
               (ABSTRACT   => 'Look up country by IP address',
                AUTHOR     => 'Randy Kobes <r.kobes@uwinnipeg.ca>') 
	       : ()),
	      clean          => { FILES => "@$files_to_clean"},
              ($eu_version >= 6.11 ?
                (NO_META     => 1,)
                : ()),
	      dist           => {
				 SUFFIX   => 'gz',
				 COMPRESS => 'gzip -9f',
				},
           );

require Apache::TestMM;
import Apache::TestMM qw(test clean);
Apache::TestMM::filter_args();
Apache::TestMM::generate_script('t/TEST');

eval {require ModPerl::MM;};
if ($@) {
  WriteMakefile(%opts);
}
else {
  ModPerl::MM::WriteMakefile(%opts);
}

#######################################################################
# The following routine assumes the existence of two subdirectories:
#   Apache: for mod_perl-1 things
#   Apache2: for mod_perl-2 things
# which_modperl() is called to determine which of the two
# directories to use, depending on availability of
# mod_perl and/or user input. The files under the
# chosen directory are then copied under the lib/ directory
# for subsequent installation. If there is a t/ directory
# under either Apache/ or Apache2/, the files under
# this directory are copied beneath the top-level t/.
#
# The routine returns a list containing two items - which
# of the directories (Apache or Apache2) is used, and also
# an array reference of files copied to the lib/ or t/ directories
#
########################################################################

sub mp_copy {
  my $ans;
  my $apache_dir = which_modperl();

  @src_files = ();
  my @dest_files = ();
  finddepth(\&wanted, $apache_dir);

  foreach my $src (@src_files) {
    my $dir = dirname($src);
    my $dest_dir;
    if ($dir =~ m!/t/?(.*)!) {
      $dest_dir = "t/$1";
    }
    else {
      $dest_dir = 'lib/' . $dir;
    }
    unless (-d $dest_dir) {
      mkpath($dest_dir, 1, 0755) or die "mkpath $dest_dir failed: $!";
    }
    my $base = basename($src);
    my $dest_file = $dest_dir . '/' . $base;
    push @dest_files, $dest_file;
    my $key = $src;
    copy($src, $dest_file) or die "Cannot copy $src to $dest_file: $!";
  }
  return ($apache_dir, \@dest_files);
}

sub wanted {
  my $name = $File::Find::name;
  not (-d $_ or $name =~ m!CVS|svn!i) and push @src_files, $name; 
}

sub which_modperl {
  my $ans;
  eval {require mod_perl2;};
  unless ($@) {
    $ans = prompt('Install mod_perl-2 version?', 'yes');
    return 'Apache2' if ($ans =~ /^y/);
  }
  eval {require Apache::src;};
  unless ($@) {
    $ans = prompt('Install mod_perl-1 version?', 'yes');
    return 'Apache' if ($ans =~ /^y/);
  }
  warn qq{Please install either mod_perl 1 or mod_perl 2 first};
  exit 0;
}
