package CFDI::Parser::Path;

use strict;
use File::Spec;
use Cwd;
require Exporter;
our @EXPORT = qw(findxml);
our @ISA = qw(Exporter);
our $VERSION = 0.3;

sub findxml(_){
  die 'path not defined' unless defined $_[0];
  die "cannot read path $_[0]" unless -e $_[0] && -r _;
  die "path $_[0] is not a directory" unless -d _;
  my ($wd,@paths,@xml) = (getcwd,$_[0]);
  while(@paths){
    my $path = shift @paths;
    next unless -e $path && -r _ && -d _;
    opendir DIR,$path or next;
    chdir $path or next;
    foreach(grep !/^\./,readdir DIR){
      next unless -e && -r _;
      if(-d _){
        push @paths,File::Spec->catdir($path,$_);
      }elsif(/\.xml$/i){
        push @xml,File::Spec->catfile($path,$_);
      }
    }
    chdir $wd;
    closedir DIR;
  }
  @xml;
}

1;