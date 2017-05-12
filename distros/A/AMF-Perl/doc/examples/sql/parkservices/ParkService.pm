package ParkService; 

use warnings;
use strict;

use AMF::Perl::Sql::MysqlRecordSet;

my $dbhost = "localhost";
my $dbname = "database";
my $dbuser = "user";
my $dbpass = "password";

use DBI;

sub new
{
    my ($proto) = @_;
    my $self = {};
    bless $self, $proto;

    my $dbh = DBI->connect("DBI:mysql:host=$dbhost:db=$dbname","$dbuser","$dbpass",{ PrintError=>1, RaiseError=>1 })
        or die "Unable to connect: " . $DBI::errstr . "\n";

	my $recordset = AMF::Perl::Sql::MysqlRecordSet->new($dbh);
	$self->recordset($recordset);

    return $self;
}


sub recordset
{
    my ($self, $val) = @_;
    $self->{recordset} = $val if $val;
    return $self->{recordset};
}

sub dbh
{
    my ($self, $val) = @_;
    $self->{dbh} = $val if $val;
    return $self->{dbh};
}


sub methodTable
{
    return {
        "getParkTypes" => {
            "description" => "Returns list of park types",
            "access" => "remote", 
			"returns" => "AMFObject"
        },
        "getParksList" => {
            "description" => "Shows list of parks given a park type",
            "access" => "remote", 
			"returns" => "AMFObject"
        },
        "getParkDetails" => {
            "description" => "Return details on a park give the parkname",
            "access" => "remote", 
			"returns" => "AMFObject"
        }
    };
    
}

sub getParkTypes()
{
    my ($self) = @_;
    return $self->recordset->query("SELECT Distinct(parktype) FROM tblparks WHERE parktype is not NULL order by parktype");
}

sub getParksList
{
    my ($self, $parkType) = @_;
	my $select = "SELECT parkName,city,state,parktype FROM tblparks ";
	$select .=  " WHERE parktype='$parkType' " if $parkType;
	$select .= "ORDER BY parkname";
    return  $self->recordset->query($select);
}

sub getParkDetails
{
    my ($self, $thisParkName) = @_;
    return  $self->recordset->query("SELECT * FROM tblparks WHERE parkname='".$thisParkName."'");
}


1;
