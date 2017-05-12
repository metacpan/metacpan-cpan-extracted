package Crypt::X509::CRL;

use Carp;
use strict;
use warnings;
use Convert::ASN1 qw(:io :debug);

require Exporter;

our @ISA = qw(Exporter);
our %EXPORT_TAGS = ( 'all' => [qw()] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );
our @EXPORT = qw( error new this_update next_update );
our $VERSION = '0.1';

my $parser = undef;
my $asn = undef;
my $error = undef;

my %oid2enchash= (
	'1.2.840.113549.1.1.1' => {'enc' => 'RSA'},
	'1.2.840.113549.1.1.2' => {'enc' => 'RSA', 'hash' => 'MD2'},
	'1.2.840.113549.1.1.3' => {'enc' => 'RSA', 'hash' => 'MD4'},
	'1.2.840.113549.1.1.4' => {'enc' => 'RSA', 'hash' => 'MD5'},
	'1.2.840.113549.1.1.5' => {'enc' => 'RSA', 'hash' => 'SHA1'},
	'1.2.840.113549.1.1.6' => {'enc' => 'OAEP'}
);

my %oid2attr = (
                "2.5.4.3" => "CN",
                "2.5.4.6" => "C",
                "2.5.4.7" => "l",
                "2.5.4.8" => "S",
                "2.5.4.10" => "O",
                "2.5.4.11" => "OU",
                "1.2.840.113549.1.9.1" => "E",
                "0.9.2342.19200300.100.1.1" => "UID",
                "0.9.2342.19200300.100.1.25" => "DC"
               );


=head1 Crypt-X509::CRL version 0.1
F<===========================>

Crypt::X509::CRL is an object oriented X.509 certificate revocation list
parser with numerous methods for directly extracting information from
certificate revocation lists.

=head1 INSTALLATION

To install this module type the following:

   perl Makefile.PL
   make
   make test
   make install

=head1 DEPENDENCIES

This module requires:

  Convert::ASN1

=head1 NAME

Crypt::X509::CRL - Parses an X.509 certificate revocation list

=head1 SYNOPSIS

 use Crypt::X509::CRL;

 $decoded = Crypt::X509::CRL->new( crl => $crl );

 $subject_email	= $decoded->subject_email;
 print "do not use after: ".gmtime($decoded->not_after)." GMT\n";

=head1 REQUIRES

Convert::ASN1

=head1 DESCRIPTION

B<Crypt::X509::CRL> parses X.509 certificate revocation lists. Methods are
provided for accessing most CRL elements.

It is based on the generic ASN.1 module by Graham Barr, on the
x509decode example by Norbert Klasen and contributions on the
perl-ldap-dev-Mailinglist by Chriss Ridd. It is also based upon the
works of Mike Jackson and Alexander Jung perl module Crypt::X509.

The following RFC 3280 Extensions are available (noted are the ones I
have implemented).

	Authority Key Identifier (implemented)
	CRL Number (implemented)
	Issuing Distribution Point (implemented)
	Issuer Alternative Name
	Delta CRL Indicator
	Freshest CRL (a.k.a. Delta CRL Distribution Point)

The following RFC 3280 CRL Entry Extensions are available (noted are the
ones I have implemented).

	Reason Code (implemented)
	Hold Instruction Code (implemented)
	Invalidity Date (implemented)
	Certificate Issuer

NOTE: The use of 'utcTime' in determining the revocation date of a given
certificate is based on RFC 3280 for dates through the year 2049.  Starting
with dates in 2050 and beyond the RFC calls for revocation dates to be
listed as 'generalTime'.

=head1 CONSTRUCTOR

=head2 new ( OPTIONS )

Creates and returns a parsed X.509 CRL hash, containing the parsed
contents. The data is organised as specified in RFC 2459.
By default only the first ASN.1 Layer is decoded. Nested decoding
is done automagically through the data access methods.

=over 4

=item crl =E<gt> $crl

A variable containing the DER formatted crl to be parsed
(eg. as stored in C<certificateRevocationList;binary> attribute in an
LDAP-directory).

=back

=head3 Example:

  use Crypt::X509::CRL;
  use Data::Dumper;

  $decoded = Crypt::X509::CRL->new( crl => $crl );

  print Dumper $decoded;

=cut back

sub new {
	my ( $class , %args ) = @_;

	if ( not defined ( $parser ) ) {
		$parser = _init();
	}

	my $self = $parser->decode( $args{'crl'} );

	$self->{'_error'} = $parser->error;
	bless ( $self , $class );

	return $self;
}

=head1 METHODS

=head2 error

Returns the last error from parsing, C<undef> when no error occured.
This error is updated on deeper parsing with the data access methods.

=head3 Example:

  $decoded= Crypt::X509::CRL->new(crl => $crl);
  if ( $decoded->error ) {
	warn "Error on parsing Certificate Revocation List: ", $decoded->error;
  }

