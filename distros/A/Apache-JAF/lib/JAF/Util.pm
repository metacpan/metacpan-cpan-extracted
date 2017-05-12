package JAF::Util;

use strict;
use File::Path ();
use File::Basename ();
use DirHandle ();

### Content

sub trim {
  my $s = shift;
  $s =~ s/^\s+//s;
  $s =~ s/\s+$//s;
  return $s;
}

sub urlify {
  my $urls = '(http|telnet|gopher|file|wais|ftp)';
  my $ltrs = '\w';
  my $gunk = '/#~:.?+=&%@!\-';
  my $punc = '.:?\-';
  my $any  = "${ltrs}${gunk}${punc}";

  my @result = ();
  my @data = @_;

  while ($_ = shift @data) {
    s{
      \b                    # start at word boundary
      (                     # begin $1  {
       $urls     :          # need resource and a colon
       [$any] +?            # followed by on or more
                            #  of any valid character, but
                            #  be conservative and take only
                            #  what you need to....
      )                     # end   $1  }
      (?=                   # look-ahead non-consumptive assertion
       [$punc]*             # either 0 or more punctuation
       [^$any]              #   followed by a non-url char
       |                    # or else
       $                    #   then end of the string
      )
     }{<a target="_blank" href="$1">$1</a>}igox;
    push @result, $_;
  }
  return wantarray ? @result : $result[0];
}

### System

sub mkdir {
  my ($path, $root, $subst) = @_;
  return unless $path;
  if ($root) {
    my @dirs = split '/', $root;
    $dirs[-1] = $subst if $subst;
    $root = join '/', @dirs;
  }
  $path = $root . $path if $root;
  File::Path::mkpath($path) unless -d $path;
  return $path;
}

sub unlink_with_path {
  my $filename = shift;
  my (@files, $rm);

  if(-f $filename) {
    $rm = File::Basename::dirname($filename);
    unlink($filename);
  } elsif(-d $filename) {
    $rm = $filename;
  } else {
    return "Neither a file nor a directory!";
  }

  while (!@files && $rm) {
    opendir DIR, $rm;
    @files = grep !/^\.\.?$/, readdir(DIR);
    closedir DIR;
    unless (@files) {
      rmdir $rm;
      $rm =~ s/\/([^\/]+)$//g;
    }
  }
  return $!;
}

### Date

sub current_date {
  my ($day, $month, $year) = (localtime)[3..5];
  $month++;
  $year += 1900;
  return wantarray ? ($day, $month, $year) : sprintf "%d.%02d.%04d", ($day, $month, $year);
}

1;
