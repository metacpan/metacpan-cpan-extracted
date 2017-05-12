# $Id$
#
# Cared for by Juguang Xiao, juguang@tll.org.sg
#
# Copyright Juguang Xiao 
#
# You may distribute this script under the same terms as perl itself

#
# Note that the functionality of using the SAX event handler for
# parsing InterPro should by now be integrated into the main
# load_ontology.pl script. Let me know if that doesn't work for you
# for some reason.
#
# I'll leave this script here around for a while until there is enough
# evidence that it all works through load_ontology.pl as well, so don't be
# confused.
#
# -Hilmar, hlapp at gmx.net
#
use strict;
use Bio::OntologyIO::Handlers::InterPro_BioSQL_Handler;
use XML::Parser::PerlSAX;
use Bio::DB::EasyArgv;
use Getopt::Long;


my $db = get_biosql_db_from_argv;
my ($file, $version);
GetOptions(
    'file=s' => \$file,
    'version=s' => \$version
);

my $handler = Bio::OntologyIO::Handlers::InterPro_BioSQL_Handler->new(
    -db => $db,
    -version => "version $version"
);
my $parser = XML::Parser::PerlSAX->new(Handler=>$handler);
my $ret = $parser->parse(Source=>{SystemId=>$file});