=cut back

sub error {
	my $self = shift;
	return $self->{'_error'};
}

=head1 DATA ACCESS METHODS

You can access all parsed data directly from the returned hash. For convenience
the following data access methods have been implemented to give quick access to
the most-used crl attributes.

=head2 version

Returns the certificate revocation list's version as an integer.  Returns undef
if the version is not specified, since it is an optional field in some cases.

=head3 NOTE that version is defined as an Integer where:

	0 = v1
	1 = v2
	2 = v3

=cut back

sub version {
	my $self = shift;

	return undef if not exists $self->{'tbsCertList'}{'version'};

	return $self->{'tbsCertList'}{'version'};
}

=head2 version_string

Returns the certificate revocation list's version as a string value.

=head3 NOTE that version is defined as an Integer where:

	0 = v1
	1 = v2
	2 = v3

=cut back

sub version_string {
	my $self = shift;

	return undef if not exists $self->{'tbsCertList'}{'version'};

	my $v = $self->{'tbsCertList'}{'version'};
	return "v1" if $v == 0;
	return "v2" if $v == 1;
	return "v3" if $v == 2;
}

=head2 this_update

Returns either the utcTime or generalTime of the certificate revocation list's date
of publication. Returns undef if not defined.

=head3 Example:

  $decoded = Crypt::X509::CRL->new(crl => $crl);
  print "CRL was published at ", gmtime( $decoded->this_update ), " GMT\n";

=cut back

sub this_update {
	my $self = shift;
	if ( exists $self->{'tbsCertList'}{'thisUpdate'}{'utcTime'} ) {
		return $self->{'tbsCertList'}{'thisUpdate'}{'utcTime'};
	} elsif ( exists $self->{'tbsCertList'}{'thisUpdate'}{'generalTime'} ) {
		return $self->{'tbsCertList'}{'thisUpdate'}{'generalTime'};
	} else {
		return undef;
	}
}

=head2 next_update

Returns either the utcTime or generalTime of the certificate revocation list's
date of expiration.  Returns undef if not defined.

=head3 Example:

  $decoded = Crypt::X509::CRL->new(crl => $crl);
  if ( $decoded->next_update > time() ) {
  	warn "CRL has expired!";
  }

=cut back

sub next_update {
	my $self = shift;
	if ( exists $self->{'tbsCertList'}{'nextUpdate'}{'utcTime'} ) {
		return $self->{'tbsCertList'}{'nextUpdate'}{'utcTime'};
	} elsif ( $self->{'tbsCertList'}{'nextUpdate'}{'generalTime'} ) {
		return $self->{'tbsCertList'}{'nextUpdate'}{'generalTime'};
	} else {
		return undef;
	}
}

=head2 signature

Return's the certificate's signature in binary DER format.

=cut back

sub signature {
	my $self = shift;
	return $self->{'signatureValue'}[0];
}

=head2 signature_length

Return's the length of the certificate's signature.

=cut back

sub signature_length {
	my $self = shift;
	return $self->{'signatureValue'}[1];
}

=head2 signature_algorithm

Returns the certificate's signature algorithm as an OID string.

=head3 Example:

  $decoded = Crypt::X509::CRL->new(crl => $crl);
  print "CRL signature is encrypted with:", $decoded->signature_algorithm, "\n";

  Example Output: CRL signature is encrypted with: 1.2.840.113549.1.1.5

=cut back

sub signature_algorithm {
	my $self = shift;
	return $self->{'tbsCertList'}{'signature'}{'algorithm'};
}

=head2 SigEncAlg

Returns the signature encryption algorithm (e.g. 'RSA') as a string.

=head3 Example:

  $decoded = Crypt::X509::CRL->new(crl => $crl);
  print "CRL signature is encrypted with:", $decoded->SigEncAlg, "\n";

  Example Output: CRL signature is encrypted with: RSA


=cut back

sub SigEncAlg {
	my $self = shift;
	return $oid2enchash{ $self->{'tbsCertList'}{'signature'}->{'algorithm'} }->{'enc'};
}

=head2 SigHashAlg

Returns the signature hashing algorithm (e.g. 'SHA1') as a string.

=head3 Example:

  $decoded = Crypt::X509::CRL->new(crl => $crl);
  print "CRL signature is hashed with:", $decoded->SigHashAlg, "\n";

  Example Output: CRL signature is encrypted with: SHA1

=cut back

sub SigHashAlg {
	my $self = shift;
	return $oid2enchash{ $self->{'tbsCertList'}{'signature'}->{'algorithm'} }->{'hash'};
}


#########################################################################
# accessors - issuer
#########################################################################

=head2 Issuer

Returns a pointer to an array of strings building the DN of the certificate
issuer (= the DN of the CA). Attribute names for the most common Attributes
are translated from the OID-Numbers, unknown numbers are output verbatim.

