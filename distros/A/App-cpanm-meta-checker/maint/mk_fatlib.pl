#!/usr/bin/env perl
# FILENAME: mk_fatlib.pl
# CREATED: 03/09/14 06:16:17 by Kent Fredric (kentnl) <kentfredric@gmail.com>
# ABSTRACT: Create a stripped fatpack library

use strict;
use warnings;
use utf8;

use Path::Tiny qw(path);
use Capture::Tiny qw( capture_stdout );
use FindBin;
my $cwd             = path('.')->absolute;
my $root            = path($FindBin::Bin)->parent->absolute;
my @buildcandidates = grep { $_->is_dir }
  grep { $_->basename =~ /\AApp-cpanm-meta-checker-/ } $root->children;

if ( not @buildcandidates ) {
  die "No build candidates";
}
my ($last) =
  [ sort { $b->stat->mtime <=> $a->stat->mtime } @buildcandidates ]->[0];
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
    STDERR->print("Tracing module load...\n");
    system( 'fatpack', 'trace', 'bin/cpanm-meta-checker' ) == 0 or die;
  };
};

my (@modules) =
  path($last)->child('fatpacker.trace')->lines_raw( { chomp => 1 } );
my $packlists;
STDERR->print("Generating packlist list...\n");
inbuild {
  withlib {
    $packlists = capture_stdout {
      system( 'fatpack', 'packlists-for', @modules );
    };
  };
};
STDERR->print("Generating fatlib...\n");
$cwd->child('fatlib')->remove_tree();

system( 'fatpack', 'tree', split /\n/, $packlists );
my $it = $cwd->child('fatlib')->iterator( { recurse => 1 } );

while ( my $item = $it->() ) {
  next unless $item->basename =~ /.so\z/;
  STDERR->print("Stripping $item as it is a .so\n");
  unlink $item;
}
