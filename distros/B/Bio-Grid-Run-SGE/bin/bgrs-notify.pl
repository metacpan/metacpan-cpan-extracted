#!/usr/bin/env perl
# created on 2014-06-25

use warnings;
use strict;
use 5.010;
use Data::Dumper;

use Bio::Grid::Run::SGE::Log::Notify::Jabber;
use Bio::Grid::Run::SGE::Config;
use Getopt::Long;
use Proc::Daemon;

my %opt = ();
GetOptions( \%opt, 'daemonize|d', 'process|p=i', 'verbose|v' ) or die "option parsing error";

if ( $opt{daemonize} ) {
  Proc::Daemon::Init;
}

if ( $opt{process} ) {
  while ( kill( 0, $opt{process} ) ) {
    sleep 1;
  }
}

my $msg = shift // 'Wollte nur mal Hallo sagen!';
say STDERR $msg if ( $opt{verbose} );

if ( $msg eq '-' ) {
  $msg = do { local $/; <STDIN> };
}

my $attempts = 3;
my $c        = Bio::Grid::Run::SGE::Config->new->config;

$c->{notify}{jabber} = [ $c->{notify}{jabber} ] unless ( ref $c->{notify}{jabber} );
for my $jid ( @{ $c->{notify}{jabber} } ) {

  my $n = Bio::Grid::Run::SGE::Log::Notify::Jabber->new($jid);

  for ( my $i = 0; $i < $attempts; $i++ ) {
    last unless ( $n->notify( { message => $msg, from => "jobbot" } ) );
  }
}