=head3 Example:

  $decoded = Crypt::X509::CRL->new( $crl );
  print "CRL was issued by: ", join( ', ' , @{ $decoded->Issuer } ), "\n";

=cut back

sub Issuer {
	my $self = shift;
	my ( $i , $type );
	my $issuerdn = $self->{'tbsCertList'}->{'issuer'}->{'rdnSequence'};

	$self->{'tbsCertList'}->{'issuer'}->{'dn'} = [];

	my $issuedn = $self->{'tbsCertList'}->{'issuer'}->{'dn'};

	for my $issue ( @{ $issuerdn } ) {
		$i = @{ $issue }[0];
		if ( $oid2attr{ $i->{'type'} } ) {
			$type = $oid2attr{ $i->{'type'} };
		} else {
			$type = $i->{'type'};
        	}
		my @key = keys ( %{ $i->{'value'} } );
		push @{ $issuedn } , $type . "=" . $i->{'value'}->{ $key[0] };
	}
	return $issuedn;
}

sub _issuer_part {
	my $self = shift;
	my $oid = shift;
	my $issuerrdn = $self->{'tbsCertList'}->{'issuer'}->{'rdnSequence'};
	for my $issue ( @{ $issuerrdn } ) {
		my $i = @{ $issue }[0];
		if ( $i->{'type'} eq $oid ) {
			my @key = keys ( %{ $i->{'value'} } );
			return $i->{'value'}->{ $key[0] };
		 }
	}
	return undef;
}

=head2 issuer_cn

Returns the string value for issuer's common name (= the value with the
OID 2.5.4.3 or in DN Syntax everything after C<CN=>).
Only the first entry is returned. C<undef> if issuer contains no common name attribute.

=cut back

sub issuer_cn {
	my $self = shift;
	return _issuer_part( $self , '2.5.4.3' );
}


=head2 issuer_country

Returns the string value for issuer's country (= the value with the
OID 2.5.4.6 or in DN Syntax everything after C<C=>).
Only the first entry is returned. C<undef> if issuer contains no country attribute.

=cut back

sub issuer_country {
	my $self = shift;
	return _issuer_part( $self , '2.5.4.6' );
}

=head2 issuer_state

Returns the string value for issuer's state or province (= the value with the
OID 2.5.4.8 or in DN Syntax everything after C<S=>).
Only the first entry is returned. C<undef> if issuer contains no state attribute.

=cut back

sub issuer_state {
	my $self = shift;
	return _issuer_part( $self , '2.5.4.8' );
}

=head2 issuer_locality

Returns the string value for issuer's locality (= the value with the
OID 2.5.4.7 or in DN Syntax everything after C<L=>).
Only the first entry is returned. C<undef> if issuer contains no locality attribute.

=cut back

sub issuer_locality {
	my $self = shift;
	return _issuer_part( $self , '2.5.4.7' );
}

=head2 issuer_org

Returns the string value for issuer's organization (= the value with the
OID 2.5.4.10 or in DN Syntax everything after C<O=>).
Only the first entry is returned. C<undef> if issuer contains no organization attribute.

=cut back

sub issuer_org {
	my $self = shift;
	return _issuer_part( $self , '2.5.4.10' );
}

=head2 issuer_email

Returns the string value for issuer's email address (= the value with the
OID 1.2.840.113549.1.9.1 or in DN Syntax everything after C<E=>).
Only the first entry is returned. C<undef> if issuer contains no email attribute.

=cut back

sub issuer_email {
	my $self = shift;
	return _issuer_part( $self , '1.2.840.113549.1.9.1' );
}


#########################################################################
#
# ------- EXTENSIONS -------
#
# valid RFC 3280 extensions:
#	Authority Key Identifier (implemented)
#	CRL Number (implemented)
#	Issuing Distribution Point (implemented)
#	Issuer Alternative Name
#	Delta CRL Indicator
#	Freshest CRL (a.k.a. Delta CRL Distribution Point)
#
#########################################################################

=head2 key_identifier

Returns the authority key identifier as a bit string.

=head3 Example:

	$decoded = Crypt::X509::CRL->new( $crl );
	my $s = unpack("H*" , $decoded->key_identifier);
	print "The Authority Key Identifier in HEX is: $s\n";

	Example output:
	The Authority Key Identifier in HEX is: 86595f93caf32da620a4f9595a4a935370e792c9


=cut back

sub key_identifier {
	my $self = shift;
	if ( defined $self->_AuthorityKeyIdentifier ) { return ( $self->_AuthorityKeyIdentifier )->{keyIdentifier}; }
	return undef;
}

