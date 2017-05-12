# -*- mode: cperl; tab-width: 8; indent-tabs-mode: nil; basic-offset: 2 -*-
# vim:ts=8:sw=2:et:sta:sts=2
#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2006-10-31
# Last Modified: $Date: 2015-09-21 10:19:13 +0100 (Mon, 21 Sep 2015) $
# Source:        $Source: /cvsroot/clearpress/clearpress/lib/ClearPress/util.pm,v $
# Id:            $Id: util.pm 470 2015-09-21 09:19:13Z zerojinx $
# $HeadURL: svn+ssh://zerojinx@svn.code.sf.net/p/clearpress/code/trunk/lib/ClearPress/util.pm $
#
package ClearPress::util;
use strict;
use warnings;
use base qw(Class::Accessor);
use Config::IniFiles;
use Carp;
use POSIX qw(strftime);
use English qw(-no_match_vars);
use ClearPress::driver;
use CGI;
use IO::Capture::Stderr;

our $VERSION = q[475.3.3];
our $DEFAULT_TRANSACTIONS = 1;
our $DEFAULT_DRIVER       = 'mysql';
my  $INSTANCES = {};

__PACKAGE__->mk_accessors(qw(transactions username requestor profiler session));

sub new {
  my ($class, $ref) = @_;

  my $self = {};

  if(exists $INSTANCES->{$class}) {
    $self = $INSTANCES->{$class};
  }

  if($ref && ref $ref eq 'HASH') {
    while(my ($k, $v) = each %{$ref}) {
      $self->{$k} = $v;
    }
  }

  if(!exists $self->{transactions}) {
    $self->{transactions} = $DEFAULT_TRANSACTIONS;
  }

  $INSTANCES->{$class} = bless $self, $class;

  return $INSTANCES->{$class};
}

sub cgi {
  my ($self, $cgi) = @_;

  if($cgi) {
    $self->{cgi} = $cgi;
  }

  if(!$self->{cgi}) {
    $self->{cgi} = CGI->new();
  }

  return $self->{cgi};
}

sub data_path {
  return q(data);
}

sub configpath {
  my ($self, @args) = @_;

  if(scalar @args) {
    $self->{configpath} = shift @args;
  }

  return $self->{configpath} || $self->data_path().'/config.ini';
}

sub dbsection {
  return $ENV{dev} || 'live';
}

sub config {
  my $self       = shift;
  my $configpath = $self->configpath() || q();
  my $dtconfigpath;

  if(!$self->{config}) {
    ($dtconfigpath) = $configpath =~ m{([[:lower:][:digit:]_/.\-]+)}smix;
    $dtconfigpath ||= q();

    if($dtconfigpath ne $configpath) {
      croak qq(Failed to detaint configpath: '$configpath');
    }

    if(!-e $dtconfigpath) {
      croak qq(No such file: $dtconfigpath);
    }

    $self->{config} ||= Config::IniFiles->new(
					       -file => $dtconfigpath,
					      );
  }

  if(!$self->{config}) {
    croak qq(No configuration available:\n). join q(, ), @Config::IniFiles::errors; ## no critic (Variables::ProhibitPackageVars)
  }

  return $self->{config};
}

sub dbh {
  my $self = shift;

  return $self->driver->dbh();
}

sub quote {
  my ($self, $str) = @_;
  return $self->dbh->quote($str);
}

sub driver {
  my ($self, @args) = @_;

  if(!$self->{driver}) {
    my $dbsection = $self->dbsection();
    my $config    = $self->config();

    if(!$dbsection || !$config->SectionExists($dbsection)) {
      croak q[Unable to determine config set to use. Try adding [live] [dev] or [test] sections to config.ini];
    }

    my $drivername = $config->val($dbsection, 'driver') || $DEFAULT_DRIVER;
    my $ref        = {};

    for my $field (qw(dbname dbhost dbport dbuser dbpass)) {
      $ref->{$field} = $self->$field()
    }

    $self->{driver} = ClearPress::driver->new_driver($drivername, $ref);
  }

  return $self->{driver};
}

sub log { ## no critic (homonym)
  my ($self, @args) = @_;
  print {*STDERR} map { (strftime '[%Y-%m-%dT%H:%M:%S] ', localtime). "$_\n" } @args or croak $ERRNO;
  return 1;
}

sub cleanup {
  my $self = shift;

  #########
  # cleanup() is called by controller at the end of a request:response
  # cycle. Here we neutralise the singleton instance so it doesn't
  # carry over any stateful information to the next request - CGI,
  # DBH, TT and anything else cached in data members.
  #
  my $class = ref $self || $self;

  delete $INSTANCES->{$class};

  if(exists $self->{dbh}) {
    $self->{dbh}->disconnect();
  }

  return 1;
}

