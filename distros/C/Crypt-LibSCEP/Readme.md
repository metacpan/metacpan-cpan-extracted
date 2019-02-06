# Crypt::LibSCEP

Crypt::LibSCEP implements an easy-to-use interface between LibSCEP and Perl programs. Its goal is to provide Perl programs with the capability of generating and reading messages for the Simple Certificate Enrollment Protocol (SCEP).

## Installation

To install this module type the following:

	perl Makefile.PL
  	make
  	make install

## Design

Crypt::LibSCEP consists of three different kinds of functionality: Create SCEP messages, parse SCEP messages and accessor methods for extracting specific information from parsed SCEP messages.

## Architecture

Crypt::LibSCEP consists of the following components:

### Blessed Objects
A parsed SCEP message is returned as a blessed object and not a Perl data structure. In order to obtain information from it, accessor methods are written that return the requested information.

### Data Format

Certificates and keys must be provided as PEM-encoded strings. Keys may be encrypted. Also, all accessor functions return strings. There is no support for file handles.

### Configuration Parameter

Besides accessor functions, the first parameter of every function is a hash reference reflecting a configuration. An empty hash reference is possible. Then, default values will be used. The use of the configuration parameter will be explained later on.

### Handle

A handle carries information that needs to be persistent over multiple requests. This is mostly the case when dealing with cryptographic engines.

## Parsing a SCEP Message

A SCEP message can contain encrypted information. Everything else can be parsed right ahead:

	$conf = {};
	$parsed = Crypt::LibSCEP::parse($conf, $scep_msg);

Afterwards, *$parsed* carries all information that has been stored in *$scep_msg* but the encrypted information. This is a convenience function in order to provide direct access to the data without involving cryptographic information.

In order to fully parse a message, the function *unwrap* is used.

	$unwrapped = Crypt::LibSCEP::unwrap($conf, $scep_msg, $sig_cert, $enc_cert, $enc_key);

*$sig_cert* is used for checking the message's signature whereas *$enc_cert* and *$enc_key* are used for decrypting the message's encrypted part. *$parsed* and *$unwrapped* are the same data type.

## Accessor Functions

Different messages types contain different values. The user is expected to provide an accessor function with the correct message. In case the content doesn't match the function (e.g. read out the failInfo from a SUCCESS message) the results can lead to false information!

**get_transaction_id**

Returns the transaction ID.

	Crypt::LibSCEP::get_transaction_id($parsed);

**get_message_type**

Returns the message type.

	Crypt::LibSCEP::get_message_type($parsed);

**get_getcert_serial**

In case the message type of *$unwrapped* is *GetCert* or *GetCRL* this function returns the serial number of the requested content.

	Crypt::LibSCEP::get_getcert_serial($unwrapped);

**get_subject**

In case the message type of *$unwrapped* is *GetCertInitial* this function returns the subject in one line used for the requested certificate.

	Crypt::LibSCEP::get_subject($unwrapped);

**get_issuer**

In case the message type of *$unwrapped* is *GetCertInitial*, *GetCert* or *GetCRL* this function returns the issuer in one line.

	Crypt::LibSCEP::get_issuer($unwrapped);

**get_failInfo**

In case the message type of *$parsed* is *CertRep* and PkiStatus is *FAILURE*, this function returns the failInfo.

	Crypt::LibSCEP::get_failInfo($parsed);

**get_pkiStatus**

In case the message type of *$parsed *is *CertRep*, this function returns the pkiStatus.

	Crypt::LibSCEP::get_pkiStatus($parsed);

**get_cert**

In case the message type of *$unwrapped* is *CertRep* as an answer to *PKCSReq*, *GetCert* or *GetCertInitial and pkiStatus is *SUCCESS* this function returns the included certificate. This is a different function than *getcert* which creates a message of type *GetCert*.

	Crypt::LibSCEP::get_cert($unwrapped);

**get_crl**

In case the message type of *$unwrapped* is *CertRep* as an answer to *GetCRL* and pkiStatus is *SUCCESS* this function returns the included CRL. This is a different function than *getcrl* which creates a message of type *GetCRL*.

	Crypt::LibSCEP::get_crl($unwrapped);

**get_signer_cert**

Returns the signer certificate of the SCEP message.

	Crypt::LibSCEP::get_signer_cert($parsed);

**get_pkcs10**