# _AuthorityKeyIdentifier
sub _AuthorityKeyIdentifier {
    my $self = shift;
    my $extensions = $self->{'tbsCertList'}->{'crlExtensions'};

    if ( not defined $extensions ) { return undef; } # no extensions in certificate

    if ( defined $self->{'tbsCertList'}{'AuthorityKeyIdentifier'} ) {
        return ( $self->{'tbsCertList'}{'AuthorityKeyIdentifier'} );
    }

    for my $extension ( @{ $extensions } ) {
        if ( $extension->{'extnID'} eq '2.5.29.35' ) { # OID for AuthorityKeyIdentifier
            my $parser = _init('AuthorityKeyIdentifier');
            $self->{'tbsCertList'}{'AuthorityKeyIdentifier'} = $parser->decode( $extension->{'extnValue'} );
            if ( $parser->error ) {
                $self->{"_error"} = $parser->error;
                return undef;
            }
            return $self->{'tbsCertList'}{'AuthorityKeyIdentifier'};
        }
    }
    return undef;
}

=head2 authorityCertIssuer

Returns a pointer to an array of strings building the DN of the Authority Cert
Issuer. Attribute names for the most common Attributes are translated from the
OID-Numbers, unknown numbers are output verbatim.  Returns undef if the
extension is not set in the certificate.

=head3 Example:

  $decoded = Crypt::X509::CRL->new($cert);
  print "Certificate was authorised by:", join( ', ', @{ $decoded->authorityCertIssuer } ), "\n";

=cut back

sub authorityCertIssuer {
	my $self = shift;
	my ( $i , $type );
	my $rdn = _AuthorityKeyIdentifier( $self );
	if ( not defined ( $rdn ) ) {
		return (undef); # we do not have that extension
	} else {
		$rdn = $rdn->{'authorityCertIssuer'}[0]->{'directoryName'};
	}
	$rdn->{'dn'} = [];
        my $dn = $rdn->{'dn'};
	$rdn = $rdn->{'rdnSequence'};
	for my $r ( @{ $rdn } ) {
		$i = @{ $r }[0];
		if ( $oid2attr{ $i->{'type'} } ) {
			$type = $oid2attr{ $i->{'type'} };
		} else {
			$type = $i->{'type'};
		}
		my @key = keys ( %{ $i->{'value'} } );
		push @{ $dn } , $type . "=" . $i->{'value'}->{ $key[0] };
	}
	return $dn;
}

sub _authcert_part {
	my $self = shift;
	my $oid = shift;
	my $rdn = _AuthorityKeyIdentifier( $self );
	if ( not defined ( $rdn ) ) {
		return (undef); # we do not have that extension
	} else {
		$rdn = $rdn->{'authorityCertIssuer'}[0]->{'directoryName'}->{'rdnSequence'};
	}
	for my $r ( @{ $rdn } ) {
		my $i = @{ $r }[0];
		if ( $i->{'type'} eq $oid ) {
			my @key = keys ( %{ $i->{'value'} } );
			return $i->{'value'}->{ $key[0] };
		 }
	}
	return undef;
}

=head2 authority_serial

Returns the authority's certificate serial number.

=cut back

sub authority_serial {
	my $self = shift;
    return ( $self->_AuthorityKeyIdentifier )->{authorityCertSerialNumber};
}


=head2 authority_cn

Returns the authority's ca.

=cut back

sub authority_cn {
	my $self = shift;
	return _authcert_part( $self , '2.5.4.3' );
}


=head2 authority_country

Returns the authority's country.

=cut back

sub authority_country {
	my $self = shift;
	return _authcert_part( $self , '2.5.4.6' );
}

=head2 authority_state

Returns the authority's state.

=cut back

sub authority_state {
	my $self = shift;
	return _authcert_part( $self , '2.5.4.8' );

}

=head2 authority_locality

Returns the authority's locality.

=cut back

sub authority_locality {
	my $self = shift;
	return _authcert_part( $self , '2.5.4.7' );
}

=head2 authority_org

Returns the authority's organization.

=cut back

sub authority_org {
	my $self = shift;
	return _authcert_part( $self , '2.5.4.10' );
}

=head2 authority_email

Returns the authority's email.

=cut back

sub authority_email {
	my $self = shift;
	return _authcert_part( $self , '1.2.840.113549.1.9.1' );
}

=head2 crl_number

Returns the CRL Number as an integer.

=cut back

# crl_number (another extension)
sub crl_number {
    my $self = shift;
    my $extension;
    my $extensions = $self->{'tbsCertList'}->{'crlExtensions'};

    if ( defined $self->{'tbsCertList'}{'cRLNumber'} ) {
        return ( $self->{'tbsCertList'}{'cRLNumber'} );
    }

    if ( not defined $extensions ) { return undef; } # no extensions in certificate

    for $extension ( @{ $extensions } ) {
        if ( $extension->{'extnID'} eq '2.5.29.20' ) { # OID for CRLNumber
            my $parser = _init('cRLNumber'); # get a parser for this
            $self->{'tbsCertList'}{'cRLNumber'} = $parser->decode( $extension->{'extnValue'} ); # decode the value
            if ( $parser->error ) {
                $self->{"_error"} = $parser->error;
                return undef;
            }
            return $self->{'tbsCertList'}{'cRLNumber'};
        }
    }
    return undef;
}

