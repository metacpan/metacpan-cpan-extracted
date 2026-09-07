#
# @author Bodo (Hugo) Barwich
# @version 2026-08-31
# @package Conig::Access::Driver
# @subpackage lib/Config/Section.pm

# This Module defines Classes to manage Data of an INI configuration section
#
#---------------------------------
# Requirements:
#
#---------------------------------
# Features:
#

#==============================================================================
# The Conig::Section Package

package Config::Section;

#----------------------------------------------------------------------------
#Dependencies

use parent Object::Meta;

use constant LIST_DATA_KEYS => 2;

#----------------------------------------------------------------------------
#Constructors

sub new {
    my $class = ref( $_[0] ) || $_[0];
    my $self  = undef;

    #Take the Method Parameters
    my %hshprms = @_[ 1 .. $#_ ];

    #Set the Default Attributes and assign the initial Values
    $self = [ {}, {}, [] ];

    #Bestow Objecthood
    bless $self, $class;

    if ( defined $hshprms{'name'} ) {
        Config::Section::setName( $self, $hshprms{'name'} );
    }
    else {
        Config::Section::setName $self ;
    }

    if ( scalar( keys %hshprms ) > 1 ) {
        delete $hshprms{'name'};

        #Parameters are a Key / Value List
        Config::Section::set( $self, %hshprms );
    }

    return $self;
}

#----------------------------------------------------------------------------
#Administration Methods

sub setName {
    my $self = $_[0];

    if ( scalar(@_) > 1 ) {
        Object::Meta::setMeta( $self, 'sectionname', $_[1] );
    }
    else {
        Object::Meta::setMeta( $self, 'sectionname', '' );
    }
}

sub add {
    my $self      = $_[0];
    my $skeyvalue = $_[1];

    if ( defined $skeyvalue ) {
        my $ikeymaxvalue = Object::Meta::getMeta( $self, 'keymax', -1 );

        Config::Section::set( $self, $ikeymaxvalue + 1, $skeyvalue );
    }    #if(defined $skeyvalue)
}

sub set {

    #Take the Method Parameters
    my ( $self, %hshprms ) = @_;

    return if ( scalar(@_) < 2 );

    my $ikeymaxvalue = Object::Meta::getMeta( $self, 'keymax',   -1 );
    my $ikeycount    = Object::Meta::getMeta( $self, 'keycount', -1 );

    foreach ( keys %hshprms ) {

        #The Field Name must not be empty
        if ( $_ ne '' ) {
            if ( $_ =~ qr/^\d+$/ ) {

                #The Field Name is an unsigned whole Number

                if ( $hshprms{$_} =~ qr/^\d+$/ ) {

                    #The Field Value is an unsigned whole Number

                    #Array of Numbers
                    $self->[Object::Meta::LIST_DATA]{$_} = $hshprms{$_};
                }
                else    #Value is not numeric
                {
                    #Array of Names
                    $self->[Object::Meta::LIST_DATA]{ $hshprms{$_} } = $_;
                }

                $#{ $self->[LIST_DATA_KEYS] } = $_
                  if ( $_ + 1 > @{ $self->[LIST_DATA_KEYS] } );

                ${ $self->[LIST_DATA_KEYS] }[$_] = $hshprms{$_};

                #Track the Max Value
                $ikeymaxvalue = $_
                  if ( $_ > $ikeymaxvalue );

            }
            else    #The Field Name is not numeric
            {
                unless ( defined $self->[Object::Meta::LIST_DATA]{$_} ) {

                    #Register the new Key
                    push @{ $self->[LIST_DATA_KEYS] }, ($_);
                }    #unless(defined $self->[MetaEntry::LIST_DATA]{$_})

                #Assign the Key and its Value
                $self->[Object::Meta::LIST_DATA]{$_} = $hshprms{$_};

            }    #if($_ =~ /^\d+$/)
        }    #if($_ ne '')
    }    #foreach (keys %hshprms)

    Object::Meta::setMeta( $self, 'keymax', $ikeymaxvalue )
      unless ( $ikeymaxvalue == -1 );

    #Reset the Key Count
    Object::Meta::setMeta( $self, 'keycount', -1 )
      unless ( $ikeycount == -1 );
}

sub Clear {
    my $self = $_[0];

    #Preserve ConfigSection Name
    my $sname = Config::Section::getName $self ;

    #Execute Base Class Logic
    Object::Meta::Clear $self ;

    $self->[LIST_DATA_KEYS] = [];

    #Restore ConfigSection Name
    Config::Section::setName $self, $sname;
}

#----------------------------------------------------------------------------
#Consultation Methods

sub get {
    my ( $self, $sfieldname, $sdefault, $imta ) = @_;
    my $srs = $sdefault;

    unless ($imta) {
        if ( defined $sfieldname
            && $sfieldname ne '' )
        {
            if ( exists $self->[Object::Meta::LIST_DATA]{$sfieldname} ) {
                $srs = $self->[Object::Meta::LIST_DATA]{$sfieldname};
            }
            elsif ( $sfieldname =~ qr/^\d+$/ ) {

                #The Field Name is an unsigned whole Number

                if ( exists $self->[LIST_DATA_KEYS][$sfieldname] ) {
                    $srs = $self->[LIST_DATA_KEYS][$sfieldname]
                      if ( defined $self->[LIST_DATA_KEYS][$sfieldname] );

                }
                else {
                    #Check as Meta Field
                    $srs =
                      Object::Meta::getMeta( $self, $sfieldname, $sdefault );
                }
            }
            else    #The Key does not exist and is not numeric
            {
                #Check as Meta Field
                $srs = Object::Meta::getMeta( $self, $sfieldname, $sdefault );
            }       #if(exists $self->[LIST_DATA_INDEXED]{$sfieldname})
        }    #if(defined $sfieldname && $sfieldname ne '')
    }
    else     #A Meta Field is requested
    {
        #Check a Meta Field
        $srs = Object::Meta::getMeta( $self, $sfieldname, $sdefault );
    }        #unless($imta)

    return $srs;
}

sub getName {
    return $_[0]->[Object::Meta::LIST_META_DATA]{'sectionname'} || '';
}

sub getKey {
    my ( $self, $iindex ) = @_;
    my $srs = '';

    #The Index Value must be an unsigned whole Number
    if ( $iindex =~ qr/^\d+$/ ) {
        if ( exists $self->[LIST_DATA_KEYS][$iindex] ) {
            $srs = $self->[LIST_DATA_KEYS][$iindex];
        }
    }

    return $srs;
}

sub getKeyValue {
    my ( $self, $iindex ) = @_;
    my $skey   = '';
    my $svalue = '';

    $skey = $self->getKey($iindex);

    $skey = '' unless ( defined $skey );

    if ( $skey ne '' ) {
        if ( Object::Meta::getMeta( $self, 'keymax', -1 ) == -1 ) {
            if ( exists $self->[Object::Meta::LIST_DATA]{$skey} ) {
                $svalue = $self->[Object::Meta::LIST_DATA]{$skey};
            }
        }
        else    #Array Configurations
        {
            #The Key is already the Value
            $svalue = $skey;
            $skey   = $iindex;
        }
    }

    return ( $skey, $svalue );
}

sub hasKey {
    my ( $self, $skeyname ) = @_;
    my $irs = 0;

    if ( defined $skeyname
        && $skeyname ne '' )
    {
        if ( $skeyname =~ qr/^\d+$/ ) {

            #The Key Name is an unsigned whole Number

            $irs = 1 if ( defined $self->[LIST_DATA_KEYS][$skeyname] );
        }
        else {
            $irs = 1 if ( defined $self->[Object::Meta::LIST_DATA]{$skeyname} );
        }
    }

    return $irs;
}

sub getKeyCount {
    my $irs = Object::Meta::getMeta( $_[0], 'keycount', -1 );

    if ( $irs == -1 ) {
        $irs = scalar( @{ $_[0]->[LIST_DATA_KEYS] } );

        Object::Meta::setMeta( $_[0], 'keycount', $irs );
    }

    return $irs;
}

return 1;
