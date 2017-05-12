#!/usr/local/bin/perl -w
use strict;

use Getopt::Long;
use FileHandle;
use DBIx::DBStag;
use Bio::Chaos;

my $expanded;
my $out;
my $macros;
my ($db,$user,$pass);
my $srctype;
GetOptions(
	   "db|d=s"=>\$db,
	   "user|u=s"=>\$user,
	   "pass|p=s"=>\$pass,
           "out|o=s"=>\$out,
           "srctype=s"=>\$srctype,
	   "help|h"=>sub {
	       system("perldoc $0"); exit 0;
	   }
	  );

my $dbh;
if ($db) {
    $dbh = 
      DBIx::DBStag->connect($db, $user, $pass);
}

my $chaos = Bio::Chaos->new;
my $where = shift @ARGV;
$chaos->fetch_from_chado($dbh,$where);
print $chaos->root->xml;

exit 0;

__END__

=head1 NAME 

  cx-query-chado.pl

=head1 SYNOPSIS

  cx-query-chado.pl -d chado 

=head1 DESCRIPTION


=head1 ARGUMENTS


=back 


=cut


