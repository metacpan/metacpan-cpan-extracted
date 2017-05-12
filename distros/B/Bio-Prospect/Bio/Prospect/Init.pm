=head1 NAME

 Bio::Prospect::Init -- initialization parameters for Bio::Prospect::
 $Id: Init.pm,v 1.11 2003/11/18 21:04:19 rkh Exp $

=head1 SYNOPSIS

=head1 DESCRIPTION

B<Bio::Prospect::Init> contains initialization parameters for the entire
Bio::Prospect:: package.

=head1 ROUTINES & METHODS

=cut


package Bio::Prospect::Init;

use warnings;
use strict;

use vars qw( $VERSION );
$VERSION = sprintf( "%d.%02d", q$Revision: 1.11 $ =~ /(\d+)\.(\d+)/ );


# PROSPECT_PATH - location of prospect installation, used by LocalClient
$Bio::Prospect::Init::PROSPECT_PATH = '/apps/compbio/i686-linux-2.4/opt/prospect';

# PDB_PATH - location of pdb files, used by LocalClient
$Bio::Prospect::Init::PDB_PATH = '/apps/compbio/share/pdb';

# PROCESSED_PDB_PATH - location of processed pdb files for use with 
# the output_rasmol_script of the Thread class
$Bio::Prospect::Init::PROCESSED_PDB_PATH = '/apps/compbio/share/prospect/pdb';

# MVIEW_APP - path to mview application, used by Align
$Bio::Prospect::Init::MVIEW_APP = '/apps/compbio/bin/mview';

# SOAP_SERVER_HOST, SOAP_SERVER_PORT - host and port for SOAP::Transport::HTTP
# object that dispatches to a SoapServer object.  See bin/startProspectSoapServer.pl
# for more information.
$Bio::Prospect::Init::SOAP_SERVER_HOST = "host";
$Bio::Prospect::Init::SOAP_SERVER_PORT = '8081';

# PING_FAILURE_EMAILME = email the following list of people if the pingProspectSoapServer
# script fails to reach SoapServer
@Bio::Prospect::Init::PING_FAILURE_EMAILME = q( you );

# PING_FAILURE_NOTIFY_FILE = semaphore for pingProspectSoapServer script.  If ping fails,
# email is sent to PING_FAILURE_EMAILME list above and then this file is created so
# that additional runs of pingProspectSoapServer will not send mail again
$Bio::Prospect::Init::PING_FAILURE_SEMPAHORE = '/tmp/prospect_sempahore';

1;
