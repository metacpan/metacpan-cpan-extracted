#***********************************************************************
#
# AFS.pm - AFS extensions for Perl
#
#  RCS-Id: @(#)$Id: Monitor.pm,v 1.5 2007/05/14 18:24:17 alfw Exp $
#
# Copyright (c) 2003, International Business Machines Corporation and others.
#
# This software has been released under the terms of the IBM Public
# License.  For details, see the IBM-LICENSE file in the LICENCES
# directory or online at http://www.openafs.org/dl/license10.html
#
# Contributors
#         2004-2006: Elizabeth Cassell <e_a_c@mailsnare.net>
#                    Alf Wachsmann <alfw@slac.stanford.edu>
#
# The code for the original library were mainly taken from the AFS
# source distribution, which comes with this message:
#
#    Copyright (C) 1989-1994 Transarc Corporation - All rights reserved
#    P_R_P_Q_# (C) COPYRIGHT IBM CORPORATION 1987, 1988, 1989
#
#**********************************************************************

package AFS::Monitor;

use Carp;

require Exporter;
require AutoLoader;
require DynaLoader;

use vars qw(@ISA $VERSION);

@ISA = qw(Exporter AutoLoader DynaLoader);

$VERSION = "0.3.2";

@EXPORT = qw (
              afsmonitor
              rxdebug
              udebug
              cmdebug
              scout
              xstat_fs_test
              xstat_cm_test
             );


# Other items we are prepared to export if requested
@EXPORT_OK = qw(
                error_message
		constant
               );

sub rxdebug {
  my %subreq;

  # parse the arguments and build a hash to pass to the XS do_rxdebug call.
  return eval {
    while (@_) {
      $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my $rxd = do_rxdebug(\%subreq);
    return $rxd;
  }
}

sub afsmonitor {
  my %subreq;

  return eval {
    while (@_) {
      $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my ($fs, $cm) = do_afsmonitor(\%subreq);
    return ($fs, $cm);
  }
}

sub cmdebug {
  my %subreq;

  return eval {
    while (@_) {
     $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my ($locks, $cache_entries) = do_cmdebug(\%subreq);
    return ($locks, $cache_entries);
  }
}

sub udebug {
  my %subreq;

  return eval {
    while (@_) {
     $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my $result = do_udebug(\%subreq);
    return $result;
  }
}

sub scout {
  my %subreq;

  return eval {
    while (@_) {
     $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my $result = do_scout(\%subreq);
    return $result;
  }
}

sub xstat_fs_test {
  my %subreq;

  return eval {
    while (@_) {
     $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my $result = do_xstat_fs_test(\%subreq);
    return $result;
  }
}

sub xstat_cm_test {
  my %subreq;

  return eval {
    while (@_) {
     $_ = shift;

      if ( @_ and $_[0] !~ /^-/ ) {
        $subreq{$_} = shift;
      }
      else {
        $subreq{$_} = 1;
      }
    }
    my $result = do_xstat_cm_test(\%subreq);
    return $result;
  }
}



sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.
    # taken from perl v5.005_02 for backward compatibility

    my $constname;

    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
	if ($! =~ /Invalid/ || $!{EINVAL}) {
	    $AutoLoader::AUTOLOAD = $AUTOLOAD;
	    goto &AutoLoader::AUTOLOAD;
	}
	else {
	    croak "Your vendor has not defined AFS macro $constname";
	}
    }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
	if ($] >= 5.00561) {
	    *$AUTOLOAD = sub () { $val };
	}
	else {
	    *$AUTOLOAD = sub { $val };
	}
    }
    goto &$AUTOLOAD;
}

bootstrap AFS::Monitor $VERSION;

# Preloaded methods go here.  Autoload methods go after __END__, and are
# processed by the autosplit program.

1;
__END__