In case the message type of $unwrapped is *PKCSReq* this function returns the decrypted certificate signing request.

	Crypt::LibSCEP::get_pkcs10($unwrapped);

**get_recipientNonce**

Returns the recipient nonce. As it is stored as a binary value one might want to convert it to a hex value.

	$senderNonce = Crypt::LibSCEP::get_recipientNonce($parsed);
	$hex = unpack(  'H*', $senderNonce );

**get_senderNonce**

Returns the sender nonce. As it is stored as a binary value one might want to convert it to a hex value.

	$senderNonce = Crypt::LibSCEP::get_senderNonce($parsed);
	$hex = unpack(  'H*', $senderNonce );

## Creating SCEP Messages

SCEP defines so-called pkiMessages which can be created using a single code line. The string that is returned contains the pkiMessage in its PEM-encoded form. As a pkiMessage is a restricted version of a PKCS#7 message, the PEM starting line indicates that the message is a PKCS #7 message. 

Creating a pkiMessage is not trivial: Some parameters are automatically generated and not configurable, some can be configured using the *$conf* parameter. Not configurable are the transaction ID and the sender nonce. Both are automatically generated according to the SCEP specification by libSCEP. It is not possible to provide them from the outside. Cryptographic parameters, namely the algorithms used for encryption and signing can be changed using the *$conf* parameter.

NOTE: Not every input data provided to Crypt::LibSCEP is suitable for creating pkiMessages. For example, the CSR that should be included into a pkiMessage of type PKCSReq MUST include the challengePassword attribute. LibSCEP will not check for the correctness of the input data. The user must verify whether the data provided to libSCEP fulfills the requirements of SCEP. 

### PKCSReq

The PKCSReq message type is basically an encrypted and signed CSR. Therefore, it requires a certificate and key to sign the message, an encryption certificate and the CSR to be sent. There is only one function to create a PKCSReq message.

**pkcsreq**

	$pkcsreq = Crypt::LibSCEP::pkcsreq($conf, $sig_key, $sig_cert, $enc_cert, $req);

### GetCertInitial

Similar to PKCSReq. Instead of a CSR, this message type includes a transaction ID, a subject and the issuer. 

**getcertinitial**

The transaction ID and subject is derived from the CSR, the issuer is derived from the encryption certificate. Even though the transaction ID is not part of the CSR, LibSCEP assumes that the transaction ID is derived from the public key of the CSR. In case a different transaction ID is is used, LibSCEP cannot deal with it.

One might ask why the $issuer_cert is required for the GetCertInitial request but not for the PKCSReq message. Indeed, the PKCSReq message does not require any information about the issuer. We can't find any reason why this is different for GetCertInitial. The client still doesn't know which certificate will be used to sign the request. We assume this is a flaw in the specification.

	$getcertinitial = Crypt::LibSCEP::getcertinitial($conf, $sig_key, $sig_cert, $enc_cert, $req, $issuer_cert);

### GetCRL

Similar to PKCSReq. Instead of a CSR, this message includes an IssuerAndSerial from the certificate to be validated. Instead of providing the issuer and serial separately as it is the case in the *getcert* function, this functions assumes that the certificate that should be validated is present. If not, it can be obtained from the CA by using *cetcert*. 

**getcrl**

	$getcertinitial = Crypt::LibSCEP::getcrl($conf, $sig_key, $sig_cert, $enc_cert, $cert_to_be_validated);

### CertRep

CertRep is similar to PKCSReq. However, the message format differs depending on the pkiStatus attribute. Three different functions are implemented, one for each pkiStatus (PENDING, FAILURE, SUCCESS). In order to build a CertRep message (which is a response message to a PKCSReq message), information from the previously received PKCSReq message are required. Therefore, the easiest solution is to provide the PKCSReq message when creating a CertRep message. As not the entire PKCSReq message is required in order to build a response message, additional functionality has been implemented allowing for creating CertRep messages without providing the PKCSReq message but only the content of the PKCSReq message that is required.

**create_pending_reply**

Creates a pkiMessage of type *CertRep* and pkiStatus set to *PENDING*.

	$certrep = Crypt::LibSCEP::create_pending_reply($config, $sig_key, $sig_cert, $pkcsreq);

	$transid = Crypt::LibSCEP::get_transaction_id($pkcsreq);
	$senderNonce = Crypt::LibSCEP::get_recipientNonce($pkcsreq);
	$certrep = Crypt::LibSCEP::create_pending_reply_wop7($config, $sig_key, $sig_cert, $transid, $senderNonce);

