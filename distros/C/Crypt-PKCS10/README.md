# NAME

Crypt::PKCS10 - parse PKCS #10 certificate requests

# SYNOPSIS

    use Crypt::PKCS10;

    Crypt::PKCS10->setAPIversion( 1 );
    my $decoded = Crypt::PKCS10->new( $csr ) or die Crypt::PKCS10->error;

    print $decoded;

    @names = $decoded->extensionValue('subjectAltName' );
    @names = $decoded->subject unless( @names );

    %extensions = map { $_ => $decoded->extensionValue( $_ ) } $decoded->extensions

# DESCRIPTION

`Crypt::PKCS10` parses PKCS #10 certificate requests (CSRs) and provides accessor methods to extract the data in usable form.

Common object identifiers will be translated to their corresponding names.
Additionally, accessor methods allow extraction of single data fields.
The format of returned data varies by accessor.

The access methods return the value corresponding to their name.  If called in scalar context, they return the first value (or an empty string).  If called in array context, they return all values.

**true** values should be specified as 1 and **false** values as 0.  Future API changes may provide different functions when other values are used.

# METHODS

Access methods may exist for subject name components that are not listed here.  To test for these, use code of the form:

    $locality = $decoded->localityName if( $decoded->can('localityName') );

If a name component exists in a CSR, the method will be present.  The converse is not (always) true.

## class method setAPIversion( $version )

Selects the API version (0 or 1) expected.

Must be called before calling any other method.

The API version determines how a CSR is parsed.  Changing the API version after
parsing a CSR will cause accessors to produce unpredictable results.

- Version 0 - **DEPRECATED**

    Some OID names have spaces and descriptions

    This is the format used for `Crypt::PKCS10` version 1.3 and lower.  The attributes method returns legacy data.

    Some new API functions are disabled.

- Version 1

    OID names from RFCs - or at least compatible with OpenSSL and ASN.1 notation.  The attributes method conforms to version 1.

If not called, a warning will be generated and the API will default to version 0.

In a future release, the warning will be changed to a fatal exception.

To ease migration, both old and new names are accepted by the API.

Every program should call `setAPIversion(1)`.

## class method getAPIversion

Returns the current API version.

Returns `undef` if setAPIversion has never been called.

## class method new( $csr, %options )

Constructor, creates a new object containing the parsed PKCS #10 certificate request.

`$csr` may be a scalar containing the request, a file name, or a file handle from which to read it.

If a file name is specified, the `readFile` option must be specified.

If a file handle is supplied, the caller should specify `acceptPEM => 0` if the contents are DER.

The request may be PEM or binary DER encoded.  Only one request is processed.

If PEM, other data (such as mail headers) may precede or follow the CSR.

    my $decoded = Crypt::PKCS10->new( $csr ) or die Crypt::PKCS10->error;

Returns `undef` if there is an I/O error or the request can not be parsed successfully.

Call `error()` to obtain more detail.

### options

The options are specified as `name => value`.

If the first option is a HASHREF, it is expanded and any remaining options are added.

- acceptPEM

    If **false**, the input must be in DER format.  `binmode` will be called on a file handle.

    If **true**, the input is checked for a `CERTIFICATE REQUEST` header.  If not found, the csr
    is assumed to be in DER format.

    Default is **true**.

- PEMonly

    If **true**, the input must be in PEM format.  An error will be returned if the input doesn't contain a `CERTIFICATE REQUEST` header.
    If **false**, the input is parsed according to `acceptPEM`.

    Default is **false**.

- binaryMode

    If **true**, an input file or file handle will be set to binary mode prior to reading.

    If **false**, an input file or file handle's `binmode` will not be modified.

    Defaults to **false** if **acceptPEM** is **true**, otherwise **true**.

- dieOnError

    If **true**, any API function that sets an error string will also `die`.

    If **false**, exceptions are only generated for fatal conditions.

    The default is **false**.  API version 1 only..

- escapeStrings

    If **true**, strings returned for extension and attribute values are '\\'-escaped when formatted.
    This is compatible with OpenSSL configuration files.

    The special characters are: '\\', '$', and '"'

    If **false**, these strings are not '\\'-escaped.  This is useful when they are being displayed
    to a human.

    The default is **true**.