sub db_credentials {
  my $self      = shift;
  my $cfg       = $self->config();
  my $dbsection = $self->dbsection();
  my $ref       = {};

  for my $field (qw(dbuser dbpass dbhost dbport dbname)) {
    $ref->{$field} = $cfg->val($dbsection, $field);
  }

  return $ref;
}

sub dbname {
  my $self = shift;
  return $self->db_credentials->{dbname};
}

sub dbuser {
  my $self = shift;
  return $self->db_credentials->{dbuser};
}

sub dbpass {
  my $self = shift;
  return $self->db_credentials->{dbpass};
}

sub dbhost {
  my $self = shift;
  return $self->db_credentials->{dbhost};
}

sub dbport {
  my $self = shift;
  return $self->db_credentials->{dbport};
}

END {
  # dereferences and causes orderly destruction of all instances
  my $cap = IO::Capture::Stderr->new();
  $cap->start;
  undef $INSTANCES;
  $cap->stop;
  while(my $line = $cap->read()) {
    if($line =~ /MySQL[ ]server[ ]has[ ]gone[ ]away/smix) { # brute force do not display these copious, noisy warnings
      next;
    }

    print {*STDERR} $line or croak qq[Error printing: $ERRNO];
  }
}

1;

__END__

=head1 NAME

ClearPress::util - A database handle and utility object

=head1 VERSION

$Revision: 470 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - Constructor

  my $oUtil = ClearPress::util->new({
                              'configpath' => '/path/to/config.ini', # Optional
                             });

=head2 data_path - Accessor to data directory containing config.ini and template subdir

  my $sPath = $oUtil->data_path();

=head2 configpath - Get/set accessor for path to config file

  $oUtil->configpath('/path/to/configfile/');

  my $sConfigPath = $oUtil->configpath();

=head2 config - The Config::IniFiles object for our configpath

  my $oConfig = $oUtil->config();

=head2 driver - driver name from config.ini

  my $sDriverName = $oUtil->driver();

=head2 dbsection - dev/test/live/application based on $ENV{dev}

  my $sSection = $oUtil->dbsection();

=head2 dbh - A database handle for the supported database

  my $oDbh = $oUtil->dbh();

=head2 quote - Shortcut for $oDbh->quote('...');

  my $sQuoted = $oUtil->quote($sUnquoted);

=head2 transactions - Enable/disable transaction commits

 Example: A cascade of object saving

  $util->transactions(0);                       # disable transactions

  for my $subthing (@{$thing->subthings()}) {   # cascade object saves (without commits)
    $subthing->save();
  }

  $util->transactions(1);                       # re-enable transactions
  $thing->save();                               # save parent object (with commit)

=head2 username - Get/set accessor for requestor's username

  $oUtil->username((getpwuid $<)[0]);
  $oUtil->username($sw->username());

  my $sUsername = $oUtil->username();

=head2 cgi - Placeholder for a CGI object (or at least something with the same param() interface)

  $oUtil->cgi($oCGI);
  my $oCGI = $oUtil->cgi();

=head2 session - Placeholder for a session hashref

  $oUtil->session($hrSession);
  my $hrSession = $oUtil->session();

=head2 profiler - Placeholder for a Website::Utilities::Profiler object

  $oUtil->profiler($oProfiler);
  my $oProf = $oUtil->profiler();

=head2 requestor - a ClearPress::model::user who requested this page (constructed by view.pm)

  This is usually used for testing group membership for authorisation checks

  my $oRequestingUser = $oUtil->requestor();

=head2 log - Formatted debugging output to STDERR

  $oUtil->log(@aMessages);

=head2 cleanup - housekeeping stub for subclasses - called when response has completed processing

  $oUtil->cleanup();

=head2 db_credentials - hashref of database connection info from the current dbsection

  my $hrDBHInfo = $oUtil->db_credentials();

=head2 dbname - database name from db_credentials

  my $sDBName = $oUtil->dbname();

=head2 dbuser - database user from db_credentials

  my $sDBUser = $oUtil->dbuser();

=head2 dbpass - database pass from db_credentials

  my $sDBPass = $oUtil->dbpass();

=head2 dbhost - database host from db_credentials

  my $sDBHost = $oUtil->dbhost();

=head2 dbport - database port from db_credentials

  my $sDBPort = $oUtil->dbport();

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=over

=item strict

=item warnings

=item DBI

=item Config::IniFiles

=item Carp

=item POSIX

=item English

=back

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett, E<lt>rpettett@cpan.orgE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (C) 2008 Roger Pettett

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.4 or,
at your option, any later version of Perl 5 you may have available.

=cut
