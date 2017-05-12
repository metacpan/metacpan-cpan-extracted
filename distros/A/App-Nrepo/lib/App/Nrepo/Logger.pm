#!/bin/false
use strict;
use warnings;

package App::Nrepo::Logger;

our $VERSION = '0.1'; # VERSION

my $logger;

sub load {
  die "Already loaded!\n" if $logger;
  my $package = shift;
  $logger = shift;
  return 1;
}

sub new {
  return $logger;
}

1;

__END__

=head1 NAME

 App::Nrepo::Logger

=head1 SYNOPSIS

In bin/yourapp.pl

 use App::Nrepo::Logger;
 # do stuff
 App::Nrepo::Logger->load($logobject);

Then in your lib/YourApp/Base.pm

 use Moo;
 use App::Nrepo::Logger;

 has 'logger' => (
     default => sub { App::Nrepo::Logger->new() },
     );

=head1 METHODS

=head2 load($obj)

Saves $obj for later

=head2 new()

Returns $obj every time