=head2 IDPs

Returns the Issuing Distribution Points as a hash providing for the default values.

=head3 Example:

	print "Issuing Distribution Points:\n";
	my $IDPs = $decoded->IDPs;
	for my $key ( sort keys %{ $IDPs } ) {
		print "$key = ";
		if ( defined $IDPs->{ $key } ) {
			print $IDPs->{ $key }, "\n";
		} else {
			print "undef\n";
		}
	}

=head3 Example Output:

	Issuing Distribution Points:
	critical = 1
	directory_addr = CN=CRL2, O=U.S. Government, C=US
	indirectCRL = 0
	onlyAttribCerts = 0
	onlyCaCerts = 0
	onlyUserCerts = 1
	reasonFlags = undef
	url = undef

=head3 Example of returned data structure:

	critical        = 0 or 1 # default is FALSE
	directory_addr  = CN=CR1,c=US # default is undef
	url             = ldap://ldap.gov/cn=CRL1,c=US # default is undef
	onlyUserCerts   = 0 or 1 # default is FALSE
	onlyCaCerts     = 0 or 1 # default is FALSE
	onlyAttribCerts = 0 or 1 # default is FALSE
	indirectCRL     = 0 or 1 # default is FALSE
	reasonFlags     = BIT STRING # default is undef

=cut back

# IDPs
sub IDPs {
    my $self = shift;
    my $extension;
    my $extensions = $self->{'tbsCertList'}->{'crlExtensions'};

    if ( defined $self->{'tbsCertList'}{'idp'} ) {
        return ( $self->{'tbsCertList'}{'idp'} );
    }

    if ( not defined $extensions ) { return undef; } # no extensions in certificate

    for $extension ( @{ $extensions } ) {
        if ( $extension->{'extnID'} eq '2.5.29.28' ) { # OID for issuingDistributionPoint
            my $parser = _init('issuingDistributionPoint'); # get a parser for this
            my $idps = $parser->decode( $extension->{'extnValue'} ); # decode the value
            if ( $parser->error ) {
                $self->{"_error"} = $parser->error;
                return undef;
            }

	    # set the critical flag
            if ( exists $extension->{'critical'} ) {
		$self->{'tbsCertList'}{'idp'}{'critical'} = $extension->{'critical'};
	    } else {
	    	$self->{'tbsCertList'}{'idp'}{'critical'} = 0;
	    }

	    # set the onlyContainsUserCerts flag
            if ( exists $idps->{'onlyContainsUserCerts'} ) {
		$self->{'tbsCertList'}{'idp'}{'onlyUserCerts'} = $idps->{'onlyContainsUserCerts'};
	    } else {
	    	$self->{'tbsCertList'}{'idp'}{'onlyUserCerts'} = 0;
	    }

	    # set the onlyContainsCACerts flag
            if ( exists $idps->{'onlyContainsCACerts'} ) {
		$self->{'tbsCertList'}{'idp'}{'onlyCaCerts'} = $idps->{'onlyContainsCACerts'};
	    } else {
	    	$self->{'tbsCertList'}{'idp'}{'onlyCaCerts'} = 0;
	    }

	    # set the onlyContainsAttributeCerts flag
            if ( exists $idps->{'onlyContainsAttributeCerts'} ) {
            	$self->{'tbsCertList'}{'idp'}{'onlyAttribCerts'} = $idps->{'onlyContainsAttributeCerts'}
	    } else {
	    	$self->{'tbsCertList'}{'idp'}{'onlyAttribCerts'} = 0;
	    }

	    # set the indirectCRL flag
	    if ( exists $idps->{'indirectCRL'} ) {
		$self->{'tbsCertList'}{'idp'}{'indirectCRL'} = $idps->{'indirectCRL'}
	    } else {
	    	$self->{'tbsCertList'}{'idp'}{'indirectCRL'} = 0
	    }

	    # set the defaults for directory_addr and url
	    $self->{'tbsCertList'}{'idp'}{'directory_addr'} = undef;
	    $self->{'tbsCertList'}{'idp'}{'url'} = undef;

	    # set the directory_addr and/or URL values
            for my $each_fullName ( @{ $idps->{'distributionPoint'}->{'fullName'} } ) { # this loops through multiple "fullName" values
	        if ( exists $each_fullName->{directoryName} ) {
	    	    # found a rdnSequence
		    $self->{'tbsCertList'}{'idp'}{'directory_addr'} =
		    join( ', ' , reverse @{ _IDP_rdn( $each_fullName->{directoryName}->{rdnSequence} ) } );
	        } elsif ( exists $each_fullName->{uniformResourceIdentifier} ) {
		    # found a URI
		    $self->{'tbsCertList'}{'idp'}{'url'} = $each_fullName->{uniformResourceIdentifier};
	        } else {
		    # found some other type of IDP value
		    # return undef;
	        }
	    }

	    # set the reason flags BIT STRING
	    if ( exists $idps->{'onlySomeReasons'} ) {
	    	$self->{'tbsCertList'}{'idp'}{'reasonFlags'} = $idps->{'onlySomeReasons'};
	    } else {
	    	$self->{'tbsCertList'}{'idp'}{'reasonFlags'} = undef;
	    }

            return $self->{'tbsCertList'}{'idp'};
        }
    }
    return undef;
}

