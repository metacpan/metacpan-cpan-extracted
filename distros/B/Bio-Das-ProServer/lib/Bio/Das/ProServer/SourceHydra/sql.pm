#########
# Author:        Andy Jenkinson
# Maintainer:    $Author: zerojinx $
# Created:       2008-05-03
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Id:            $Id: sql.pm 687 2010-11-02 11:37:11Z zerojinx $
# Source:        $Source: $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceHydra/sql.pm $
#
# DBI-driven sourceadaptor broker
#
package Bio::Das::ProServer::SourceHydra::sql;
use strict;
use warnings;
use English qw(-no_match_vars);
use Carp;
use base qw(Bio::Das::ProServer::SourceHydra::dbi);
use Readonly;

our $VERSION       = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };
Readonly::Scalar our $CACHE_TIMEOUT => 30;

#########
# the purpose of this module:
#
sub sources {
  my ($self)    = @_;
  my $hydraname = $self->{'dsn'};
  my $sql       = $self->config->{'query'};
  my $now       = time;

  #########
  # flush the table cache *at most* once every $CACHE_TIMEOUT
  # This may need signal triggering to have immediate support
  #
  if($now > ($self->{'_sourcecache_timestamp'} || 0)+$CACHE_TIMEOUT) {
    $self->{'debug'} and carp qq(Flushing table-cache for $hydraname);
    delete $self->{'_sources'};
    $self->{'_sourcecache_timestamp'} = $now;
  }

  # Use the configured query to find the names of the sources
  if(!exists $self->{'_sources'}) {
    $self->{'_sources'} = [];
    eval {
      $self->{'debug'} and carp qq(Fetching sources using query: $sql);
      $self->{'_sources'} = [map { $_->[0] } @{$self->transport()->dbh()->selectall_arrayref($sql)}];
      $self->{'debug'} and carp qq(@{[scalar @{$self->{'_sources'}}]} sources found);
      1;

    } or do {
      carp "Error scanning database: $EVAL_ERROR";
      delete $self->{'_sources'};
    };
  }

  return @{$self->{'_sources'} || []};
}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceHydra::sql - A database-backed implementation of B::D::P::SourceHydra

=head1 VERSION

$Revision: 687 $

=head1 AUTHOR

Andy Jenkinson <andy.jenkinson@ebi.ac.uk>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2008 EMBL-EBI

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.

=head1 DESCRIPTION

Extension of the 'dbi' hydra to allow the use of custom SQL queries to determine
the available source names.

=head1 SYNOPSIS

  my $sqlHydra = Bio::Das::ProServer::SourceHydra::sql->new( ... );
  my @sources  = $dbiHydra->sources();

=head1 SUBROUTINES/METHODS

=head2 sources : DBI sources

  Runs a preconfigured SQL statement, with the first column of each row of the
  results being the name of a DAS source.

  my @sources = $sqlhydra->sources();

  The SQL query comes from $self->config->{'query'};

  This routine caches results for $CACHE_TIMEOUT seconds.

=head1 DIAGNOSTICS

Run ProServer with the -debug flag.

=head1 CONFIGURATION AND ENVIRONMENT

  [mysimplehydra]
  adaptor   = simpledb           # SourceAdaptor to clone
  hydra     = sql                # Hydra implementation to use
  transport = dbi
  query     = select sourcename from meta_table
  dbname    = proserver
  dbhost    = mysql.example.com
  dbuser    = proserverro
  dbpass    = topsecret

=head1 DEPENDENCIES

Bio::Das::ProServer::SourceHydra::dbi

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=cut