- ignoreNonBase64

    If **true**, most invalid base64 characters in PEM data will be ignored.  For example, this will
    accept CSRs prefixed with '> ', as e-mail when the PEM is inadvertently quoted.  Note that the
    BEGIN and END lines may not be corrupted.

    If **false**, invalid base64 characters in PEM data will cause the CSR to be rejected.

    The default is **false**.

- readFile

    If **true**, `$csr` is the name of a file containing the CSR.

    If **false**, `$csr` contains the CSR or is an open file handle.

    The default is **false**.

- verifySignature

    If **true**, the CSR's signature is checked.  If verification fails, `new` will fail.  Requires API version 1.

    If **false**, the CSR's signature is not checked.

    The default is **true** for API version 1 and **false** for API version 0.

    See `checkSignature` for requirements and limitations.

No exceptions are generated, unless `dieOnError` is set or `new()` is called in
void context.

The defaults will accept either PEM or DER from a string or file hande, which will
not be set to binary mode.  Automatic detection of the data format may not be
reliable on file systems that represent text and binary files differently. Set
`acceptPEM` to **false** and `PEMonly` to match the file type on these systems.

The object will stringify to a human-readable representation of the CSR.  This is
useful for debugging and perhaps for displaying a request.  However, the format
is not part of the API and may change.  It should not be parsed by automated tools.

Exception: The public key and extracted request are PEM blocks, which other tools
can extract.

If another object inherits from `Crypt::PKCS10`, it can extend the representation
by overloading or calling `as_string`.

## {class} method error

Returns a string describing the last error encountered;

If called as an instance method, last error encountered by the object.

If called as a class method, last error encountered by the class.

Any method can reset the string to **undef**, so the results are
only valid immediately after a method call.

## class method name2oid( $oid )

Returns the OID corresponding to a name returned by an access method.

Not in API v0;

## csrRequest( $format )