**create_error_reply**

Creates a pkiMessage of type *CertRep* and pkiStatus set to *FAILURE*. In addition to the CertRep PENDING, an error message also requires a failInfo attribute. Please look into the SCEP specification which values are allowed here.  

	$failInfo = "badRequest";
	$certrep = Crypt::LibSCEP::create_error_reply($config, $sig_key, $sig_cert, $pkcsreq, $failInfo);

	$certrep = Crypt::LibSCEP::create_error_reply_wop7($config, $sig_key, $sig_cert, $transid, $senderNonce, $failInfo);


**create_certificate_reply**

Creates a pkiMessage of type *CertRep* and pkiStatus set to *SUCCESS* as an answer to the request-type PKCSReq, GetCertInitial or GetCert. As this message carries the issued or requested certificate, it must be provided to the function.

A certificate response message can also carry multiple certificates. However, the issued or requested one must be the first in list. The functions are built in such a way that they also accept an entire chain of certificates for *$issuedCert*. This allows for the user to include multiple ones. The user must be careful and provide a chain that conforms to this limitation.

A SUCCESS reply can be tricky: The user might want so get a signing certificate that should not be used for encryption. Normally, the certificate for encryption is the one issued. In order to provide a way to send a SUCCESS response with a different certificate for encryption, use the *\*_wo_p7* function and provide the encryption certificate manually.

	$certrep = Crypt::LibSCEP::create_certificate_reply($config, $sig_key, $sig_cert, $pkcsreq_or_getcert, $req_cert_or_chain);

	$certrep = Crypt::LibSCEP::create_certificate_reply_wop7($config, $sig_key, $sig_cert, $transid, $senderNonce, $enc_cert, $req_cert_or_chain);

**create_crl_reply**

Like *create_certificate_reply* but instead of certificates, a CRL is included. This message is used as a SUCCESS answer to GetCRL.

	$crl_reply = Crypt::LibSCEP::create_crl_reply($config, $sig_key, $sig_cert, $getcrl, $crl);


### GetCert

A GetCert message contains an issuer and a serial number which together uniquely identify a certificate that is requested. 

**getcert**

The function takes the serial number as a string whereas the issuer must be directly derived from the issuer certificate. Typically this way is easier even though only the subject of the issuer certificate rather than the entire certificate must be present for this task.

	$serial = "1";
	$getcert = Crypt::LibSCEP::getcert($conf, $sig_key, $sig_cert, $enc_cert, $issuer_cert, $serial);

### Further Convenience Functions

**create_nextca_reply**

HTTP messages in the context of SCEP don't necessarily transport pkiMessages meaning they don't have SCEP-specific attributes. LibSCEP provides a convenience function to create so-called degenerate certificates-only PKCS#7 Signed-data messages. This is required for creating an HTTP response message to GetNextCACert. All certificates that should be included must be chained to one string and stored in *$chain*. 

	$getNextCaCertReply = Crypt::LibSCEP::create_nextca_reply($config, $chain, $sig_cert, $sig_key);

## Configuration

The configuration parameter contains all variables that don't have to be necessarily provided for every request.