# internal function for parsing the rdn sequence parts
sub _IDP_rdn {
	my $crl_rdn = shift; # this should be the passed in 'rdnSequence' array
	my ( $i ,$type );
	my $crl_dn = [];
	for my $part ( @{$crl_rdn} ) {
		$i = @{$part}[0];
		if ( $oid2attr{ $i->{'type'} } ) {
			$type = $oid2attr{ $i->{'type'} };
		 } else {
            		$type = $i->{'type'};
        	 }
		my @key = keys ( %{ $i->{'value'} } );
		push @{ $crl_dn } , $type . "=" . $i->{'value'}->{ $key[0] };
	}
	return $crl_dn;
}

#########################################################################
#
# ------- CRL ENTRY EXTENSIONS -------
#
# valid RFC 3280 CRL Entry Extensions:
#	Reason Code
#	Hold Instruction Code
#	Invalidity Date
#	Certificate Issuer
#
#########################################################################

=head2 revocation_list

Returns an array of hashes for the revoked certificates listed on the given CRL.  The
keys to the hash are the certificate serial numbers in decimal format.

=head3 Example:

	print "Revocation List:\n";
	my $rls = $decoded->revocation_list;
	my $count_of_rls = keys %{ $rls };
	print "Found $count_of_rls revoked certificate(s) on this CRL.\n";
	for my $key ( sort keys %{ $rls } ) {
		print "Certificate: ", DecimalToHex( $key ), "\n";
		for my $extn ( sort keys %{ $rls->{ $key } } ) {
			if ( $extn =~ /date/i ) {
				print "\t$extn: ", ConvertTime( $rls->{ $key }{ $extn } ), "\n";
			} else {
				print "\t$extn: ", $rls->{ $key }{ $extn }, "\n";
			}
		}
	}

=head3 Example Output:

	Revocation List:
	Found 1 revoked certificate(s) on this CRL.
	Certificate: 44 53 a0 f3
		crlReason: keyCompromise
		invalidityDate: Wednesday, September 27, 2006 12:54:51 PM
		revocationDate: Wednesday, September 27, 2006 1:29:36 PM

=cut back

# revocation_list
sub revocation_list {
    my $self = shift;
    my @crl_reason = qw(unspecified keyCompromise cACompromise affiliationChanged superseded
    			cessationOfOperation certificateHold removeFromCRL privilegeWithdrawn
    			aACompromise);
    my %hold_codes = (
	    '1.2.840.10040.2.1' => 'holdinstruction-none',
	    '1.2.840.10040.2.2' => 'holdinstruction-callissuer',
	    '1.2.840.10040.2.3' => 'holdinstruction-reject',
	    );

    if ( defined $self->{'tbsCertList'}{'rl'} ) {
        return ( $self->{'tbsCertList'}{'rl'} );
    }

    my $rls = $self->{'tbsCertList'}->{'revokedCertificates'};
    if ( not defined $rls ) { # no revoked certs in this CRL
        $self->{'tbsCertList'}{'rl'} = undef;
        return $self->{'tbsCertList'}{'rl'};
    }

    for my $rl ( @{ $rls } ) {
        # the below assignment of 'utcTime' is based on the RFC of dates through the
        # year 2049, after which the RFC calls for dates to be listed as
        # 'GeneralizedTime' or in the ASN1 below for Time as 'generalTime'.
        if ( exists $rl->{'revocationDate'}{'utcTime'} ) {
            $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{'revocationDate'} =
                                                        $rl->{'revocationDate'}{'utcTime'};
        } elsif ( exists $rl->{'revocationDate'}{'generalTime'} ) {
            $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{'revocationDate'} =
                                                    $rl->{'revocationDate'}{'generalTime'};
	} else {
            $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{'revocationDate'} = undef;
	}

        for my $extension ( @{ $rl->{'crlEntryExtensions'} } ) {
            if ( $extension->{'extnID'} eq '2.5.29.21' ) { # OID for crlReason
                my $parser = _init('CRLReason'); # get a parser for this
                my $reason = $parser->decode( $extension->{'extnValue'} ); # decode the value
                if ( $parser->error ) {
                    $self->{"_error"} = $parser->error;
                    return undef;
                }
                $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{'crlReason'} =
                                                        $crl_reason[ $reason ];

            } elsif ( $extension->{'extnID'} eq '2.5.29.24' ) { # OID for invalidityDate
                my $parser = _init('invalidityDate');
                my $invalid_date = $parser->decode( $extension->{'extnValue'} );
                if ( $parser->error ) {
                    $self->{"_error"} = $parser->error;
                    return undef;
                }
                $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{'invalidityDate'} =
                                                                              $invalid_date;

            } elsif ( $extension->{'extnID'} eq '2.5.29.23' ) { # OID for holdInstructionCode
                my $parser = _init('holdInstructionCode');
                my $hold_code = $parser->decode( $extension->{'extnValue'} );
                if ( $parser->error ) {
                    $self->{"_error"} = $parser->error;
                    return undef;
                }
                $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{'holdInstructionCode'} =
                                                        $hold_codes{ $hold_code };

            } else {
                # unimplemented OID(s) found
                $self->{'tbsCertList'}{'rl'}{ $rl->{'userCertificate'} }{ $extension->{'extnID'} } =
                					$extension->{'extnValue'};
            }
        }
    }
    return $self->{'tbsCertList'}{'rl'};
}


