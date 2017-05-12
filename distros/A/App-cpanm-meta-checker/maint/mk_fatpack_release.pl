#!/usr/bin/env perl
# ABSTRACT: Create a stripped fatpack library

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
inbuild {
  withlib {
    STDERR->print("Packing...\n");

    my $file = capture_stdout {
      system( 'fatpack', 'file', $last->child('bin/cpanm-meta-checker') );
    };
    $cwd->child('bin/cpanm-meta-checker.fatpack')->spew_raw($file);
  };
};

