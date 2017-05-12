#!/usr/bin/env perl
# ABSTRACT: Create a stripped fatpack library in-place from release

use strict;
use warnings;
use utf8;

use Path::Tiny qw(path);
use Capture::Tiny qw( capture_stdout );
use FindBin;
my $cwd    = path('.')->absolute;
my $root   = path($FindBin::Bin)->parent->absolute;
my ($last) = $root;
print "Making fatlib using $last\n";

sub withlib(&) {
  my ($code) = @_;
  my $oldopts = $ENV{PERL5OPT} || '';
  my @oldlib = split /:/, $ENV{PERL5LIB} || '';

  #    local $ENV{PERL5OPT} = "$oldopts -I${last}/lib";
  local $ENV{PERL5LIB} = join q[:], $last->child('lib'), @oldlib;

  #STDERR->print("\e[31mPERL5OPT=$ENV{PERL5OPT}\e[0m\n");
  return $code->();
}

sub inbuild(&) {
  my ($code) = @_;
  chdir $last;
  $code->();
  chdir $cwd;
}

STDERR->print("Stripping...\n");

for my $wd (qw( fatlib lib )) {

  my $iterator = $last->child($wd)->iterator( { recurse => 1 } );

  while ( my $it = $iterator->() ) {
    next if -d $it;
    if ( $it->basename =~ /.so\z/ ) {
      warn "Found .so file $it\n";
      next;
    }
    print "$it\n";
    system( 'perlstrip', $it );
  }
}

