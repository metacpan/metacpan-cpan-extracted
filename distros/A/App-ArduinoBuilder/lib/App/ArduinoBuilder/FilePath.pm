package App::ArduinoBuilder::FilePath;

use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Logger;
use App::ArduinoBuilder::System 'system_canonpath';
use Exporter 'import';
use File::Find;
use File::Spec::Functions 'catdir';
use List::Util 'min', 'any';

our @EXPORT_OK = qw(find_latest_revision_dir list_sub_directories find_all_files_with_extensions);

sub _compare_version_string {
  my @la = split /\.|-/, $a;
  my @lb = split /\.|-/, $b;
  for my $i (0..min($#la, $#lb)) {
    # Let’s try to handle things like: 1.5.0-b
    my $c = $la[$i] <=> $lb[$i] || $la[$i] cmp $lb[$i];
    return $c if $c;
  }
  return $#la <=> $#lb;
}

sub  _pick_highest_version_string {
  return (sort _compare_version_string @_)[-1];
}

# find_latest_revision('/path/to/dir') --> '/path/to/dir/9.8.2'
# Returns the input if there are no sub-directories looking like revisions in
# the given directory.
sub find_latest_revision_dir {
  my ($dir) = @_;
  opendir my $dh, $dir or fatal "Can’t open dir '$dir': $!";
  my @revs_dir = grep { -d catdir($dir, $_) && m/^\d+(?:\.\d+)?(?:-.*)?/ } readdir($dh);
  closedir $dh;
  return $dir unless @revs_dir;
  return catdir($dir, _pick_highest_version_string(@revs_dir));
}

sub list_sub_directories {
  my ($dir) = @_;
  opendir my $dh, $dir or fatal "Can’t open dir '$dir': $!";
  my @sub_dirs = grep { -d catdir($dir, $_) && ! m/^\./ } readdir($dh);
  closedir $dh;
  return @sub_dirs;
}

# $dir can be a single directory to search or an array ref.
# excluded_dirs must be an array_ref
sub find_all_files_with_extensions {
  my ($dir, $exts, $excluded_dirs, $no_recurse) = @_;
  my $exts_re = join('|', @{$exts});
  my @excluded_dirs = map { system_canonpath($_) } @{$excluded_dirs // []};
  my @found;
  my @dirs = ref $dir ? @{$dir} : $dir;
  for my $d (@dirs) {
    find(sub { push @found, $File::Find::name if -f && m/\.(?:$exts_re)$/;
               if (-d) {
                 # $_ eq '.' only on the first, root directly that we are crawling.
                 if ($no_recurse && $_ ne '.') {
                   $File::Find::prune = 1;
                   return;
                 } elsif (/^\..+/) {
                   $File::Find::prune = 1;
                   return;
                 }
                 my $a = system_canonpath($_);
                 $File::Find::prune = any { $_ eq $a } @excluded_dirs;
               }
             }, $d);
  }
  return @found;
}

1;
