# License: Public Domain or CC0
# See https://creativecommons.org/publicdomain/zero/1.0/
# The author, Jim Avera (jim.avera at gmail) has waived all copyright and
# related or neighboring rights to the content of this file.
# Attribution is requested but is not required.

# Common setup and tools for tests. It always:
#   Provides (using import::into) strict, warnings, and various packages.
#   Provides Test::More.
#   Makes UTF-8 encode/decode the default for all file handles
#
# If @ARGV contains -d etc. those options are removed from @ARGV
# and the corresponding globals are set: $debug, $verbose, $silent.

# This file is identical in all my module distributions.

package t_Common;

sub hash2str($) {
  my $href = shift;
  join("",map{" ${_}=>".($href->{$_}//"u")} sort keys %$href)
}
my $default_pragmas = ($^H//"u").":".hash2str(\%^H);
my $default_warnbits = ${^WARNING_BITS}//"u";

use strict; use warnings  FATAL => 'all'; use feature qw/say state/;

require Exporter;
use parent 'Exporter';
our @EXPORT = qw/oops/;
our @EXPORT_OK = qw/$debug $silent $verbose/;

use Import::Into;
use Carp;

sub oops(@) { @_=("oops! ",@_); goto &Carp::confess }

# Do an initial read of $[ so arybase will be autoloaded
# (prevents corrupting $!/ERRNO in subsequent tests)
eval '$[' // die;

sub import {
  my $target = caller;

  state $initialized;
  unless ($initialized++) {
    # It seems like test cases using Test::More are re-started from
    # the beginning when Test::More is first loaded, and at that point
    # some non-default pragma is in effect.  So skip this check if
    # we come here a 2nd time.
    
    # Check that the user did not already say "no warnings ..." or somesuch
    # which we would override.
    my $level = 0; # ++$level while defined(caller($level+1));
    my $callers_pragmas = 
           ((caller($level))[8]//"u").":".hash2str((caller($level))[10]//{});
    my $callers_warnbits = (caller($level))[9]//"u";

#use Data::Dumper::Interp;
#warn dvis '##III $default_pragmas $default_warnbits\n      $callers_pragmas $callers_warnbits\n';
#warn "(pragmas changed)\n" if $callers_pragmas ne $default_pragmas;
#warn "(warnbits changed)\n" if $callers_warnbits ne $default_warnbits;
#
    carp "Detected 'use/no warnings/strict' done before importing ",
          __PACKAGE__, "\n(they might be un-done)\n"
      if ($callers_pragmas ne $default_pragmas 
            || $callers_warnbits ne $default_warnbits);
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
  autovivification->unimport::out_of($target,
                warn => qw/fetch store exists delete/);

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

  require File::Temp;
  File::Temp->import::into($target, qw/tempfile tempdir/);

  require File::Path;
  File::Path->import::into($target, qw/make_path rmtree/);

  require File::Spec;

  require List::Util;
  List::Util->import::into($target, qw/reduce min max first any all none sum0/);



  require Scalar::Util;
  Scalar::Util->import::into($target, qw/blessed reftype looks_like_number 
                                         weaken isweak refaddr/);

  require Cwd;
  Cwd->import::into($target, qw/getcwd abs_path/);

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

1;
