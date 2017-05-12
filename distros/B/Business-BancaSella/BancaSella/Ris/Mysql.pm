package Business::BancaSella::Ris::Mysql;

$VERSION = "0.11";
sub Version { $VERSION; }
require 5.004;
use strict;
use warnings;
use Carp;

my %fields 	=
    (
     dbh		=>	undef,
     tableName	=>	undef,
     fieldName	=>	undef,
     );
     
my @fields_req	= qw/dbh tableName fieldName/;
								

sub new
{   
	my $proto = shift;
    my $class = ref($proto) || $proto;
    my $self = {};
    bless $self,$class;
    $self->init(@_);
    return $self;
}							

sub init {
	my $self = shift;
	my (%options) = @_;
	# Assign default options
	while (my ($key,$value) = each(%fields)) {
		$self->{$key} = $self->{$key} || $value;
    }
    # Assign options
    while (my ($key,$value) = each(%options)) {
    	$self->{$key} = $value
    }
    # Check required params
    foreach (@fields_req) {
		croak "You must declare '$_' in " . ref($self) . "::new"
				if (!defined $self->{$_});
	}
}


sub check {
	my $self = shift;
	my $ris = shift;
	# get Ris password
	my $sql 	= 'select ' . $self->fieldName . ' from ' . $self->tableName .  
					' where ' . $self->fieldName . "='" . $ris . "'";
	my @ret		= $self->dbh->selectrow_array($sql) ;
	if (@ret) {
		return $ret[0] eq $ris;
	} else {
		return 0;
	}
}

sub remove {
	my $self = shift;
	my $ris = shift;
	# remove Ris password from Ris Table.
	my $sql 	= 'delete from ' . $self->tableName . ' where ' . 
				$self->fieldName . " = '" . $ris . "'";
	my $rec_affected= $self->dbh->do($sql) or die "Unable to execute $sql";
	die "Unable to find $ris in table" if ($rec_affected == 0);
}

sub extract {
	# check password and remove it
	# return true if find it
    my ($self,$password,$only_test) = @_;
    return 0 if (!$self->check($password));
    $self->remove($password);
}

sub prepare {
    my ($self,$source_file) = @_;
    # read the passwords
    open(SOURCE,"<$source_file") || croak "SYSTEM. opening $source_file : $!\n";
    my @rows = <SOURCE>;
    if ( $! ) {
        croak "SYSTEM. reading $source_file : $!\n";
    }
    close(SOURCE) || croak "SYSTEM. closing $source_file : $!\n";

    # verify the passwords
    my @passwords = ();
    my $line = 1;
    foreach my $row ( @rows ) {
        unless ( $row =~ /^([a-zA-Z0-9]{32})\n+$/ ) {
            croak "CORRUPT. file $source_file corrupted at line $line\n";
        }
        push @passwords, ($1);
    }
    # build insert string 
    my $sql = "INSERT INTO " . $self->{tableName} . " (" . $self->{fieldName} .
    	") VALUES  \n";
    foreach (@passwords) {
    	$sql .=   "('$_'),\n";
    }
    # remove last ",\n"
    chomp($sql);chop($sql);
    $self->{dbh}->do($sql) or croak "Unable to execute " . substr($sql,0,200). "...";
}

sub dbh { my $s=shift; return @_ ? ($s->{dbh}=shift) : $s->{dbh} }
sub tableName { my $s=shift; return @_ ? ($s->{tableName}=shift) : $s->{tableName} }
sub fieldName { my $s=shift; return @_ ? ($s->{fieldName}=shift) : $s->{fieldName} }

1;
__END__
