#
# @author Bodo (Hugo) Barwich
# @version 2026-08-31
# @package Conig::Access::Driver
# @subpackage lib/Config/Access/Driver.pm

# This Module defines Classes to manage Data of an INI configuration section
#
#---------------------------------
# Requirements:
#
#---------------------------------
# Features:
#

use Config::Section::List;
use Config::Section::Parser;

#==============================================================================
# The Config::Access::Driver Package

package Config::Access::Driver;

our $VERSION = '1.0.0';

#----------------------------------------------------------------------------
#Dependencies

use parent 'File::Access::Driver';

use Scalar::Util 'blessed';

use Data::Dump qw(dump);

#----------------------------------------------------------------------------
#Static Methods

sub readConfigSectionList {
    my $cfgfl = undef;

    my %hshprms = undef;

    #Return the Section List
    my $lstsecs = undef;

    if ( scalar(@_) > 1 ) {

        #Take the Method Parameters
        %hshprms = @_;
    }
    else {
        #One single Parameter
        %hshprms = ( 'filepath' => $_[0] );
    }

    $cfgfl = Config::Access::Driver::new( 'Config::Access::Driver', %hshprms );

    $cfgfl->setFilePath( $hshprms{'filepath'} );

    $lstsecs = $cfgfl->readList();

    #Free the System Resources
    $cfgfl->freeResources();

    return $lstsecs;
}

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $class = ref( $_[0] ) || $_[0];
    my $self  = undef;

    #Pass through the Method Parameters
    $self = $class->SUPER::new( @_[ 1 .. $#_ ] );

    $self->{'_list_sections'} = undef;

    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub setList {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        $self->{'_list_sections'} = $_[1]
          if ( defined blessed $_[1] );

    }

    if ( defined $self->{'_list_sections'} ) {
        $self->{'_list_sections'} = undef
          unless ( $self->{'_list_sections'}->isa('Config::Section::List') );

    }
}

sub Read {
    my $self      = $_[0];
    my $rarrcntnt = undef;

    if ( defined $self->{'_list_sections'} ) {

        #Clean the Section List for new Content
        $self->{'_list_sections'}->clearList;
    }
    else {
        #Create a New Section List
        $self->{'_list_sections'} = new Config::Section::List::;
    }

    #Read the File Content into an Array
    $rarrcntnt = File::Access::Driver::readContentArray $self ;

    return 0 if ( !defined $rarrcntnt
        || ref($rarrcntnt) ne 'ARRAY' );

    return Config::Section::Parser::fillListFromArray(
        $self->{'_list_sections'}, $rarrcntnt );
}

sub readList {
    my $self = $_[0];

    #Read and Parse the Configuration File
    $self->Read();

    #Return the Parsed Section List
    return $self->getList;
}

sub Write {
    my $self   = $_[0];
    my $scntnt = Config::Section::Parser::buildStringFromList(
        $self->{'_list_sections'});

    #print "cfg cntnt:\n" . $scntnt;

    #Write the Configuration Content to the File
    my $irs = File::Access::Driver::writeContent $self, $scntnt;

   return $irs;
}

sub writeList {
    my $self = $_[0];
    my $irs  = 0;

    #Set the List
    $self->setList( $_[1] );

    #Write the Section List to the Configuration File
    $irs = $self->Write;

    #Communicate the Result
    return $irs;
}

sub Clear {
    my $self = $_[0];

    #Execute the Base Class Logic
    $self->SUPER::Clear;

    if ( defined $self->{'_list_sections'} ) {

        #Clear the Section List
        $self->{'_list_sections'}->clearList;
    }
}

sub freeResources {
    my $self = $_[0];

    #Execute the Base Class Logic
    $self->SUPER::freeResources;

    $self->{'_list_sections'} = undef;
}

#----------------------------------------------------------------------------
#Consultation Methods

sub getList {
    my $self = $_[0];

    #Create a new empty Section List
    $self->{'_list_sections'} = new Config::Section::List::
      unless ( defined $self->{'_list_sections'} );

    return $self->{'_list_sections'};
}

return 1;