#######################################################################
# internal function
#######################################################################

# _init is the initialzation function and is also used for subsequent
# decoding of the inner parts of the object.
sub _init {
        my $what  = shift;
        if ( ( not defined $what ) or ( '' eq $what ) ) { $what = 'CertificateList' }
	if ( not defined $asn) {
		$asn = Convert::ASN1->new;
		$asn->prepare(<<ASN1);
-- ASN.1 from RFC 3280 and X509 (April 2002)
-- Adapted for use with Convert::ASN1


-- attribute data types --

   Attribute ::= SEQUENCE {
	type			AttributeType,
	values			SET OF AttributeValue
		-- at least one value is required --
	}

   AttributeType ::= OBJECT IDENTIFIER

   AttributeValue ::= DirectoryString  --ANY

   AttributeTypeAndValue ::= SEQUENCE {
	type			AttributeType,
	value			AttributeValue
	}


-- naming data types --

   Name ::= CHOICE { -- only one possibility for now
	rdnSequence		RDNSequence
	}

   RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

   RelativeDistinguishedName ::=
	SET OF AttributeTypeAndValue  --SET SIZE (1 .. MAX) OF


-- Directory string type --

   DirectoryString ::= CHOICE {
	teletexString		TeletexString,  --(SIZE (1..MAX)),
	printableString		PrintableString,  --(SIZE (1..MAX)),
	bmpString		BMPString,  --(SIZE (1..MAX)),
	universalString		UniversalString,  --(SIZE (1..MAX)),
	utf8String		UTF8String,  --(SIZE (1..MAX)),
	ia5String		IA5String,  --added for EmailAddress,
	integer			INTEGER
	}


-- CRL specific structures begin here

   CertificateList ::= SEQUENCE  {
        tbsCertList          TBSCertList,
        signatureAlgorithm   AlgorithmIdentifier,
        signatureValue       BIT STRING
        }


   TBSCertList ::= SEQUENCE  {
        version                 Version OPTIONAL,  -- if present, MUST be v2
        signature               AlgorithmIdentifier,
        issuer                  Name,
        thisUpdate              Time,
        nextUpdate              Time OPTIONAL,

        revokedCertificates     RevokedCertificates OPTIONAL,
        crlExtensions           [0]  EXPLICIT Extensions OPTIONAL
	}

   RevokedCertificates ::= SEQUENCE OF RevokedCerts

   RevokedCerts ::= SEQUENCE  {
	userCertificate         CertificateSerialNumber,
	revocationDate          Time,
	crlEntryExtensions      Extensions OPTIONAL
	}

   -- Version, Time, CertificateSerialNumber, and Extensions
   -- are all defined in the ASN.1 in section 4.1

   -- AlgorithmIdentifier is defined in section 4.1.1.2

   Version ::= INTEGER  --{  v1(0), v2(1), v3(2)  }

   CertificateSerialNumber ::= INTEGER

   AlgorithmIdentifier ::= SEQUENCE {
	algorithm		OBJECT IDENTIFIER,
	parameters		ANY
	}


   Name ::= CHOICE { -- only one possibility for now
	rdnSequence		RDNSequence
	}


   Time ::= CHOICE {
	utcTime			UTCTime,
	generalTime		GeneralizedTime
	}

--extensions

   Extensions ::= SEQUENCE OF Extension  --SIZE (1..MAX) OF Extension

   Extension ::= SEQUENCE {
	extnID			OBJECT IDENTIFIER,
	critical		BOOLEAN OPTIONAL,  --DEFAULT FALSE,
	extnValue		OCTET STRING
	}

   AuthorityKeyIdentifier ::= SEQUENCE {
      keyIdentifier             [0] KeyIdentifier            OPTIONAL,
      authorityCertIssuer       [1] GeneralNames             OPTIONAL,
      authorityCertSerialNumber [2] CertificateSerialNumber  OPTIONAL }
    -- authorityCertIssuer and authorityCertSerialNumber shall both
    -- be present or both be absent

   KeyIdentifier ::= OCTET STRING

   GeneralNames ::= SEQUENCE OF GeneralName

   GeneralName ::= CHOICE {
     otherName                       [0]     AnotherName,
     rfc822Name                      [1]     IA5String,
     dNSName                         [2]     IA5String,
     x400Address                     [3]     ANY, --ORAddress,
     directoryName                   [4]     Name,
     ediPartyName                    [5]     EDIPartyName,
     uniformResourceIdentifier       [6]     IA5String,
     iPAddress                       [7]     OCTET STRING,
     registeredID                    [8]     OBJECT IDENTIFIER }

-- AnotherName replaces OTHER-NAME ::= TYPE-IDENTIFIER, as
-- TYPE-IDENTIFIER is not supported in the 88 ASN.1 syntax

   AnotherName ::= SEQUENCE {
     type    OBJECT IDENTIFIER,
     value      [0] EXPLICIT ANY } --DEFINED BY type-id }

   EDIPartyName ::= SEQUENCE {
     nameAssigner            [0]     DirectoryString OPTIONAL,
     partyName               [1]     DirectoryString }

-- id-ce-issuingDistributionPoint OBJECT IDENTIFIER ::= { id-ce 28 }

   issuingDistributionPoint ::= SEQUENCE {
        distributionPoint          [0] DistributionPointName OPTIONAL,
        onlyContainsUserCerts      [1] BOOLEAN OPTIONAL,  --DEFAULT FALSE,
        onlyContainsCACerts        [2] BOOLEAN OPTIONAL,  --DEFAULT FALSE,
        onlySomeReasons            [3] ReasonFlags OPTIONAL,
        indirectCRL                [4] BOOLEAN OPTIONAL,  --DEFAULT FALSE,
        onlyContainsAttributeCerts [5] BOOLEAN OPTIONAL   --DEFAULT FALSE
        }

   DistributionPointName ::= CHOICE {
     fullName                [0]     GeneralNames,
     nameRelativeToCRLIssuer [1]     RelativeDistinguishedName }

   ReasonFlags ::= BIT STRING --{
   --     unused                  (0),
   --     keyCompromise           (1),
   --     cACompromise            (2),
   --     affiliationChanged      (3),
   --     superseded              (4),
   --     cessationOfOperation    (5),
   --     certificateHold         (6),
   --     privilegeWithdrawn      (7),
   --     aACompromise            (8) }

-- id-ce-cRLNumber OBJECT IDENTIFIER ::= { id-ce 20 }

   cRLNumber ::= INTEGER --(0..MAX)

-- id-ce-cRLReason OBJECT IDENTIFIER ::= { id-ce 21 }

   -- reasonCode ::= { CRLReason }

   CRLReason ::= ENUMERATED {
        unspecified             (0),
        keyCompromise           (1),
        cACompromise            (2),
        affiliationChanged      (3),
        superseded              (4),
        cessationOfOperation    (5),
        certificateHold         (6),
        removeFromCRL           (8),
        privilegeWithdrawn      (9),
        aACompromise           (10) }

-- id-ce-holdInstructionCode OBJECT IDENTIFIER ::= { id-ce 23 }

   holdInstructionCode ::= OBJECT IDENTIFIER

-- holdInstruction    OBJECT IDENTIFIER ::=
--                  { iso(1) member-body(2) us(840) x9-57(10040) 2 }
--
-- id-holdinstruction-none   OBJECT IDENTIFIER ::= {holdInstruction 1}
-- id-holdinstruction-callissuer
--                           OBJECT IDENTIFIER ::= {holdInstruction 2}
-- id-holdinstruction-reject OBJECT IDENTIFIER ::= {holdInstruction 3}

-- id-ce-invalidityDate OBJECT IDENTIFIER ::= { id-ce 24 }

   invalidityDate ::=  GeneralizedTime

-- id-ce-certificateIssuer   OBJECT IDENTIFIER ::= { id-ce 29 }

   certificateIssuer ::=     GeneralNames

ASN1
        }
        my $self = $asn->find( $what );
        return $self;
}


=head1 SEE ALSO

See the examples of C<Convert::ASN1> and the <perl-ldap@perl.org> Mailing List.
An example on how to load certificates can be found in F<t\Crypt-X509-CRL.t>.

=head1 ACKNOWLEDGEMENTS

This module is based on the x509decode script, which was contributed to
Convert::ASN1 in 2002 by Norbert Klasen.

It is also based on the Crypt::X509 perl module, which was contributed
by Mike Jackson and Alexander Jung.

=head1 AUTHOR

Duncan Segrest <CPAN@GigaGeek.info> ,

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2007 by Duncan Segrest <CPAN@GigaGeek.info>.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
__END__
