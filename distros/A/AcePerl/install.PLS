#!perl
use Config;
use File::Basename qw(&basename &dirname);
use Cwd;
                                                                                                  $origdir = cwd;
chdir dirname($0);
$file = basename($0, '.PLS');
$file .= $^O eq 'VMS' ? '.com' : '.pls';

open OUT,">$file" or die "Can't create $file: $!";

print "Extracting $file (with variable substitutions)\n";

print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!

# In the following, perl variables are not expanded during extraction.

print OUT <<'!NO!SUBS!';

use strict;
use File::Copy 'cp';
use IO::Dir;

my $source = shift;
my $dest   = shift;

die "$source is not a directory" unless -d $source;
die "$dest is not a directory"   unless -d $dest;

copy_tree($source,'.',$dest);

sub copy_tree {
  my ($base,$subdir,$dest) = @_;

  my $dir = IO::Dir->new("$base/$subdir") or die "Can't opendir() $source: $!";
  while (my $thing = $dir->read) {

    next if $thing =~ /^./;    # not hidden files
    next if $thing =~ /^\#/;   # not autosave files
    next if $thing =~ /~$/;    # not autosave files
    next if $thing eq 'CVS';   # not CVS directories
    next if $thing eq 'core';  # not core files

    if (-f "$base/$subdir/$thing") { # a regular file
      my $result = copy("$base/$subdir/$thing","$dest/$subdir/$thing");
      print STDERR "$base/$subdir/$thing => $dest/$subdir/$thing: ",$result ? "OK\n" : "FAILED: $!\n";
    } elsif (-d "$base/$subdir/$thing") {
      copy_tree($base,"$subdir/$thing",$dest);
    }

  }
}

__END__
!NO!SUBS!
close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";
exec("$Config{'eunicefix'} $file") if $Config{'eunicefix'} ne ':';
chdir $origdir;
