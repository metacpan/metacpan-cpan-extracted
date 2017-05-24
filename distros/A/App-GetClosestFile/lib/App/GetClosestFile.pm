package App::GetClosestFile;

use strict;
use warnings;
use File::stat;
use Cwd;

# ABSTRACT: get full path matches for filename regexes in diretory trees

our $VERSION;

BEGIN {
    $VERSION = '0.2.3';
}

my $filename;
my @child_dirs = ();
my $show_all_matches = 0;
my $line_breaks = 0;
my $recursion_depth = 0;
my $current_depth = 0;
my $root;

foreach my $index (0 .. $#ARGV) {
  my $arg = $ARGV[$index];

  if ($arg eq '--all') {
    $show_all_matches = 1;
  } elsif ($arg eq '--break') {
    $line_breaks = 1;
  } elsif ($arg eq '--help') {
    usage();
  } elsif ($arg eq '--depth') {
    $recursion_depth = $ARGV[$index + 1];
  } else {
    $filename = $arg;
  }
}

if (!$filename) {
  usage();
}

sub usage {
  print "\ngetclosest [options] filename

    options:

      --all       show all matches
      --break     print results on separate lines
      --depth N   recursion depth
      --help      show this message
      
Version $VERSION.\n\n";

  exit;
}

sub count_depth {
  my $output = 0;

  if ($root) {
    my $path = shift;
    $path = $path =~ s/$root\///r;
    my @parts = split '', $path;

    for (@parts) {
      if ($_ eq '/') {
        $output++;
      }
    }
  }

  return $output;
}

sub read_dir {
  my $dir;
  my $dirname = shift;

  $current_depth = count_depth $dirname;

  if ($recursion_depth > 0) {
    if ($current_depth > $recursion_depth) {
      return;
    }
  }

  opendir($dir, $dirname) or die;

  my @files = readdir($dir);

  foreach my $file (@files) {
    if ($file eq "." or $file eq "..") {
      next;
    }

    stat($dirname . "/" . $file);

    if (-d _) {
      push @child_dirs, $dirname . "/" . $file;
    } else {
      if ($file =~ /$filename/) {
        print $dirname . "/" . $file;

        if ($show_all_matches == 1) {
          if ($line_breaks) {
            print "\n";
          } else {
            print " ";
          }
        } else {
          exit;
        }
      }
    }
  }
}

sub run {
  $root = getcwd;
  read_dir($root, 1);

  while (my $size = @child_dirs > 0) {
    my $dir = shift @child_dirs;
    read_dir($dir);
  }
}

1;