Returns the binary (ASN.1) request (after conversion from PEM and removal of any data beyond the length of the ASN.1 structure.

If $format is **true**, the request is returned as a PEM CSR.  Otherwise as a binary string.

## certificationRequest

Returns the binary (ASN.1) section of the request that is signed by the requestor.

The caller can verify the signature using **signatureAlgorithm**, **certificationRequest** and **signature(1)**.

## Access methods for the subject's distinguished name

Note that **subjectAltName** is prefered, and that modern certificate users will ignore the subject if **subjectAltName** is present.

### subject( $format )

Returns the entire subject of the CSR.

In scalar context, returns the subject as a string in the form `/componentName=value,value`.
  If format is **true**, long component names are used.  By default, abbreviations are used when they exist.

    e.g. /countryName=AU/organizationalUnitName=Big org/organizationalUnitName=Smaller org
    or     /C=AU/OU=Big org/OU=Smaller org

In array context, returns an array of `(componentName, [values])` pairs.  Abbreviations are not used.

Note that the order of components in a name is significant.

### commonName

Returns the common name(s) from the subject.

    my $cn = $decoded->commonName();

### organizationalUnitName

Returns the organizational unit name(s) from the subject

### organizationName

Returns the organization name(s) from the subject.

### emailAddress

Returns the email address from the subject.

### stateOrProvinceName

Returns the state or province name(s) from the subject.

### countryName

Returns the country name(s) from the subject.

## subjectAltName( $type )

Convenience method.

When $type is specified: returns the subject alternate name values of the specified type in list context, or the first value
of the specified type in scalar context.

Returns undefined/empty list if no values of the specified type are present, or if the **subjectAltName**
extension is not present.

Types can be any of:

      otherName
    * rfc822Name
    * dNSName
      x400Address
      directoryName
      ediPartyName
    * uniformResourceIdentifier
    * iPAddress
    * registeredID

The types marked with '\*' are the most common.

If `$type` is not specified:
 In list context returns the types present in the subjectAlternate name.
 In scalar context, returns the SAN as a string.

## version

Returns the structure version as a string, e.g. "v1" "v2", or "v3"

## pkAlgorithm

Returns the public key algorithm according to its object identifier.

## subjectPublicKey( $format )

If `$format` is **true**, the public key will be returned in PEM format.

Otherwise, the public key will be returned in its hexadecimal representation

## subjectPublicKeyParams

Returns a hash describing the public key.  The contents vary depending on
the public key type.

### Standard items:

`keytype` - ECC, RSA, DSA or `undef`

`keytype` will be `undef` if the key type is not supported.  In
this case, `error()` returns a diagnostic message.

`keylen` - Approximate length of the key in bits.

Other items include:

For RSA, `modulus` and `publicExponent`.

For DSA, `G, P and Q`.

For ECC, `curve`, `pub_x` and `pub_y`.  `curve` is an OID name.

### Additional detail

`subjectPublicKeyParams(1)` returns the standard items, and may
also return `detail`, which is a hashref.

For ECC, the `detail` hash includes the curve definition constants.

## signatureAlgorithm

Returns the signature algorithm according to its object identifier.

## signatureParams

Returns the parameters associated with the **signatureAlgorithm** as binary.
Returns **undef** if none, or if **NULL**.

Note: In the future, some **signatureAlgorithm**s may return a hashref of decoded fields.

Callers are advised to check for a ref before decoding...

## signature( $format )

The CSR's signature is returned.

If `$format` is **1**, in binary.

If `$format` is **2**, decoded as an ECDSA signature - returns hashref to `r` and `s`.

Otherwise, in its hexadecimal representation.

## attributes( $name )

A request may contain a set of attributes. The attributes are OIDs with values.
The most common is a list of requested extensions, but other OIDs can also
occur.  Of those, **challengePassword** is typical.

For API version 0, this method returns a hash consisting of all
attributes in an internal format.  This usage is **deprecated**.

For API version 1:

If $name is not specified, a list of attribute names is returned.  The list does not
include the requestedExtensions attribute.  For that, use extensions();

If no attributes are present, the empty list (`undef` in scalar context) is returned.

If $name is specified, the value of the extension is returned.  $name can be specified
as a numeric OID.

In scalar context, a single string is returned, which may include lists and labels.

    cspName="Microsoft Strong Cryptographic Provider",keySpec=2,signature=("",0)

Special characters are escaped as described in options.

In array context, the value(s) are returned as a list of items, which may be references.

    print( " $_: ", scalar $decoded->attributes($_), "\n" )
                                      foreach ($decoded->attributes);

See the _Table of known OID names_ below for a list of names.

## extensions

Returns an array containing the names of all extensions present in the CSR.  If no extensions are present,
the empty list is returned.

The names vary depending on the API version; however, the returned names are acceptable to `extensionValue`, `extensionPresent`, and `name2oid`.

The values of extensions vary, however the following code fragment will dump most extensions and their value(s).

    print( "$_: ", $decoded->extensionValue($_,1), "\n" ) foreach ($decoded->extensions);

The sample code fragment is not guaranteed to handle all cases.
Production code needs to select the extensions that it understands and should respect
the **critical** boolean.  **critical** can be obtained with extensionPresent.

## extensionValue( $name, $format )

Returns the value of an extension by name, e.g. `extensionValue( 'keyUsage' )`.
The name SHOULD be an API v1 name, but API v0 names are accepted for compatibility.
The name can also be specified as a numeric OID.

If `$format` is 1, the value is a formatted string, which may include lists and labels.
Special characters are escaped as described in options;

If `$format` is 0 or not defined, a string, or an array reference may be returned.
The array many contain any Perl variable type.

To interpret the value(s), you need to know the structure of the OID.

See the _Table of known OID names_ below for a list of names.

## extensionPresent( $name )

Returns **true** if a named extension is present:
    If the extension is **critical**, returns 2.
    Otherwise, returns 1, indicating **not critical**, but present.

If the extension is not present, returns `undef`.

The name can also be specified as a numeric OID.

See the _Table of known OID names_ below for a list of names.

## registerOID( )

Class method.

Register a custom OID, or a public OID that has not been added to Crypt::PKCS10 yet.

The OID may be an extension identifier or an RDN component.

The oid is specified as a string in numeric form, e.g. `'1.2.3.4'`

### registerOID( $oid )

Returns **true** if the specified OID is registered, **false** otherwise.

### registerOID( $oid, $longname, $shortname )

Registers the specified OID with the associated long name.  This
enables the OID to be translated to a name in output.

The long name should be Hungarian case (**commonName**), but this is not currently
enforced.

Optionally, specify the short name used for extracting the subject.
The short name should be upper-case (and will be upcased).

E.g. built-in are `$oid => '2.4.5.3', $longname => 'commonName', $shortname => 'CN'`

To register a shortname for an existing OID without one, specify `$longname` as `undef`.

E.g. To register /E for emailAddress, use:
  `Crypt::PKCS10->registerOID( '1.2.840.113549.1.9.1', undef, 'e' )`

Generates an exception if any argument is not valid, or is in use.

Returns **true** otherwise.

## checkSignature

Verifies the signature of a CSR.  (Useful if new() specified `verifySignature => 0`.)

Returns **true** if the signature is OK.

Returns **false** if the signature is incorrect.  `error()` returns
the reason.

Returns **undef** if it was not possible to complete the verification process (e.g. a required
Perl module could not be loaded or an unsupported key/signature type is present.)

_Note_: Requires Crypt::PK::\* for the used algorithm to be installed. For RSA
v1.5 padding is assumed, PSS is not supported (validation fails).

## certificateTemplate

`CertificateTemplate` returns the **certificateTemplate** attribute.

Equivalent to `extensionValue( 'certificateTemplate' )`, which is prefered.

## Table of known OID names

The following OID names are known.  They are used in returned strings and
structures, and as names by methods such as **extensionValue**.

Unknown OIDs are returned in numeric form, or can be registered with
**registerOID**.

    OID                        Name (API v1)              Old Name (API v0)
    -------------------------- -------------------------- ---------------------------
    0.9.2342.19200300.100.1.1  userID
    0.9.2342.19200300.100.1.25 domainComponent
    1.2.840.10040.4.1          dsa                        (DSA)
    1.2.840.10040.4.3          dsaWithSha1                (DSA with SHA1)
    1.2.840.10045.2.1          ecPublicKey
    1.2.840.10045.3.1.1        secp192r1
    1.2.840.10045.3.1.7        secp256r1
    1.2.840.10045.4.3.1        ecdsa-with-SHA224
    1.2.840.10045.4.3.2        ecdsa-with-SHA256
    1.2.840.10045.4.3.3        ecdsa-with-SHA384
    1.2.840.10045.4.3.4        ecdsa-with-SHA512
    1.2.840.113549.1.1.1       rsaEncryption              (RSA encryption)
    1.2.840.113549.1.1.2       md2WithRSAEncryption       (MD2 with RSA encryption)
    1.2.840.113549.1.1.3       md4WithRSAEncryption
    1.2.840.113549.1.1.4       md5WithRSAEncryption       (MD5 with RSA encryption)
    1.2.840.113549.1.1.5       sha1WithRSAEncryption      (SHA1 with RSA encryption)
    1.2.840.113549.1.1.6       rsaOAEPEncryptionSET
    1.2.840.113549.1.1.7       RSAES-OAEP
    1.2.840.113549.1.1.11      sha256WithRSAEncryption    (SHA-256 with RSA encryption)
    1.2.840.113549.1.1.12      sha384WithRSAEncryption
    1.2.840.113549.1.1.13      sha512WithRSAEncryption    (SHA-512 with RSA encryption)
    1.2.840.113549.1.1.14      sha224WithRSAEncryption
    1.2.840.113549.1.9.1       emailAddress
    1.2.840.113549.1.9.2       unstructuredName
    1.2.840.113549.1.9.7       challengePassword
    1.2.840.113549.1.9.14      extensionRequest
    1.2.840.113549.1.9.15      smimeCapabilities          (SMIMECapabilities)
    1.3.6.1.4.1.311.2.1.14     CERT_EXTENSIONS
    1.3.6.1.4.1.311.2.1.21     msCodeInd
    1.3.6.1.4.1.311.2.1.22     msCodeCom
    1.3.6.1.4.1.311.10.3.1     msCTLSign
    1.3.6.1.4.1.311.10.3.2     msTimeStamping
    1.3.6.1.4.1.311.10.3.3     msSGC
    1.3.6.1.4.1.311.10.3.4     msEFS
    1.3.6.1.4.1.311.10.3.4.1   msEFSRecovery
    1.3.6.1.4.1.311.10.3.5     msWHQLCrypto
    1.3.6.1.4.1.311.10.3.6     msNT5Crypto
    1.3.6.1.4.1.311.10.3.7     msOEMWHQLCrypto
    1.3.6.1.4.1.311.10.3.8     msEmbeddedNTCrypto
    1.3.6.1.4.1.311.10.3.9     msRootListSigner
    1.3.6.1.4.1.311.10.3.10    msQualifiedSubordination
    1.3.6.1.4.1.311.10.3.11    msKeyRecovery
    1.3.6.1.4.1.311.10.3.12    msDocumentSigning
    1.3.6.1.4.1.311.10.3.13    msLifetimeSigning
    1.3.6.1.4.1.311.10.3.14    msMobileDeviceSoftware
    1.3.6.1.4.1.311.13.1       RENEWAL_CERTIFICATE
    1.3.6.1.4.1.311.13.2.1     ENROLLMENT_NAME_VALUE_PAIR
    1.3.6.1.4.1.311.13.2.2     ENROLLMENT_CSP_PROVIDER
    1.3.6.1.4.1.311.13.2.3     OS_Version
    1.3.6.1.4.1.311.20.2       certificateTemplateName
    1.3.6.1.4.1.311.20.2.2     msSmartCardLogon
    1.3.6.1.4.1.311.21.7       certificateTemplate
    1.3.6.1.4.1.311.21.10      ApplicationCertPolicies
    1.3.6.1.4.1.311.21.20      ClientInformation
    1.3.6.1.5.2.3.5            keyPurposeKdc              (KDC Authentication)
    1.3.6.1.5.5.7.2.1          CPS
    1.3.6.1.5.5.7.2.2          userNotice
    1.3.6.1.5.5.7.3.1          serverAuth
    1.3.6.1.5.5.7.3.2          clientAuth
    1.3.6.1.5.5.7.3.3          codeSigning
    1.3.6.1.5.5.7.3.4          emailProtection
    1.3.6.1.5.5.7.3.8          timeStamping
    1.3.6.1.5.5.7.3.9          OCSPSigning
    1.3.6.1.5.5.7.3.21         sshClient
    1.3.6.1.5.5.7.3.22         sshServer
    1.3.6.1.5.5.7.9.5          countryOfResidence
    1.3.14.3.2.29              sha1WithRSAEncryption      (SHA1 with RSA signature)
    1.3.36.3.3.2.8.1.1.1       brainpoolP160r1
    1.3.36.3.3.2.8.1.1.2       brainpoolP160t1
    1.3.36.3.3.2.8.1.1.3       brainpoolP192r1
    1.3.36.3.3.2.8.1.1.4       brainpoolP192t1
    1.3.36.3.3.2.8.1.1.5       brainpoolP224r1
    1.3.36.3.3.2.8.1.1.6       brainpoolP224t1
    1.3.36.3.3.2.8.1.1.7       brainpoolP256r1
    1.3.36.3.3.2.8.1.1.8       brainpoolP256t1
    1.3.36.3.3.2.8.1.1.9       brainpoolP320r1
    1.3.36.3.3.2.8.1.1.10      brainpoolP320t1
    1.3.36.3.3.2.8.1.1.11      brainpoolP384r1
    1.3.36.3.3.2.8.1.1.12      brainpoolP384t1
    1.3.36.3.3.2.8.1.1.13      brainpoolP512r1
    1.3.36.3.3.2.8.1.1.14      brainpoolP512t1
    1.3.132.0.1                sect163k1
    1.3.132.0.15               sect163r2
    1.3.132.0.16               sect283k1
    1.3.132.0.17               sect283r1
    1.3.132.0.26               sect233k1
    1.3.132.0.27               sect233r1
    1.3.132.0.33               secp224r1
    1.3.132.0.34               secp384r1
    1.3.132.0.35               secp521r1
    1.3.132.0.36               sect409k1
    1.3.132.0.37               sect409r1
    1.3.132.0.38               sect571k1
    1.3.132.0.39               sect571r1
    2.5.4.3                    commonName
    2.5.4.4                    surname                    (Surname)
    2.5.4.5                    serialNumber
    2.5.4.6                    countryName
    2.5.4.7                    localityName
    2.5.4.8                    stateOrProvinceName
    2.5.4.9                    streetAddress
    2.5.4.10                   organizationName
    2.5.4.11                   organizationalUnitName
    2.5.4.12                   title                      (Title)
    2.5.4.13                   description                (Description)
    2.5.4.14                   searchGuide
    2.5.4.15                   businessCategory
    2.5.4.16                   postalAddress
    2.5.4.17                   postalCode
    2.5.4.18                   postOfficeBox
    2.5.4.19                   physicalDeliveryOfficeName
    2.5.4.20                   telephoneNumber
    2.5.4.23                   facsimileTelephoneNumber
    2.5.4.41                   name                       (Name)
    2.5.4.42                   givenName
    2.5.4.43                   initials
    2.5.4.44                   generationQualifier
    2.5.4.45                   uniqueIdentifier
    2.5.4.46                   dnQualifier
    2.5.4.51                   houseIdentifier
    2.5.4.65                   pseudonym
    2.5.29.14                  subjectKeyIdentifier       (SubjectKeyIdentifier)
    2.5.29.15                  keyUsage                   (KeyUsage)
    2.5.29.17                  subjectAltName
    2.5.29.19                  basicConstraints           (Basic Constraints)
    2.5.29.32                  certificatePolicies
    2.5.29.32.0                anyPolicy
    2.5.29.37                  extKeyUsage                (EnhancedKeyUsage)
    2.16.840.1.101.3.4.2.1     sha256                     (SHA-256)
    2.16.840.1.101.3.4.2.2     sha384                     (SHA-384)
    2.16.840.1.101.3.4.2.3     sha512                     (SHA-512)
    2.16.840.1.101.3.4.2.4     sha224                     (SHA-224)
    2.16.840.1.101.3.4.3.1     dsaWithSha224
    2.16.840.1.101.3.4.3.2     dsaWithSha256
    2.16.840.1.101.3.4.3.3     dsaWithSha384
    2.16.840.1.101.3.4.3.4     dsaWithSha512
    2.16.840.1.113730.1.1      netscapeCertType
    2.16.840.1.113730.1.2      netscapeBaseUrl
    2.16.840.1.113730.1.4      netscapeCaRevocationUrl
    2.16.840.1.113730.1.7      netscapeCertRenewalUrl
    2.16.840.1.113730.1.8      netscapeCaPolicyUrl
    2.16.840.1.113730.1.12     netscapeSSLServerName
    2.16.840.1.113730.1.13     netscapeComment
    2.16.840.1.113730.4.1      nsSGC

# EXAMPLES

In addition to the code snippets contained in this document, the `examples/` directory of the distribution
contains some sample utilitiles.

Also, the `t/` directory of the distribution contains a number of tests that exercise the
API.  Although artificial, they are another good source of examples.

Note that the type of data returned when extracting attributes and extensions is dependent
on the specific OID used.

Also note that some functions not listed in this document are tested.  The fact that they are
tested does not imply that they are stable, or that they will be present in any future release.

The test data was selected to exercise the API; the CSR contents are not representative of
realistic certificate requests.

# ACKNOWLEDGEMENTS

Martin Bartosch contributed preliminary EC support:  OIDs and tests.

Timothe Litt made most of the changes for V1.4+

`Crypt::PKCS10` is based on the generic ASN.1 module by Graham Barr and on the
 x509decode example by Norbert Klasen. It is also based upon the
works of Duncan Segrest's `Crypt-X509-CRL` module.

# AUTHORS

Gideon Knocke <gknocke@cpan.org>
Timothe Litt <tlhackque@cpan.org>

# LICENSE

GPL v1 -- See LICENSE file for details
