# -*- mode: cperl; mode: follow; -*-
#

package App::Regather::Plugin::list;

=head1 NAME

list - prints all available commands with short descriptions

=cut

use strict;
use warnings;
use diagnostics;

use Carp;
use Pod::Usage;

=head1 METHODS

=head2 new

Creates new object .

=cut

sub new {
  my $class = shift;
  my @classpath = split(/::/, $class);
  pop @classpath;
  bless { classpath => \@classpath }, $class
}

=head2 run

Lists available commands on the stdout.  For each command an attempt is
made to load it, to ensure the module is usable.  If so, its description
is extracted from the NAME section of its pod.

=cut

sub run {
  my $self = shift;
  print "\nAvailable plugins are:\n";
  my %names = App::Regather::Plugin->names;
  my ($s, @res);
  while ( my ($k, $v) = each %names ) {

    open(my $fh, '>', \$s);
    pod2usage(-input      => $v,
	      -output     => $fh,
	      -verbose    => 99,
	      -sections   => ['NAME'],
	      -exitstatus => 'NOEXIT');
    close $fh;
    my (undef,$descr) = split("\n", $s||'');
    $descr = '    ' . $k unless ($descr);
    push @res, "$descr, App::Regather::Plugin::$k(3)\n";

  }

  print $_ foreach (sort @res);
}

######################################################################

1;

