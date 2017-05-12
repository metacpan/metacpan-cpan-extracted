package Bio::KBase::CDMI::CDMIClient;


use Bio::KBase::CDMI::Client;

our $have_local_cdmi;
eval {
    require Bio::KBase::CDMI::CDMI;
    require Bio::KBase::CDMI::CDMI_APIImpl;
    require Bio::KBase::CDMI::CDMI_EntityAPIImpl;
    $have_local_cdmi = 1;
};

use strict;
use Getopt::Long;


=head3 new

    my $cdmi = CDMIClient->new_for_script(%options);

Construct a new CDMI client object for a command-line script. This method
uses a call to L<GetOpt::Long/getoptions> to parse the command-line
options, with the incoming B<options> parameter as a parameter.
The following command-line options (all of which are optional) will
also be processed by this method and used to construct the CDMI object.

If the command-line parse fails, an undefined value will be returned
rather than a CDMI object.

The CDMIClient object can create either a CDMI_APIClient object for accessing
the CDMI over the network, or a CDMI_APIImpl object for accessing
a local database. The latter will most likely only be used by
developers of the CDMI. The C<--local> option must be passed to
create the local database version.

=over 4

=item url

Web service url to connect to.

=item local

Create an object to be used by a local database.

=item loadDirectory

Data directory to be used by the loaders.

=item DBD

XML database definition file.

=item dbName

Name of the database to use.

=item sock

Socket for accessing the database.

=item userData

Name and password used to log on to the database, separated by a slash.

=item dbhost

Database host name.

=item port

MYSQL port number to use (MySQL only).

=item dbms

Database management system to use (e.g. C<postgres>, default C<mysql>).

=back

=cut

sub new_for_script {
    # Get the parameters.
    my ($class, %options) = @_;


    return new_for_script_with_type($class, 'Bio::KBase::CDMI::CDMI_APIImpl', 'Bio::KBase::CDMI::Client', %options);
}

sub new_get_entity_for_script {
    # Get the parameters.
    my ($class, %options) = @_;


    return new_for_script_with_type($class,
				    'Bio::KBase::CDMI::CDMI_EntityAPIImpl',
				    'Bio::KBase::CDMI::Client',
				    %options);
}

sub new_for_script_with_type
{
    my($class, $impl_class, $client_class, %options) = @_;


    # We'll put the return value in here if the command-line parse fails.
    my $retVal;
    # Create the variables for our internal options.
    my ($loadDirectory, $dbd, $dbName, $sock, $userData, $dbhost, $port, $dbms);
    my ($local, $url);

    $url = "http://bio-data-1.mcs.anl.gov/services/cdmi_api";

    # Parse the command line.
    my $rc = GetOptions(%options,
			"local"		  => \$local,
			"url=s"		  => \$url,
			"loadDirectory=s" => \$loadDirectory,
			"DBD=s"		  => \$dbd,
			"dbName=s"	  => \$dbName,
			"sock=s"	  => \$sock,
			"userData=s"	  => \$userData,
			"dbhost=s"	  => \$dbhost,
			"port=i"	  => \$port,
			"dbms=s"	  => \$dbms);
    # If the parse worked, create the CDMI object.
    if ($rc) {
	if ($local)
	{
	    if (!$have_local_cdmi)
	    {
		die "The appropriate modules are not available for using the -local flag";
	    }
	    my $cdmi = Bio::KBase::CDMI::CDMI->new(loadDirectory => $loadDirectory, DBD => $dbd,
						   dbName => $dbName, sock => $sock, userData => $userData,
						   dbhost => $dbhost, port => $port, dbms => $dbms);
	    $retVal = $impl_class->new($cdmi);

	}
	else
	{
	    $retVal = $client_class->new($url);
	}
    }
    # Return the result.
    return $retVal;
}

sub new {
    # Get the parameters.
    my ($class, $local) = @_;


    return new_with_type($class, 'Bio::KBase::CDMI::CDMI_APIImpl', 'Bio::KBase::CDMI::Client', $local);
}

sub new_get_entity {
    # Get the parameters.
    my ($class, $local) = @_;


    return new_with_type($class,
                                    'Bio::KBase::CDMI::CDMI_EntityAPIImpl',
                                    'Bio::KBase::CDMI::Client',
                                    $local);
}

sub new_with_type
{
    my($class, $impl_class, $client_class, $local) = @_;


    # We'll put the return value in here.
    my $retVal;
    my ($url);

    $url = "http://bio-data-1.mcs.anl.gov/services/cdmi_api";

    if ($local)
    {
        if (!$have_local_cdmi)
        {
            die "The appropriate modules are not available for using the -local flag";
        }
        my $cdmi = Bio::KBase::CDMI::CDMI->new();
        $retVal = $impl_class->new($cdmi);

    }
    else
    {
        $retVal = $client_class->new($url);
    }
    # Return the result.
    return $retVal;
}

1;
