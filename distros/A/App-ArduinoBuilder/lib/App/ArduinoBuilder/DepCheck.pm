package App::ArduinoBuilder::DepCheck;

use strict;
use warnings;
use utf8;

use App::ArduinoBuilder::Logger;
use Exporter 'import';
use File::Basename;
use File::Spec::Functions;

our @EXPORT_OK = qw(check_dep);

# Returns true if the target needs to be rebuilt.
sub check_dep {
  my ($source, $target) = @_;
  fatal "Can’t find source file: ${source}" unless -f $source;
  my $mtime = -M _;  # Note: this is negated mtime due to a weird Perl quirk.
  return 1 unless -f $target;
  # In some error situation a 0 byte .o file is written, let’s assume that a valid output is
  # never empty (which would not be true in the general case for a build system).
  return 1 if -z _;
  return 1 if $mtime < -M _;


  my $d_file = catfile(dirname($target), basename($source).'.d');
  unless (-f $d_file) {
    warning "Dependency file does not exist: ${d_file}";
    return 0;  # We assume that there is no other dependency.
  }
  return 1 if $mtime < -M _;

  open my $fh, '<', $d_file or fatal "Can’t open dependency file '${d_file}': $!";
  my $l = <$fh>;
  if ($l !~ m/\s*(.*?)\s*:\s*(.*?)?\s*\\?/) {
    error "Can’t parse dependency file: ${d_file}";
    return 1;
  }
  # we could test that rel2abs($1) eq rel2abs($target)
  return 1 if $2 && $mtime < -M $2;

  while (my $l = <$fh>) {
    if ($l !~ m/\s*(.*?)?\s*\\?/) {
      error "Can’t parse dependency file: ${d_file}";
      return 1;
    }
    return 1 if $1 && $mtime < -M $1;
  }
  close $fh;
  return 0;
}

1;
