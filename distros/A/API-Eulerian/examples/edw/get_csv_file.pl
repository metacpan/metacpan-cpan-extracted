###############################################################################
#
# @file Rest.pl
#
# @brief Example of Eulerian Data Warehouse Peer performing an Analysis using
#        Rest Protocol.
#
# @author Thorillon Xavier:x.thorillon@eulerian.com
#
# @date 25/11/2021
#
# @version 1.0
#
###############################################################################

use strict;

use lib qw( ./lib );

use File::Slurp();
use Pod::Usage();
use Getopt::Long();
use HTTP::Tiny();

use API::Eulerian::EDW();

my ($grid,$ip,$token,$help,$site,$query) = ('','','','','',0);

Getopt::Long::GetOptions(
  "grid=s"    => \$grid,
  "ip=s"      => \$ip,
  "token=s"   => \$token,
  "site=s"    => \$site,
  "query=s"   => \$query,
  "help|?"    => \$help
);
Pod::Usage::pod2usage(1) if ( $help );

my %h_setup = (
  grid      => $grid,
  ip        => $ip,
  token     => $token,
  site      => $site,
  query     => $query
);

# get local IP
if ( !defined $h_setup{ip} || !length $h_setup{ip} ) {
  my $response = HTTP::Tiny->new->get('http://monip.org/');
  unless ( $response->{success} ) {
    print STDERR "\tunable to reach external network to get IP address.\n";
    exit(1);
  }
  ($h_setup{ip}) = ($response->{content} =~ /IP\s:\s(\d+\.\d+\.\d+\.\d+)/gm);
}

foreach my $p ( qw/ grid ip token site query / ) {
  if ( !defined $h_setup{$p} || !length $h_setup{$p} ) {
    print STDERR "\tmissing $p parameter, check help.\n";
    exit(1);
  }
}
delete $h_setup{$_} for ( qw/ site query / );

# get query to send
my $qfile = './examples/edw/sql/'.$query.'.sql';
if ( !-e $qfile ) {
  print STDERR "\trequested query $query does not exists.\n";
  exit(1);
}
my $date_from = time() - 24 * 3600;
my $date_to = time();

my $cmd = File::Slurp::slurp($qfile);
$cmd =~ s/\[% SITE %\]/$site/gm;
$cmd =~ s/\[% DATE_FROM %\]/$date_from/gm;
$cmd =~ s/\[% DATE_TO %\]/$date_to/gm;


#
# Create a user specific Hook used to handle Analysis replies.
#

my $edw = new API::Eulerian::EDW();
my $rh_ret = $edw->get_csv_file( \%h_setup, $cmd );

use Data::Dumper;
print Dumper($rh_ret);

1;
__END__

=head1 NAME

 get_csv_file.pl - Sample EDW script for querying through REST and get a CSV file

=head1 SYNOPSIS

 Rest.pl [optinos]

 Options :
  -help brief help message

=head1 OPTIONS

=over 8

=item B<-help>

 Print a brief help message and exists

=item B<--grid>

 Name of the grid on which your data is hosted.

=item B<--ip>

 The IP from which the call is going to be made and that will reach the EDW server.
 If not provided, will try to guess it through an external call.

=item B<--token>

 Authorization token provided through the Eulerian interface for accessing the Eulerian API.

=item B<--site>

 Name of the site as shown in the Eulerian Interface.

=item B<--query>

 Name of the query to send, needs to exist in examples/edw/sql/*.sql

=back

=head1 DESCRIPTION

 Query the EDW with the REST API.

=cut