In case, the key that is used to sign a message is encrypted, *passin* contains the information on how to obtain the encryption password. Possible values are *plain*, *pass* and *env*. *plain* is the default value meaning the key is not encrypted. Note that IF the key is encrypted and *passin* is set to *plain*, the program will fail and not prompt for a password during runtime. *env* means that the password is stored in an environment variable called *env*. In case the environment variable is already occupied and another variable must be used, change the following code line in *LibSCEP.&#8203;xs* and re-compile the XS-code.

	if(!strcmp(config->passin, "env")) {

The last option is to set *passin* to *pass* and provide the password directly using the configuration parameter *passwd*.

The hash algorithm used for signing can be changed with *sigalg* whereas the default encryption algorithm can be changed with *encalg*. The names of the algorithms are those used by OpenSSL. The names are directly passed to the OpenSSL functions *EVP_get_digestbyname()* and *EVP_get_cipherbyname()* respectively.

Per default, Crypt::LibSCEP logs in DEBUG mode to stdout. The configuration allows to provide a path to a log-file via *log* that is then used instead of stdout. This is the only time when Crypt::LibSCEP works on files. When working with a persistent handle, changing the logfile one the handle is created is not allowed.

In case the user wants to change the level of verbosity, change the following code line in *LibSCEP.&#8203;xs* and re-compile the XS-code. Possible values are FATAL,
ERROR, WARN, INFO and DEBUG.

	s = scep_conf_set(config->handle, SCEPCFG_VERBOSITY, DEBUG);

An example configuration looks as the following:

	$config = {passin=>"pass", passwd=>"mypassword", sigalg=>"sha256", encalg=>"aes256", log=>"/path/to/logfile"};

## Persistency

For every request, LibSCEP creates a handle that contains all information that needs to be persistent during a request, for example the cryptographic algorithms to be used. Once the request is completed, the handle is deleted. It is more efficient to create the handle once and work on it for the entire session. This especially comes to practice when dealing with engines. When creating a handle, *encalg* and *sigalg* will be obtained from *$config* and stored in *$handle*. Afterwards, only the handle has to be provided to requests. The algorithms don't have to be provided again as they are already stored in *$handle*.

For requests, the handle can be provided as a configuration parameter. Once the user has finished using the handle, it must be deleted manually by executing *cleanup*.

	$config = {sigalg=>"sha256", encalg=>"aes256"};
	$handle = Crypt::LibSCEP::create_handle($config);
	$certrep = Crypt::LibSCEP::create_error_reply({passin=>"pass", passwd=>"mypassword", handle=>$handle}, $sig_key, $sig_cert, $pkcsreq, "badRequest");
	Crypt::LibSCEP::cleanup($handle);

Handles can also be updated by simply adding a parameter to the configuration when using the handle. In the following example, all three CertRep messages will be generated using the encryption algorithm "aes256". *$certrep2* updates the handle and changes *sigalg* to *md5*. *$certrep2* and *$certrep3* will therefore be generated using *md5*.

	$config = {sigalg=>"sha256", encalg=>"aes256"};
	$handle = Crypt::LibSCEP::create_handle($config);
	$certrep1 = Crypt::LibSCEP::create_error_reply({passin=>"pass", passwd=>"mypassword", handle=>$handle}, $sig_key, $sig_cert, $pkcsreq, "badRequest");
	$certrep2 = Crypt::LibSCEP::create_error_reply({passin=>"pass", passwd=>"mypassword", sigalg=>"md5", handle=>$handle}, $sig_key, $sig_cert, $pkcsreq, "badRequest");
	$certrep3 = Crypt::LibSCEP::create_error_reply({passin=>"pass", passwd=>"mypassword", handle=>$handle}, $sig_key, $sig_cert, $pkcsreq, "badRequest");
	Crypt::LibSCEP::cleanup($handle);

## Dealing with Engines

LibSCEP supports the use of engines. However, Crypt::LibSCEP only supports PKCS#11 engines.

The workflow of working with engines is relatively easy and consists of two steps. Fist, a handle is created as described above. Second, configuration information of the engine is added to the handle using the command *create_engine*. Then, the handle can be used as before. LibSCEP will do all the work for you.

**PKCS11 Engine**

In order to configure a PKCS11 engine, the following information is required: engine label, path to the engine, path to the module and PIN. The *create_engine* command takes all these arguments in a single hash. When using a PKCS11 engine, the key is managed by the engine and is not accessible for the user. Instead of providing the key to the command, a key identifier which points to the key managed by the engine is provided instead.

A full workflow looks as the following.

	$handle = Crypt::LibSCEP::create_handle({});
	$label = "pkcs11";
	$so = "/path/to/engine_pkcs11.so";
	$module = "/path/to/module.so";
	$pin = "123456";
	$id = "FFFF";
	$engine_conf = {module => $module, label => $label, so => $so, pin => $pin};
	Crypt::LibSCEP::create_engine({handle=>$handle}, $engine_conf);
	$pkcsreq = Crypt::LibSCEP::pkcsreq({handle=>$handle}, $id, $sig_cert, $enc_cert, $req);
	Crypt::LibSCEP::cleanup($handle);

Note: The current implementation does not allow for mixing engines. That means, every Crypt::LibSCEP command after *create_engine* must involve *$handle* until *cleanup($handle)* is executed. Using commands not involving this handle, for example trying to use multiple engines in parallel, results in erroneous behavior.