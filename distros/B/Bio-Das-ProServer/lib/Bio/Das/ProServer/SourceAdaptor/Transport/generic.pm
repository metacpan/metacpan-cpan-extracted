#########
# Author:        rmp
# Maintainer:    $Author: zerojinx $
# Created:       2003-05-22
# Last Modified: $Date: 2010-11-02 11:37:11 +0000 (Tue, 02 Nov 2010) $
# Source:        $Source $
# Id:            $Id $
# $HeadURL: https://proserver.svn.sourceforge.net/svnroot/proserver/trunk/lib/Bio/Das/ProServer/SourceAdaptor/Transport/generic.pm $
#
package Bio::Das::ProServer::SourceAdaptor::Transport::generic;
use strict;
use warnings;

our $VERSION  = do { my ($v) = (q$Revision: 687 $ =~ /\d+/mxsg); $v; };

sub new {
  my ($class, $defs) = @_;
  my $self = {
              'dsn'       => $defs->{'dsn'}    || 'unknown',
              'config'    => $defs->{'config'} || {},
              'debug'     => $defs->{'debug'},
             };
  bless $self, $class;

  $self->init_time(time);
  $self->init();

  return $self;
}

sub init_time {
  my ($self, $time) = @_;
  if (defined $time) {
    $self->{'init_time'} = $time;
  }
  return $self->{'init_time'};
}

sub init {return;}

sub config {
  my $self = shift;
  return $self->{'config'};
}

sub query {return;}

1;
__END__

=head1 NAME

Bio::Das::ProServer::SourceAdaptor::Transport::generic - A generic transport layer for deriving others from

=head1 VERSION

$Revision: 687 $

=head1 SYNOPSIS

=head1 DESCRIPTION

=head1 SUBROUTINES/METHODS

=head2 new - base-class object constructor

  my $transport = Bio::Das::ProServer::SourceAdaptor::Transport::<impl>->new({
    'dsn'    => 'my-dsn-name',   # useful for hydras
    'config' => $config->{$dsn}, # subsection of config file for this adaptor holding this transport
  });

=head2 init_time - get/set the time() this transport was initialised/reset

  my $iInitTime = $oTransport->init_time();
  $oTransport->init_time($iInitTime);

=head2 init - Post-constructor initialisation hook

  By default does nothing - override in subclasses if necessary

=head2 config - Handle on config file (given at construction)

  my $cfg = $transport->config();

=head2 query - Execute a query against this transport

  Unimplemented in base-class. You almost always want to override this

  my $resultref = $transport->query(...);

=head1 DIAGNOSTICS

=head1 CONFIGURATION AND ENVIRONMENT

=head1 DEPENDENCIES

=head1 INCOMPATIBILITIES

=head1 BUGS AND LIMITATIONS

=head1 AUTHOR

Roger Pettett <rmp@sanger.ac.uk>.

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2007 The Sanger Institute

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.  See DISCLAIMER.txt for
disclaimers of warranty.


=cut
