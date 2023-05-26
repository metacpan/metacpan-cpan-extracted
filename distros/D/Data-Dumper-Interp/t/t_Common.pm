# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights to the content of this file.
# Attribution is requested but is not required.

# Common setup stuff, not specifically for test cases.
# This file is intended to be identical in all my module distributions.

package t_Common;

sub hash2str($) { my $h=shift; join("",map{" ${_}=>".($h->{$_}//"u")} sort keys %$h) }
my ($default_warnbits, $default_pragmas);
BEGIN {
  $default_warnbits = ${^WARNING_BITS}//"u";
  $default_pragmas = ($^H//"u").":".hash2str(\%^H);
}

use strict; use warnings  FATAL => 'all'; use feature qw/say state/;

require Exporter;
use parent 'Exporter';
our @EXPORT = qw/oops mytempfile mytempdir/;
our @EXPORT_OK = ();

use Import::Into;
use Carp;

sub oops(@) { @_=("oops! ",@_); goto &Carp::confess }

sub import {
  my $target = caller;

  state $imported_previously;
  unless ($imported_previously++) {
    # It seems like test cases using Test::More are re-started from
    # the beginning when Test::More is first loaded, and at that point
    # some non-default pragma is in effect.  I can't figure any other
    # reason why we would be imported twice, with non-default settings
    # the 2nd time.
    
    # Check that the user did not already say "no warnings ..." or somesuch
    # I was confused about how to this before, 
    # see https://rt.cpan.org/Ticket/Display.html?id=147618
    my $users_warnbits = ${^WARNING_BITS}//"u";
    my $users_pragmas = ($^H//"u").":".hash2str(\%^H);
    carp "Detected 'use/no warnings/strict' done before importing ",
          __PACKAGE__, "\n(they might be un-done)\n"
      if ($users_pragmas ne $default_pragmas 
            || $users_warnbits ne $default_warnbits);
  }
  strict->import::into($target);
  #warnings->import::into($target);
  warnings->import::into($target, FATAL => 'all'); # blowing up a test is ok

  #use 5.010;  # say, state
  use 5.011;  # cpantester gets warning that 5.11 is the minimum acceptable
  use 5.018;  # lexical_subs
  require feature;
  feature->import::into($target, qw/state say current_sub lexical_subs/);
  warnings->unimport::out_of($target, "experimental::lexical_subs");

  # die if obsolete or dangerous syntax is used
  require indirect;
  indirect->unimport::out_of($target);

  require multidimensional;
  multidimensional->unimport::out_of($target);

  require autovivification;
  # A bug makes
  #   "no autovivification warn anything..." wrongly flag
  #   "my %hash; delete $hash{nonexistentkey}"
  # This happens with Perl 5.24.0 and autovivification v0.18
  # but not with Perl5.34.0 and same autovivification.
  # So just disable autoviv but don't enable warnings...
  autovivification->unimport::out_of($target, qw/fetch store exists delete/);

  # Avoid regex performance penalty in Perl <= 5.18 if
  # $PREMATCH $MATCH or $POSTMATCH are imported (fixed in perl 5.20).
  require English;
  English->import::into($target, '-no_match_vars' );

  # Stuff I often use

  require utf8;
  utf8->import::into($target);

  require Carp;
  Carp->import::into($target);

  require File::Basename;
  File::Basename->import::into($target, qw/basename dirname/);

  # NO. use mytempfile or mytempdir
  #require File::Temp;
  #File::Temp->import::into($target, qw/tempfile tempdir/);

  require File::Path;
  File::Path->import::into($target, qw/make_path rmtree/);

  require File::Spec;
  require File::Spec::Functions;
  File::Spec::Functions->import::into($target, qw/
    canonpath catdir catfile curdir rootdir updir
    no_upwards file_name_is_absolute devnull tmpdir splitpath splitdir 
    abs2rel rel2abs case_tolerant/);

  require List::Util;
  List::Util->import::into($target, qw/reduce min max first any all none sum0/);



  require Scalar::Util;
  Scalar::Util->import::into($target, qw/blessed reftype looks_like_number 
                                         weaken isweak refaddr/);

  require Cwd;
  Cwd->import::into($target, qw/getcwd abs_path fastgetcwd fast_abs_path/);

  require Guard;
  Guard->import::into($target, qw(scope_guard guard));

  unless (Cwd::abs_path(__FILE__) =~ /Data-Dumper-Interp/) { 
    # unless we are testing this
    require Data::Dumper::Interp;
    Data::Dumper::Interp->import::into($target);
    $Data::Dumper::Interp::Useqq = 'unicode'; # omit 'controlpic' to get \t etc.
  }

  # chain to Exporter to export any other importable items
  goto &Exporter::import
}

use File::Temp 0.23 ();

# These wrappers provide sane defaults:
#   TMPDIR set and the appropriate clean-up option enabled.
# In addition, if a single "template" argument is a full filename including
# suffix (i.e. does not end in ...XXX), then it is split into separate
# TEMPLATE and SUFFIX arguments for File::Temp
sub _process_tfargs(@) {
  return @_ if (scalar(@_) % 2 == 0); # already key => value, ....
  (local $_, my @rest) = @_;
  if (s/X([^X]+)$/X/) { unshift @rest, SUFFIX => $1; }
  (TEMPLATE => $_, @rest)
}
sub mytempfile {
  my @tfargs = _process_tfargs(@_);
  File::Temp::tempfile(
    TMPDIR => File::Spec->tmpdir(),
    UNLINK  =>  1,
    @tfargs
  )
}
sub mytempdir {
  my @tfargs = _process_tfargs(@_);
  File::Temp::tempdir(
    TMPDIR => File::Spec->tmpdir(),
    CLEANUP =>  1,
    @tfargs
  )
}
# prevent direct use of File::Temp by exporting these conflicting stubs
# ?? Maybe just name our wrappers without the "my" and let them be imported explicitly?
sub tempfile { confess "call mytempfile instead" }
sub tempdir  { confess "call mytempdir instead" }

1;
