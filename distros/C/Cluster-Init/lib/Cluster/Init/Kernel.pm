package Cluster::Init::Kernel;
use strict;
use warnings;
use Data::Dump qw(dump);
use Carp::Assert;
use Cluster::Init::DB;
use Cluster::Init::Util qw(debug);
use base qw(Cluster::Init::Util);

our $db;

sub db
{
  $db = Cluster::Init::DB->new unless $db;
  return $db;
}

1;
