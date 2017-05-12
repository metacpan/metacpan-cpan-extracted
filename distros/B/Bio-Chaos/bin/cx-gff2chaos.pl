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
foreach my $file (@ARGV) {
    $chaos->parse($file,'gff3');
    $chaos->add_srcfeatures($srctype) if $srctype;
    print $chaos->root->xml;
}

exit 0;

__END__

=head1 NAME 

  cx-chaos2chadoxml.pl

=head1 SYNOPSIS

  cx-chaos2chadoxml.pl CG10833.chaos-xml > CG10833.with-macros.chaos-xml
  cx-chaos2chadoxml.pl -x CG10833.chaos-xml > CG10833.expanded.chaos-xml

=head1 DESCRIPTION

Converts Chaos-XML to Chado-XML

Note that there are different "flavours" of Chado-XML. This includes
both macro-ified and un-macroified flavours. This script will handle both

As a first step, the chaos-xml is converted to chado-xml; this
chado-xml uses some macros.

As an optional second step, the macros are expanded to their full form
(this is required for input to some programs, eg apollo)


Both steps happen via the use of XSL Stylesheet Transforms

=head1 ARGUMENTS

=over

=item -x 

Expand all macros to full form

=item -m 

Create macros

=back 


=Head1 REQUIREMENTS

You need an XSLT Processor, such as xsltproc, available as part of libxslt

=cut


