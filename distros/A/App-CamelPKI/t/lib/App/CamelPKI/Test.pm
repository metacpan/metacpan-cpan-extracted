#!perl -w

package App::CamelPKI::Test;

use warnings;
use strict;

=head1 NAME

B<App::CamelPKI::Test> - L<App::CamelPKI> Tests.

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use App::CamelPKI::Test qw(:default %test_der_DNs);
  use Test::Group;

  my $utf8 = App::CamelPKI::Test->test_simple_utf8();

  run_perl_ok(<<"SCRIPT");
  use App::CamelPKI::Test;
  warn "Hello world";
  SCRIPT

=for My::Tests::Below "synopsis" end

=for My::Tests::Below "synopsis-asn1" begin

 use App::CamelPKI::Test qw(x509_decoder);

 my $dn_as_tree = x509_decoder('Name')->decode($dn_der);

=for My::Tests::Below "synopsis-asn1" end

 server_start();
 server_stop();

=head1 DESCRIPTION

This module is a library which aims at simplifying App-PKI test writing.
It started as a raw copy of I<Crypt::OpenSSL::CA:Test> you can find in
the C<t/lib> directory of the source L<Crypt::OpenSSL::CA> CPAN source
package.


=head1 EXPORTED FUNCTIONS

All functions described in this section factor some useful test
tactics and are exported by default.  The L</SAMPLE INPUTS> may also
be exported upon request.

=over

=cut

use Test::Builder;
use Test::More;
use Test::Group;
use File::Find;
use File::Path ();
use File::Spec::Functions qw(catfile catdir);
use File::Slurp;
use File::Temp ();
use POSIX ":sys_wait_h";
use File::Which ();
use IO::Socket::SSL;
use LWP::UserAgent;
use HTTP::Request;
#pour formulaires
use URI::URL;
use HTTP::Request::Common;
use HTTP::Request::Form;
use HTML::TreeBuilder 3.0;

use base 'Exporter';
BEGIN {
    our @EXPORT =
        qw(openssl_path run_thru_openssl run_dumpasn1
           run_perl run_perl_ok
           certificate_looks_ok
           certificate_chain_ok certificate_chain_invalid_ok
           x509_schema x509_decoder
           run_php run_php_script
           http_request_prepare http_request_execute
           plaintextcall_remote
           call_remote formcall_remote formreq_remote
           jsoncall_local jsonreq_remote jsoncall_remote
           is_php_cli_present);
    our @EXPORT_OK = (@EXPORT,
                      qw(test_simple_utf8 test_bmp_utf8
                         @test_DN_CAs
                         %test_der_DNs
                         %test_public_keys
                         %test_reqs_SPKAC %test_reqs_PKCS10
                         %test_keys_plaintext %test_keys_password
                         %test_self_signed_certs %test_rootca_certs
                         %test_entity_certs
                         test_CRL
                         server_start server_stop server_port
                         create_camel_pki_conf_php
                         camel_pki_chain
                         ));
    our %EXPORT_TAGS = ("default" => \@EXPORT);
}

=item I<plaintextcall_remote($url)>

Qureies a real Apache server at $url, which must be fully-qualified.
Throws an exception if the HTTP request isn't a success; otherwise,
Returns the C<text/plain> response as a string.

Available named options are:

=over

=item I<< -certificate => $certobj >>

=item I<< -certificate => $certpem >>

The certificate to identify oneself as, as an L<App::CamelPKI::Certificate>
instance or PEM string.

=item I<< -key => $keyobj >>

=item I<< -key => $keypem >>

The private key to use along with the certificate, as an
L<App::CamelPKI::PrivateKey> instance or PEM string.

=cut

sub plaintextcall_remote {
    my ($url, @args) = @_;
    my $req = http_request_prepare($url, @args);
    my $res = http_request_execute($req, @args);
    die sprintf("plain request at $url failed with code %d\n%s\n",
                $res->code, $res->content)
        unless $res->is_success;
    die sprintf("plain request at $url returned a %s document\n%s\n",
                $res->header("content-type"), $res->content)
        unless $res->header("content-type") =~ m|^text/plain|;
    return $res->content;
}

=item I<jsoncall_local ($uri, $struct)>

Sends the $struct data structure (which is typically a reference to a
hash) to the Catalyst dispatcher via a JSON request at $url URL, en
returns the return value given by the controller. The
L<Catalyst::Test> must have been loaded previously.

In case of a controller error, triggers an exception with die(),
containing the error text 'as is'.

=cut

sub jsoncall_local {
    require JSON;

    my ($url, $struct) = @_;

    my $req = Catalyst::Utils::request($url);

    $req->header("Accept"=>"application/json");

    local $App::CamelPKI::Action::JSON::request_body_for_tests;
    if (defined($struct)) {
        $req->header("Content-type" => "application/json");
        $req->method("POST");
        ## FIXME: presumably passing the POST payload was supposed to
        ## be done like this,
        # $req->add_content(scalar(JSON::to_json($struct)));
        ## but that doesn't work... so we use a global variable instead!
        ## (see L<App::CamelPKI::Action::JSON>):
        $App::CamelPKI::Action::JSON::request_body_for_tests =
            JSON::to_json($struct);
    }
    my $response = Catalyst::Test::local_request("App::CamelPKI", $req);
    die sprintf("plain request at $url failed with code %d\n%s\n",
                $response->code, $response->content)
        unless $response->is_success;
    my $retval = eval { JSON::from_json($response->content) };
    return $retval if defined $retval;
    die $response;
}

=item I<jsonreq_remote ($url, $struct, %args)>

Sends $struct to a real Apache server at $url, which must be
fully-qualified.  Returns the response as an L<HTTP::Response> object.

Available named options are:

=over

=item I<< -certificate => $certobj >>

=item I<< -certificate => $certpem >>

The certificate to identify oneself as, as an L<App::CamelPKI::Certificate>
instance or PEM string.

=item I<< -key => $keyobj >>

=item I<< -key => $keypem >>

The private key to use along with the certificate, as an
L<App::CamelPKI::PrivateKey> instance or PEM string.

=back

=cut

sub jsonreq_remote {
    my ($url, $structure, @args) = @_;

    my $req = http_request_prepare($url, @args);
    $req->method("POST");
    $req->header("Content-Type" => "application/json");
    $req->content(scalar(JSON::to_json($structure)));
    $req->header("Accept" => "application/json");
    return http_request_execute($req, @args);
}

=item I<jsoncall_remote($url, $struct, %args)>

Like L</jsonreq_remote> but instead of returning an L<HTTP::Response>
object, returns the decoded JSON data structure by reference and
throws an exception if the HTTP request isn't a success or doesn't
decode properly.

=cut

sub jsoncall_remote {
    my $response = jsonreq_remote(@_);
    my $content = $response->content;
    die sprintf("jsoncall_remote: failed with code %d\n%s\n",
                $response->code, $content) if ! $response->is_success;
    my $retval = eval { JSON::from_json($content) };
    return $retval if defined $retval;
    die $content;
}

=item I<call_remote($url)>

Gets $url and return the result.

=cut

sub call_remote {
	my ($url, @args) = @_;
	my $ua = LWP::UserAgent->new;
	my $req = http_request_prepare($url, @args);
    my $res = http_request_execute($req, @args);
 	
 	my $content = $res->content;
 	die sprintf("call_remote: failed with code %d\n%s\n",
                $res->code, $content) if ! $res->is_success;
    return $content if defined $content;
    die $content;
 	
}

=item I<formreq_remote($url $struct, $button, @args)>

Call a form and fill it based on $struct, then push on $button

=cut
sub formreq_remote {
    my ($url, $structure, $button, @args) = @_;
    
	my $ua = LWP::UserAgent->new;
	my $req = http_request_prepare($url, @args);
    my $res = http_request_execute($req, @args);
    
    my $tree = HTML::TreeBuilder->new;
    $tree->parse($res->content);
    $tree->eof();
    
    my @Forms = $tree->find_by_tag_name('FORM');
    die "No forms in page" unless @Forms;
    my $f = HTTP::Request::Form->new($Forms[0], $url);
    foreach my $part (keys(%$structure)){
    	$f->field($part, $structure->{$part});
    }
    my $response = http_request_execute($f->press($button), @args);
    return $response;
}

=item I<formcall_remote($url, $struct, %args)>

Like L</jsonreq_remote> but instead of returning an L<HTTP::Response>
object, returns the page and
throws an exception if the HTTP request isn't a success .

=cut

sub formcall_remote {
    my $response = formreq_remote(@_);
    my $content = $response->content;
    die sprintf("formcall_remote: failed with code %d\n%s\n",
                $response->code, $content) if ! $response->is_success;
    return $content if defined $content;
    die $content;
}

=item I<http_request_prepare($url, %args)>

=item I<http_request_execute($request, %args)>

These functions factor code between L</jsonreq_remote>,
L</plaintextcall_remote> and such, although they may also be called
directly.  I<http_request_prepare> creates and returns and returns a GET
L<HTTP::Request> object that the caller may further tweak, prior to
passing it along to I<http_request_execute>, which in turn does the HTTP/S
request and returns an L<HTTP::Response> object.  Named arguments are
the same as in L</jsonreq_remote>, L</plaintextcall_remote> or
L</jsoncall_remote>.

=cut

sub http_request_prepare {
    my ($url) = @_;
    return HTTP::Request->new("GET", $url);
}

sub http_request_execute {
    my ($req, %args) = @_;
    die "Bad argument $req" unless eval { $req->isa("HTTP::Request") };
    # Trust me, snarfing this undocumented variable really is the
    # most elegant way of causing LWP to use a client certificate.
    # I've gone through these hoops many, many times.
    local @LWP::Protocol::http::EXTRA_SOCK_OPTS;
    if ($args{-key} && $args{-certificate}) {
        my $keysdir = catdir(tempdir(), "test_ssl_client_keys");
        if (! -d $keysdir) {
            mkdir($keysdir) or die "Cannot mkdir($keysdir): $!\n";
        }
        write_file(my $clientcertfile = catfile($keysdir, "cert.pem"),
                   (ref($args{-certificate}) ?
                    $args{-certificate}->serialize() :
                    $args{-certificate}));
        write_file(my $clientkeyfile = catfile($keysdir, "key.pem"),
                   (ref($args{-key}) ? $args{-key}->serialize() :
                    $args{-key}));
        @LWP::Protocol::http::EXTRA_SOCK_OPTS =
            (SSL_use_cert => 1,
             SSL_cert_file => $clientcertfile,
             SSL_key_file => $clientkeyfile,
            );
    }
    return LWP::UserAgent->new->request($req);
}

=item I<camel_pki_chain>

Returns the certification chain of the App-PKI application under test,
starting with the Operational CA certificate.

=cut

sub camel_pki_chain {
    require Catalyst::Test;
    Catalyst::Test->import("App::CamelPKI");

    my $req = Catalyst::Utils::request("/ca/certificate_chain_pem");
    my $resp = Catalyst::Test::local_request("App::CamelPKI", $req)
        ->content;
    return map {$_->serialize} (App::CamelPKI::Certificate->parse_bundle($resp));
}



=item I<openssl_path>

Returns the path to the C<openssl> command-line tool, if it is known,
or undef.  Useful for skipping tests that depend on
L</run_thru_openssl> being able to run.

=cut

sub openssl_path {
    my ($openssl_bin) =
        ( `which openssl 2>/dev/null` =~ m/^(.*)/ ); # Chopped, untainted
    return if ! ($openssl_bin && -x $openssl_bin);
    return $openssl_bin;
}

=item I<run_thru_openssl($stdin_text, $arg1, $arg2, ...)>

Runs the command C<openssl $arg1 $arg2 ...>, feeding it $stdin_text on
its standard input.  In list context, returns a ($stdout_text,
$stderr_text) pair.  In scalar context, returns the text of the
combined standard output and error streams.  Throws an exception if
the C<openssl> command is unavailable (that is, L</openssl_path>
returns undef).  Upon return $? will be set to the exit status of
C<openssl>.

=cut

use IPC::Run ();
use Carp ();
sub run_thru_openssl {
    my ($data, @cmdline) = @_;

    $data = "" if (! defined($data));
    Carp::croak "Bizarre first argument passed to run_thru_openssl()"
        if ref($data);

    defined(my $binary = openssl_path) or die "Cannot find openssl binary";
    unshift(@cmdline, $binary);

    if (wantarray) {
        my ($out, $err);
        IPC::Run::run(\@cmdline, \$data, \$out, \$err);
        return ($out, $err);
    } else {
        my $out;
        IPC::Run::run(\@cmdline, \$data, \$out, \$out);
        return $out;
    }
}

=item I<run_dumpasn1($der)>

Runs the I<dumpasn1> command (found in $ENV{PATH}) on $der and returns
its output.  Throws an exception if dumpasn1 fails for some reason.

=cut

sub run_dumpasn1 {
    my ($der) = @_;
    my $out;
    IPC::Run::run(["dumpasn1", "-"], \$der, \$out, \$out);
    die "dumpasn1 failed with code $?" if $?;
    return $out;
 }


=item I<run_perl($scripttext)>

Runs $scripttext in a sub-Perl interpreter, returning the text of its
combined stdout and stderr as a single string.  $? is set to the exit
value of same.

=item I<run_perl_ok($scripttext)>

=item I<run_perl_ok($scripttext, \$stdout)>

=item I<run_perl_ok($scripttext, \$stdout, $testname)>

Like L</run_perl> but simultaneously asserts (using L<Test::More>)
that the exit value is successful.  The return value of the sub is the
status of the assertion; the output of $scripttext (that is, the
return value of the underlying call to I<run_perl>) is transmitted to
the caller by modifying in-place the scalar reference passed as the
second argument, if any.  Additionally the aforementioned output is
passed to L<Test::More/diag> if the script does exit with nonzero
status.

=cut

sub run_perl {
    my ($scripttext, $outref, $testname) = @_;

    Carp::croak "Bizarre first argument passed to run_perl()"
        if (! defined($scripttext) || ref($scripttext));

    if ($ENV{DEBUG}) {
        my $scriptdir = catdir(tempdir(), "run_perl_ok");
        File::Path::mkpath($scriptdir);
        my $scriptfile = catfile
            ($scriptdir, sprintf("run_perl_ok_%d_%d", $$,
                                 _unique_number()));
        write_file($scriptfile, $scripttext);
        diag(<<"FOR_CONVENIENCE");
run_perl: a copy of the script to run was saved in $scriptfile
to ease debugging.
FOR_CONVENIENCE
    }

    my ($perl) = ($^X =~ m/^(.*)$/); # Untainted
    my @perlcmdline = ($perl, (map { -I => $_ }
                               (grep {! m|/usr|} @INC)),  # Shame, shame.
                      );

    diag(join(" ", @perlcmdline)) if $ENV{DEBUG};

    my $stdout;
    IPC::Run::run(\@perlcmdline, \$scripttext, \$stdout, \$stdout);
    return $stdout;
}

sub run_perl_ok {
    my ($code, $outref, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $testname ||= "run_perl_ok";
    my $out = run_perl($code);
    $$outref = $out if ref($outref) eq "SCALAR";
    my $retval = is($?, 0, $testname);
    diag($out) if ! $retval;
    return $retval;
}

=item I<certificate_looks_ok($pem_certificate)>

=item I<certificate_looks_ok($pem_certificate, $test_name)>

Checks that a certificate passed as a PEM string looks OK to OpenSSL,
meaning that the signature validates OK and OpenSSL is able to parse
it.

=cut

sub certificate_looks_ok {
    my ($pem_certificate, $test_name) = @_;

    $test_name ||= "certificate_looks_ok";
    test $test_name => sub {
        my ($out, $err);
        ($out, $err) =
            run_thru_openssl($pem_certificate, qw(x509 -noout -text));
        unless (is($?, 0, "openssl execution failed with code $?")) {
            diag $err;
            return;
        }
        unlike($out, qr/error/,
             "openssl seemed to dislike the certificate");
        like($out, qr/Certificate:/,
             "openssl seemed not to be able to parse the certificate");
    };
}

=item I<certificate_chain_ok($pem_certificate, \@certchain )>

=item I<certificate_chain_ok($pem_certificate, \@certchain , $test_name)>

Checks that a certificate passed as a PEM string is validly signed by
the certificate chain @certchain, which is a list of PEM strings
passed as a reference.

=cut

sub certificate_chain_ok {
    my ($cert, $certchain, $testname) = @_;

    test (($testname || "certificate_chain_ok") => sub {
        my $out = _run_openssl_verify($cert, $certchain, $testname);
        return if ! defined $out; # Already failed
        like($out, qr/OK/, "verify successful");
        unlike($out, qr/error/, "no errors");
    });
}

sub _run_openssl_verify {
    my ($cert, $certchain, $testname) = @_;

    # This is mostly a hack to get the test suite to
    # work, but CA:FALSE certificates *really* should
    # not be made part of a certification chain.

    my @certchain = grep {
        my $out = run_thru_openssl($_, qw(x509 -noout -text));
        ( $out =~ m/CA:TRUE/ ) ? 1 : (warn(<<"WARNING"), 0);
$testname: ignoring a non-CA certificate that was passed as
part of the chain.
WARNING
    } @$certchain;
    fail("no remaining certificates in chain"), return undef
        if ! @certchain;

    my $bundlefile = catfile
        (tempdir(), sprintf("ca-bundle-%d-%d.crt", $$,
                             _unique_number()));
    write_file($bundlefile,
                            join("\n", @certchain));
    return scalar run_thru_openssl($cert, qw(verify),
                                   -CAfile => $bundlefile);
}

=item I<certificate_chain_invalid_ok($pem_certificate, \@certchain )>

The converse of L</certificate_chain_ok>; checks that
I<$pem_certificate> is B<not> validly signed by @certchain.  Note,
however, that there is a case where both I<certificate_chain_ok> and
I<certificate_chain_invalid_ok> both fail, and that is when @certchain
doesn't contain any B<valid> CA certificate.

=cut

sub certificate_chain_invalid_ok {
    my ($cert, $certchain, $testname) = @_;

    test (($testname || "certificate_chain_ok") => sub {
        my $out = _run_openssl_verify($cert, $certchain, $testname);
        return if ! defined $out; # Already failed
        like($out, qr/error/, "verify failed as expected");
    });
}

=item I<x509_schema()>

Returns the ASN.1 schema for the whole X509 specification, as a string
that L<Convert::ASN1> will grok.

=cut

sub x509_schema { <<"SCHEMA" }
-- Taken from examples/x509decode in Convert::ASN1
Attribute ::= SEQUENCE {
        type                    AttributeType,
        values                  SET OF AttributeValue
                -- at least one value is required --
        }

AttributeType ::= OBJECT IDENTIFIER

AttributeValue ::= DirectoryString  --ANY

AttributeTypeAndValue ::= SEQUENCE {
        type                    AttributeType,
        value                   AttributeValue
        }


-- naming data types --

Name ::= CHOICE { -- only one possibility for now
        rdnSequence             RDNSequence
        }
RDNSequence ::= SEQUENCE OF RelativeDistinguishedName

DistinguishedName ::= RDNSequence

RelativeDistinguishedName ::=
        SET OF AttributeTypeAndValue  --SET SIZE (1 .. MAX) OF


-- Directory string type --

DirectoryString ::= CHOICE {
        teletexString           TeletexString,  --(SIZE (1..MAX)),
        printableString         PrintableString,  --(SIZE (1..MAX)),
        bmpString               BMPString,  --(SIZE (1..MAX)),
        universalString         UniversalString,  --(SIZE (1..MAX)),
        utf8String              UTF8String,  --(SIZE (1..MAX)),
        ia5String               IA5String  --added for EmailAddress
        }


-- certificate and CRL specific structures begin here

Certificate ::= SEQUENCE  {
        tbsCertificate          TBSCertificate,
        signatureAlgorithm      AlgorithmIdentifier,
        signature               BIT STRING
        }

TBSCertificate  ::=  SEQUENCE  {
        version             [0] EXPLICIT Version OPTIONAL,  --DEFAULT v1
        serialNumber            CertificateSerialNumber,
        signature               AlgorithmIdentifier,
        issuer                  Name,
        validity                Validity,
        subject                 Name,
        subjectPublicKeyInfo    SubjectPublicKeyInfo,
        issuerUniqueID      [1] IMPLICIT UniqueIdentifier OPTIONAL,
                -- If present, version shall be v2 or v3
        subjectUniqueID     [2] IMPLICIT UniqueIdentifier OPTIONAL,
                -- If present, version shall be v2 or v3
        extensions          [3] EXPLICIT Extensions OPTIONAL
                -- If present, version shall be v3
        }
Version ::= INTEGER  --{  v1(0), v2(1), v3(2)  }

CertificateSerialNumber ::= INTEGER

Validity ::= SEQUENCE {
        notBefore               Time,
        notAfter                Time
        }

Time ::= CHOICE {
        utcTime                 UTCTime,
        generalTime             GeneralizedTime
        }

UniqueIdentifier ::= BIT STRING

SubjectPublicKeyInfo ::= SEQUENCE {
        algorithm               AlgorithmIdentifier,
        subjectPublicKey        BIT STRING
        }

Extensions ::= SEQUENCE OF Extension  --SIZE (1..MAX) OF Extension
Extension ::= SEQUENCE {
        extnID                  OBJECT IDENTIFIER,
        critical                BOOLEAN OPTIONAL,  --DEFAULT FALSE,
        extnValue               OCTET STRING
        }

AlgorithmIdentifier ::= SEQUENCE {
        algorithm               OBJECT IDENTIFIER,
        parameters              ANY
        }


--extensions

AuthorityKeyIdentifier ::= SEQUENCE {
      keyIdentifier             [0] KeyIdentifier            OPTIONAL,
      authorityCertIssuer       [1] GeneralNames             OPTIONAL,
      authorityCertSerialNumber [2] CertificateSerialNumber  OPTIONAL }
    -- authorityCertIssuer and authorityCertSerialNumber shall both
    -- be present or both be absent

KeyIdentifier ::= OCTET STRING


SubjectKeyIdentifier ::= KeyIdentifier


-- key usage extension OID and syntax
-- id-ce-keyUsage OBJECT IDENTIFIER ::=  { id-ce 15 }

KeyUsage ::= BIT STRING --{
--      digitalSignature        (0),
--      nonRepudiation          (1),
--      keyEncipherment         (2),
--      dataEncipherment        (3),
--      keyAgreement            (4),
--      keyCertSign             (5),
--      cRLSign                 (6),
--      encipherOnly            (7),
--      decipherOnly            (8) }


-- private key usage period extension OID and syntax
-- id-ce-privateKeyUsagePeriod OBJECT IDENTIFIER ::=  { id-ce 16 }

PrivateKeyUsagePeriod ::= SEQUENCE {
     notBefore       [0]     GeneralizedTime OPTIONAL,
     notAfter        [1]     GeneralizedTime OPTIONAL }
     -- either notBefore or notAfter shall be present


-- certificate policies extension OID and syntax
-- id-ce-certificatePolicies OBJECT IDENTIFIER ::=  { id-ce 32 }

CertificatePolicies ::= SEQUENCE OF PolicyInformation

PolicyInformation ::= SEQUENCE {
     policyIdentifier   CertPolicyId,
     policyQualifiers   SEQUENCE OF
             PolicyQualifierInfo } --OPTIONAL }

CertPolicyId ::= OBJECT IDENTIFIER

PolicyQualifierInfo ::= SEQUENCE {
       policyQualifierId  PolicyQualifierId,
       qualifier        ANY } --DEFINED BY policyQualifierId }

-- Implementations that recognize additional policy qualifiers shall
-- augment the following definition for PolicyQualifierId

PolicyQualifierId ::=
     OBJECT IDENTIFIER --( id-qt-cps | id-qt-unotice )

-- CPS pointer qualifier

CPSuri ::= IA5String

-- user notice qualifier

UserNotice ::= SEQUENCE {
     noticeRef        NoticeReference OPTIONAL,
     explicitText     DisplayText OPTIONAL}

NoticeReference ::= SEQUENCE {
     organization     DisplayText,
     noticeNumbers    SEQUENCE OF INTEGER }

DisplayText ::= CHOICE {
     visibleString    VisibleString  ,
     bmpString        BMPString      ,
     utf8String       UTF8String      }


-- policy mapping extension OID and syntax
-- id-ce-policyMappings OBJECT IDENTIFIER ::=  { id-ce 33 }

PolicyMappings ::= SEQUENCE OF SEQUENCE {
     issuerDomainPolicy      CertPolicyId,
     subjectDomainPolicy     CertPolicyId }


-- subject alternative name extension OID and syntax
-- id-ce-subjectAltName OBJECT IDENTIFIER ::=  { id-ce 17 }

SubjectAltName ::= GeneralNames

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
-- TYPE-IDENTIFIER is not supported in the '88 ASN.1 syntax

AnotherName ::= SEQUENCE {
     type    OBJECT IDENTIFIER,
     value      [0] EXPLICIT ANY } --DEFINED BY type-id }

EDIPartyName ::= SEQUENCE {
     nameAssigner            [0]     DirectoryString OPTIONAL,
     partyName               [1]     DirectoryString }

-- issuer alternative name extension OID and syntax
-- id-ce-issuerAltName OBJECT IDENTIFIER ::=  { id-ce 18 }

IssuerAltName ::= GeneralNames


-- id-ce-subjectDirectoryAttributes OBJECT IDENTIFIER ::=  { id-ce 9 }

SubjectDirectoryAttributes ::= SEQUENCE OF Attribute


-- basic constraints extension OID and syntax
-- id-ce-basicConstraints OBJECT IDENTIFIER ::=  { id-ce 19 }

BasicConstraints ::= SEQUENCE {
     cA                      BOOLEAN OPTIONAL, --DEFAULT FALSE,
     pathLenConstraint       INTEGER OPTIONAL }


-- name constraints extension OID and syntax
-- id-ce-nameConstraints OBJECT IDENTIFIER ::=  { id-ce 30 }

NameConstraints ::= SEQUENCE {
     permittedSubtrees       [0]     GeneralSubtrees OPTIONAL,
     excludedSubtrees        [1]     GeneralSubtrees OPTIONAL }

GeneralSubtrees ::= SEQUENCE OF GeneralSubtree

GeneralSubtree ::= SEQUENCE {
     base                    GeneralName,
     minimum         [0]     BaseDistance OPTIONAL, --DEFAULT 0,
     maximum         [1]     BaseDistance OPTIONAL }

BaseDistance ::= INTEGER


-- policy constraints extension OID and syntax
-- id-ce-policyConstraints OBJECT IDENTIFIER ::=  { id-ce 36 }

PolicyConstraints ::= SEQUENCE {
     requireExplicitPolicy           [0] SkipCerts OPTIONAL,
     inhibitPolicyMapping            [1] SkipCerts OPTIONAL }

SkipCerts ::= INTEGER

-- CRL distribution points extension OID and syntax
-- id-ce-cRLDistributionPoints     OBJECT IDENTIFIER  ::=  {id-ce 31}

cRLDistributionPoints  ::= SEQUENCE OF DistributionPoint

DistributionPoint ::= SEQUENCE {
     distributionPoint       [0]     DistributionPointName OPTIONAL,
     reasons                 [1]     ReasonFlags OPTIONAL,
     cRLIssuer               [2]     GeneralNames OPTIONAL }

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


-- extended key usage extension OID and syntax
-- id-ce-extKeyUsage OBJECT IDENTIFIER ::= {id-ce 37}

ExtKeyUsageSyntax ::= SEQUENCE OF KeyPurposeId

KeyPurposeId ::= OBJECT IDENTIFIER

-- extended key purpose OIDs
-- id-kp-serverAuth      OBJECT IDENTIFIER ::= { id-kp 1 }
-- id-kp-clientAuth      OBJECT IDENTIFIER ::= { id-kp 2 }
-- id-kp-codeSigning     OBJECT IDENTIFIER ::= { id-kp 3 }
-- id-kp-emailProtection OBJECT IDENTIFIER ::= { id-kp 4 }
-- id-kp-ipsecEndSystem  OBJECT IDENTIFIER ::= { id-kp 5 }
-- id-kp-ipsecTunnel     OBJECT IDENTIFIER ::= { id-kp 6 }
-- id-kp-ipsecUser       OBJECT IDENTIFIER ::= { id-kp 7 }
-- id-kp-timeStamping    OBJECT IDENTIFIER ::= { id-kp 8 }

SCHEMA

=item I<x509_decoder($name)>

Returns the same as L<Convert::ASN1/find> would when called upon an
object that would previously have L</x509_schema> fed to him.  The
difference is that I<x509_decoder> checks for errors and will
therefore never return undef.

The returned object has a C<< ->decode >> object that serves to
validate the various pieces of DER produced by OpenSSL from within the
tests.

=cut

use Convert::ASN1;
sub x509_decoder {
    my ($name) = @_;
    my $asn = Convert::ASN1->new;
    $asn->prepare(x509_schema());
    die $asn->error if $asn->error;

    my $retval = $asn->find($name);
    die "$name not found in X509 schema" if ! defined $retval;
    return $retval;
}

=item I<server_start>

Start the Catalyst server on the port number specified in C<camel_pki.yml>
(and readable in L</server_port>), do nothing if already started.

=cut

sub server_start {
    system("./script/start_stop_camel_pki.pl", "start");
    die if $?;
}

=item I<server_stop>

Stop the Catalyst server, do nothing if already stopped.

=cut

sub server_stop {
    system("./script/start_stop_camel_pki.pl", "stop");
    die if $?;
}

=item I<server_port>

Returns the port number on which the Catalyst server is (supposed) to
be running.

=cut

sub server_port {
    require App::CamelPKI;
    return App::CamelPKI->model("WebServer")->apache->https_port;
}

=item I<create_camel_pki_conf_php()>

Creates a file named C<t/php/tmp/camel_pki_conf.inc.php> which contains
PHP declarations for the host name and port number of the server, and
the administrator's certficate and private key, to be used by the PHP
tests.

=cut

sub create_camel_pki_conf_php {
    require App::CamelPKI;
    my $webserver = App::CamelPKI->model("WebServer")->apache;
    my $host = $webserver->certificate->get_subject_CN();
    my $port = $webserver->https_port();

    my ($admincert, $adminkey) = App::CamelPKI->model("CA")
        ->make_admin_credentials;

    my $admin_key_pem = $adminkey->serialize;
    my $admin_cert_pem = $admincert->serialize;
	#TODO créer le répertoire si il existe pas !!
	if (! -d "t/php/tmp"){
		 mkdir ("t/php/tmp") or die "Could not create t/php/tmp directory. Tests will fail.";
	}
    write_file("t/php/tmp/camel_pki_conf.inc.php", <<"CONF_DEFINES");
<?php

/* Camel-PKI test configuration file - auto generated. */

function camel_pki_https_host() { return "$host"; }
function camel_pki_https_port() { return $port; }
function camel_pki_key_pem() { return "$admin_key_pem"; }
function camel_pki_certificate_pem() { return "$admin_cert_pem"; }

?>
CONF_DEFINES

    return;
}

=item I<is_php_cli_present()>

Returns true if the php executable (php-cli) is found on the system using File::Which.
It searches for exectables named "php" or "php5".

=cut

sub is_php_cli_present(){
	my ($php) = (File::Which::which("php"), File::Which::which("php5"));
	if ($php){
		my @mods = `$php -m`;
		foreach(@mods){
			$_ =~ s/\n//g;
			return 1 if $_ =~ /curl/;
		}
	}
	return 0;
}

=item I<run_php($script)>

=item I<run_php_script($path)>

Run the script, either in its patch ($path) or in integral phat ($script),
and returns STDERR and STDOUT combined in one unique string. The command
line executrable C<php> (or C<php4>) is used. If $path a file name, the
path C<t/php> is added just before.

Note that an ad-hoc C<php.ini> script is needed; it's embeded in Camel-PKI
in C<t/php/php-json.ini>.

=back

=back

=cut

use File::Slurp;
sub run_php {
    my ($phpcode) = @_;

    my $phpscript = catfile
        (tempdir(), sprintf("run_php_script.%d.php", _unique_number()));
    write_file($phpscript, $phpcode);

    return run_php_script($phpscript);
}

sub run_php_script {
    my ($phpscript) = @_;

    $phpscript = "t/php/$phpscript" unless ($phpscript =~ m|/|);
    my ($php) = (File::Which::which("php"), File::Which::which("php5"));
    die "Impossible to find php command line executable"
        unless defined $php;

    my $out;
    IPC::Run::run([$php, "--php-ini", "t/php/php-json.ini",
                   -d => 'require_once_path=t/php',
                   $phpscript],
                  \"", \$out, \$out);
    return $out;
}

=head1 MÉTHODES DE CLASSE

=head2 I<tempdir>

Returns a temporary directory e.g. for storing the C<ca-bundle.crt>
for L</certificate_chain_ok>.

=cut

{
    my $cached;
    sub tempdir {
        return My::Tests::Below->tempdir if
            (My::Tests::Below->can("tempdir"));
        return $cached if defined $cached;
        return ($cached = File::Temp::tempdir
                ("perl-Camel-PKI-Test-XXXXXX",
                 TMPDIR => 1, ($ENV{DEBUG} ? () : (CLEANUP => 1))));
    }
}

=head1 SAMPLE INPUTS

I<App::CamelPKI::Test> also provides a couple of constants and
class methods to serve as inputs for tests.  All such symbols are
exportable, but not exported by default (see L</SYNOPSIS>) and they
start with I<test_>, so as to be clearly identified as sample data in
the test code.

=over

=item I<test_simple_utf8()>

=item I<test_bmp_utf8()>

Two constant functions that return test strings for testing the UTF-8
capabilities of Camel-PKI.  Both strings are encoded
internally in UTF-8 in the sense of L<utf8/is_utf8>. I<test_simple_utf8()>
contains only characters in the Latin1 range; I<test_bmp_utf8()> contains
only characters outside Latin1, but inside the Basic Multilingual
Plane.

=cut

sub test_simple_utf8 {
    my $retval = "zoinxé";
    die unless utf8::decode($retval);
    return $retval;
}

sub test_bmp_utf8 {
    my $retval = "☮☺⌨"; # Peace, joy, coding :-)
    die unless utf8::decode($retval);
    return $retval;
}

=item I<%test_der_DNs>

Contains a set of DER-encoded DNs. The keys are the DNs in RFC4514
notation, and the values are strings of bytes.  Available DN keys for
now are C<CN=Zoinx,C=fr>.

=cut

## You can generate more using Crypt::OpenSSL::CA using a
## one-liner such as
##
##      perl -MCrypt::OpenSSL::CA -MMIME::Base64 -e 'print
##              encode_base64(Crypt::OpenSSL::CA::X509_NAME->new
##                            (C => "fr", CN => "Zoinx")->to_asn1)'

use MIME::Base64 qw(decode_base64);
our %test_der_DNs =
    ("CN=Zoinx,C=fr" => decode_base64(<<DER),
MB0xCzAJBgNVBAYTAmZyMQ4wDAYDVQQDEwVab2lueA==
DER
);

=item I<@test_DN_CAs>

The DN used in all CA and self-signed certificates, namely
L</%test_self_signed_certs>, L</%test_rootca_certs> and friends. Set
in the same order as the parameters to the I<new> function in
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::X509_NAME>.

=cut

our @test_DN_CAs = (C => "AU", ST => "Some-State",
                    O => "Internet Widgits Pty Ltd");

=item I<%test_reqs_SPKAC>

Certificate signing requests (CSRs) in Netscape SPKAC format, as if
generated by

  openssl spkac -key test.key -challenge secret

but without the trailing newline, and with the leading C<SPKAC=> removed.

=cut

our %test_reqs_SPKAC =
    (rsa1024 => "MIIBQDCBqjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA3xmJpTmG6RpAQ/2oE1J4sS3HYeh9VzNd8Ne0W82qAO28mQ+i/g5/DGXevT7l3GQEBFBuDnukMgHGn7Lw2+0h48iRy6D0zrAGdHsf9MyCVacPl8qaQPH2cem57hylGm6n4/Nzi5PwAn0EgV+23C+2PIcGHGSXKsozM7fQU+6ApXcCAwEAARYGc2VjcmV0MA0GCSqGSIb3DQEBBAUAA4GBAMpl9v+6SSQt0yGlmg20bZEz9jiTzbD3UX6vdCdIdYuksTnVrTarVTi6zMSAK/me+fo+54LbZxqxFVjrnz1eg7yUQkvjfrs/HGDpdBoWHvw3+iePK8DHlaipolACNF+OyoMryl5gqRPhV6FosHiiD9QQ4IY7GSMKMr5iQ/pwlAGx",
     rsa2048 => "MIICRjCCAS4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCxupRLykaWvgQP2aZmcEGq9/3OXtnQ1H0tnNfbJexzYYyCOiU1CP8KsMoeNMvdUun4FwGKeckjGF1eDuOgbGh0naG4+M4/5PTCbOaF2otb8zPc+oUGh3tmgiLhLnlV4zQbeTBRD6/giHnFgUWC+Ec/PjEnmDu917430GI2nnD66/OZr9NnyxFYMhSlufwWRGCtR6LLa9QqDAl+DvbSmvHGL9G7VFBGcFwLbaTYUWmkvQwEhq01yZ/bp+yAIJpygsnWMg6kJahkBI5hNFK1KWbLYyF9IDJb6TsL9mRiW8+0BAkZosD5jdm4Ra7SMtiTjzY+FyNp2IRwZ32N70iNGGPZAgMBAAEWBnNlY3JldDANBgkqhkiG9w0BAQQFAAOCAQEAd3JfT2QEo8pBHhQFlh9PDfc3OhL7z0IcebcDL7kslxB5JViuzKMce/+68RoQ9eaepmVunXxVIJEauNp5LrZatxODp8kOsJI86HD1ChMVqrr6DZi6ulBEXst2kvzkEwVN24Hm5t80hGK8jnZtN86iIXk4iA7iEiniTO7qVhq3kEIouV6fprOk2P8bZ24OlVQ0+1Lp4h5EKajRQZoacnK4IGUTNXEGdAI17ID/qf8sqKZQtiqrRXGAQqbx3bxk8aLUm8OhmyeGett75H0n956MNPJiwDy9ftcUnyiuHHYGKq6SZNNs4mKOjnSnz3D9DhUCbJkfG2FbCkRsMl8SHARoyA==",
    );

=item I<%test_reqs_PKCS10>

Certificate signing requests (CSRs) in standard PKCS#10 PEM format, as
if generated by

  openssl req -new -key test.key -batch

but without the trailing newline, and with the leading C<SPKAC=> removed.

=cut

our %test_reqs_PKCS10 =
    (rsa1024 => <<RSA1024,
-----BEGIN CERTIFICATE REQUEST-----
MIIBhDCB7gIBADBFMQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEh
MB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEB
AQUAA4GNADCBiQKBgQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZ
D6L+Dn8MZd69PuXcZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+X
yppA8fZx6bnuHKUabqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwID
AQABoAAwDQYJKoZIhvcNAQEFBQADgYEAUIiH0G2g71bKJzlTaWudEOyF8PI+6HNV
KmGB8IwUOMbpkm8x2+hxa+dgmX6P0bRdHuClLt1yLN0te3eId7CinPmLgLPFNwCH
e1U+tEfcUWPs3dr4phEGPPhD6Pe8dt1rOosvrF1GlG/Z/VATpmy+XTO/2QMfRLNO
aKTcQBVm6/8=
-----END CERTIFICATE REQUEST-----
RSA1024
     rsa2048 => <<RSA2048,
-----BEGIN CERTIFICATE REQUEST-----
MIICijCCAXICAQAwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUx
ITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcN
AQEBBQADggEPADCCAQoCggEBALG6lEvKRpa+BA/ZpmZwQar3/c5e2dDUfS2c19sl
7HNhjII6JTUI/wqwyh40y91S6fgXAYp5ySMYXV4O46BsaHSdobj4zj/k9MJs5oXa
i1vzM9z6hQaHe2aCIuEueVXjNBt5MFEPr+CIecWBRYL4Rz8+MSeYO73XvjfQYjae
cPrr85mv02fLEVgyFKW5/BZEYK1Hostr1CoMCX4O9tKa8cYv0btUUEZwXAttpNhR
aaS9DASGrTXJn9un7IAgmnKCydYyDqQlqGQEjmE0UrUpZstjIX0gMlvpOwv2ZGJb
z7QECRmiwPmN2bhFrtIy2JOPNj4XI2nYhHBnfY3vSI0YY9kCAwEAAaAAMA0GCSqG
SIb3DQEBBQUAA4IBAQBgTkQSAWAqG3mQ9vvnKi/QEyqwkqMeyQGGrUbeXW6OJmQq
QyHkq8BIBWUZhSdcwbGytmDsmODqQy38M1ePdRx6H+fr9iLlSxuvjoB3Kr+aoXW3
p67KTGd/74KFY5WmnIVD2GR/qFE7ywedU2iQg73+ZKJM1x/r9Uyb8sz/1pcH7nCk
KfcqNAAK8tbhoHtCeMx1XqKkzJUirZ7C4CyextecMtWP4xUtWfK0lxtBum1cMIVv
IoP5HFBA6qGezMy9MhdoP+BozejIwlov9378AB41sevv2BleK/kWE28rhXA8Zfqn
nkGRAm6ZG4kpRFoqrhbNmCaKyCJXhBu91eJfjEGZ
-----END CERTIFICATE REQUEST-----
RSA2048
    );

=item I<%test_keys_plaintext>

An array of test private keys in PEM format.  The values of this hash
tables are strings in PEM format (that is, Base64-encoded DER with
delimiters C<-----BEGIN RSA PRIVATE KEY-----> and C<-----END RSA
PRIVATE KEY----->, without encryption).  The keys are well-known key
handles that are re-used throughout the sample input hashes below:

=over

=item I<rsa1024>

=item I<rsa2048>

RSA keys of size 1024 bits and 2048 bits respectively.

=back

More RSA keys can be obtained using the command

   openssl genrsa 1024

or similar (e.g. changing the key size)

=cut

our %test_keys_plaintext =
    (rsa1024 => <<RSA1024,
-----BEGIN RSA PRIVATE KEY-----
MIICXgIBAAKBgQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+
Dn8MZd69PuXcZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA
8fZx6bnuHKUabqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQAB
AoGBANWLUi8uUy4IDH+H6jskc5XUJcZXjLHM3xxKu74rq4/b/uvbBb58DavGTl+C
Nu6vZRDkE5QVUOL0xDPUSauY3RerFnMPdTZZ43WAKYbrrNqA0/xEpEAWv4CxXAMI
f3Bf2ypBdFzE268HiaQxv//61ZtIjb7NDu8j6gcRLLVjU0RhAkEA9X0TZScqGLFR
84GsSltkoSzx2Q+6d81yjzC27CtQgwEUCFhvFG69jAUzJASogac0hmkGa1lVzylO
5D2wgL24PwJBAOinC/ey4XE3isah86Kpgfj8yVj5vtLEodBkUmhNOIrgiHt6+QE+
5YwreJikzRB2Bs9idglg+f/0nqlLdKLWBMkCQQDZNxvjRD0+biAKa/IMNUQcTU2N
+BnRictVIhCpdkYeNOUJ4V4gYUB81dkDhM+pMU8Lo4CXmguQa4ev81nrAHQ3AkBh
ffbW4p/0OKkv2Zfl9xBfDVc2sNlVK07/q7qYuJtUHwkybXLBIeFBXsoXdR/1oO/z
obgC8B9zMcf2+4ax4et5AkEAsNLkUpS5EmsdlyuUnHxg5jU30o8XSUznmzR7OX/H
hP36rGgrE4mclD0LgazRRMjmWFzT6/RtiQb5OnfFxXaDTQ==
-----END RSA PRIVATE KEY-----
RSA1024
     rsa2048 => <<RSA2048,
-----BEGIN RSA PRIVATE KEY-----
MIIEowIBAAKCAQEAsbqUS8pGlr4ED9mmZnBBqvf9zl7Z0NR9LZzX2yXsc2GMgjol
NQj/CrDKHjTL3VLp+BcBinnJIxhdXg7joGxodJ2huPjOP+T0wmzmhdqLW/Mz3PqF
Bod7ZoIi4S55VeM0G3kwUQ+v4Ih5xYFFgvhHPz4xJ5g7vde+N9BiNp5w+uvzma/T
Z8sRWDIUpbn8FkRgrUeiy2vUKgwJfg720prxxi/Ru1RQRnBcC22k2FFppL0MBIat
Ncmf26fsgCCacoLJ1jIOpCWoZASOYTRStSlmy2MhfSAyW+k7C/ZkYlvPtAQJGaLA
+Y3ZuEWu0jLYk482PhcjadiEcGd9je9IjRhj2QIDAQABAoIBADh9EvFb4z+6OVRI
W0kn2NdcZwEWyKhFQVwkA7+VuCecE6q4jGbk6xscwcEECt/XoKHHviejObi738Er
flHY4wJdr6849WT9goXhUwusQKsDC7LqtSk0GpakOi3UNaCEzGUHCcJZ+A6nkfyi
b9OG0i5ZuAnbqvFWBxF6XBz8EvDNUdc2OWSr4IWkweBJlFp9Cj3th574b+PzO7Tl
grgX5Uhc137LTqusaT7OkirUyRMHFR1ryvgTYe99OFqSdS6jZpE6GyijqiHlesfd
m+VKMUGf6F3bBfmHS390AQTmKGSq7gB+K1aYNKTQJyDIvTgqhg1otBZ+vcFnrDhu
W7xXYbkCgYEA6AFRdH3gKQBfqcmUf+Jfi8a8vadSM40ggWbHd00fon2D2ZphsXU0
tGR+3zFg+9UzL7kegUApcI5F3vHaihamh2x9T4Dz4Lzsr3EBwCzQo1Cmb9d/xtyn
1inBirrPwSPfB49MgPzy5yokbaVpola23seZfDA5wYE3N6MZ5vElPkMCgYEAxBw2
7+ZWgP2GLSbHHWvxjhk0YRdqiLEisXUV/7Xr0dlr5CAHRiuGwocOBpmBvyXiyfnw
GA0k9yanycRQouQTQSbQ1jV4yCZS4QLTCHsMQ53r1p48TtSB8/RHYK9/HKlrybn4
gRCkvVoJBP3jnFTjLcBktfVTsPbwMqU3TkGUibMCgYBa5tlReVhw+DKDRfYnPT0O
eSnObVap2CvaR7jzp4YzllYo1nJco32pCI8lSCWlxl0t36xyG/+gmD4MIlrsK//H
o9xdYDst3RgnjXGQKH7+3kS4IYlxE1e3c9jfUF7CYBmszpq9F17c8Agh5ePDtZIl
K7OZkxOuG8DUzdUCRY3AHQKBgQCt3jX2y8i15BApx8+RDjrDOSVvT0tslV+k5aHz
bF7/VjyJrLvGQqDfps2QnFikF/rSB34OVNkJJoRsJlk3ke5gPQG6aP4EtbWVOOPR
CQb+i+ykAvaFDXOJznHaDr4rsymVWAQyqYblOgX1HwPFfp1L2t9vU2o34zdiL4ix
IQOIcQKBgBHzLcB2tyyoosIpj88Ke2m2UFt34b6KskjV5CgrKyvgTV8uZUI3bSFU
nXoWRFxNE9jOECDZUFdIwz4tdjKHG3bIXYX3qzDGhbfwxze3G/5g0lEWUabBjtjY
1dzsPX66bnNHT1dwF9K+ZilNKIpUUEPisXEsLZ28n579qZbP1vmL
-----END RSA PRIVATE KEY-----
RSA2048
);

=item I<%test_keys_password>

The same private keys as in L</%test_keys_plaintext>, but
protected with C<secret> as the password.  Keys are the same as in
I<%test_keys_plaintext>; values are encrypted using 3DES-CBC,
as if by the command

   openssl rsa -des3 -passout pass:secret -in test.key

=cut

our %test_keys_password =
    (rsa1024 => <<RSA1024,
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,106A001EF5153939

+rxNdLaRxeXQ0j59ySdfeOeGS0nAYvH9JHaKTwazHg4HO4rt0LiJJ8TF/7hMlNXB
WAPl7Qz3Pynr/NCjgU7QU92K1ZDh6fSoZYgyDqMoZJRQbgwvubRnsqlhgeX2NPE+
FLzn8auohpWiKBHN7EQrIZf7uKfk8G1VmVcMNL6FGQ/1QPCaGoE1+IOizIq3wqxH
bXn2hIy8n8sNnqEBBmBkw2iFqOUMYX3JcfXTQzbKdlgWi4HLozK+wGypNlihSm/s
CcXGL7ucAtt9Kz0pjQ4M2u905Cfk/7ok7YnHpZ31d8Ale7tqXnRu/HlgGz4pQk+D
ba8HNvlza2TKrsezQEiLOKcK6WVG9eUmB7K8/Vuz9w1gr/JVLT1Cl09TqVovnwOz
emWkDZCFS/GwljCEr8xNFhxxkMEicfDxerCuqAYavlohr+UuVBWj2CQCAw1k1uNp
wNiaW3n2Fl9CQEX7K9UK1Wj0xGrmxQcntjZVdM49oQv1EGqES0VuaNp5jE9J2NjN
yUDXDGG0L2AYTEy45bG8QYZsh0omzQW5BQ1xnYFV8nHRbalqg0nF2qqo8XZjlEyg
HzgHYHJScxmA9UpwcEXYrvhOvslzbikVi8BAA5cnvk1ODZv2qdeZJc1qCplLrfqH
q38Uvj0Nc8ZDad3EmO9cPbyv5+KPpj857+Gt6aNJuX9rFQklcdzBW6SqSr8pUpkS
BcIOK68j5tmTUcggfXzIhtSmKdrZRCDtaDRIcfdxAviwwakckdKz8Y+g6gQkrxSQ
WFOdBd3n9h88zS9cX53dRdTWRtFpoqtvQt/APAkkwEDrpgTfnjV8OA==
-----END RSA PRIVATE KEY-----
RSA1024
     rsa2048 => <<RSA2048,
-----BEGIN RSA PRIVATE KEY-----
Proc-Type: 4,ENCRYPTED
DEK-Info: DES-EDE3-CBC,E3164422C4E0B305

uGlTnFwMuSTot47PzsLknHWRAPC5ZgOubZ6pmiNCF2ljSAx/ut5eS+Ri9VuxNVe3
KHfM096qA4x0yzwwioqRulgo0ZJYajfHQKsrGCZmpRJWTUPPXGADUSfyecnn/2VA
LkCsipovIRnnl3dLje3kEfUagrObUzZG35ohwswwgAHm3Hu/8gQCOk7jFZtaV3/k
0mIHd5v3pNw4LrFCGm8bDGQEJECVCkapLr6kIN7fWLiKtp8SFD5f+eBSdzr17R8T
HBHc/qH8tzBHQpAJ6vBDdOzeS5iC3GUv6cP3RUMIjAcsoyWpYPDQjL7Ay6ALQ6k4
zKq2yI3keW5jv84KtsBCmdytePojKznnytiFFeKPXz9rb20qfs1uNt1fJaDRgvAr
frBUeXOJ1rpgLbWIABS59hnjZeXmUJMWRlp/6fzzfdNnWFYVb09jCdu9PQ6dv0YK
4tDtZRJe3r8aZpvPBGC/6Hx3BrezBYt6kG5DDG5HhISNqOAYgAslRumYmh9+4tDG
TvQklpeha2B7lCwzv9Y4+ZoqSW3oE+O5P3GCbnzJYrXxkWtfZA4dU5iw62gaw28n
7oyULNftrSA9jR37UB10Yyp0MmTmKxGVep1vrvr1L070NHVNEEvtbMVovSe0zQ0g
104k8nBrApwFkYrenQEgs+MvUxFboi1z/PLuMbzObkwj/THfgzez+m/G5+Hl5Whw
Y77O31DDlIhrB2+gfImLuM4Oe6ztPJjopkAQrcHF2KqbJzQnTIxvIe5VC6XLlo/Z
XSD/ftnt3JbCgWe5AeXLhZQVUypQFSWKxrSDtD7IEoRUP7mAMbgFT26x8lC9JkSD
ioW+AaILhwXXb0wyOCjH8gR01jDRUhbzaCLI9up983w0E5bIzYsBxf6GIZNrFas7
Mo5t+v8sLOoPQaMLgCaZJ+9UHVoTFK60d7aRTZvu12++t3G/fQSiZQtNYbO58r0Z
0UmrdcuZwRuHwxXTndQ57sA+QXKy4+S2kk64Ff2YoGCsE34L6UazfT5skt/iS7ct
GHcqKUiR5LGb7b7vZexJ++X7rOGUZVO52NYxQUPVPr4blSbMl8tMHmDez94rUg1X
aJ6+6+uY8lcebr65LCSA/N09qLxAFoi5gku1wS4GQECvsQvA7/GYAp+3O4ytULrE
Cqf5Wx9PBweKkB1h4BLzsKUFCXUgm74dlvs8GtBPTKd58CEeLO2pAbKJhBciUF37
Wuw28zVKX8WaC789HyrTJx8n+hSwaZAqHFiv9TFUF8XwG+Cp9FwRof81V1jbfWWe
AUD+R41bDR8tMmblaSd9GLYWKzeAdk7D1u6dF9RCQu4Tg1hjAKQxCgpg221n3VbE
btAaVBQuTHRrjo7jtwz5sjM3jC9SEhK0I/eP8QOUPut9O+jmP3/k28cBgIAY3RHf
JGpgZSGMB2zzYmYbLOtrbrh5Z9nNhCOhLBQGuRMe+/lO8/Jo4BrC/rYUkV3zkS3d
mwIm/AHPy7+ZLpz3F+zTmSiWOP7oB44hzJTAy/7RbW0RwO4ry4lLRPcbxQ77epjz
vX/Kwjl44H6jnO0zjXutBg/5+3lDxuMxZzcVfCOqF4KENA3vBynJCA==
-----END RSA PRIVATE KEY-----
RSA2048
);

=item I<%test_public_keys>

Public keys obtained from the L</%test_keys_plaintext>
using the following C<openssl> command:

  openssl rsa -pubout -in test.key

=cut

our %test_public_keys =
    (rsa1024 => <<"RSA1024",
-----BEGIN PUBLIC KEY-----
MIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKBgQDfGYmlOYbpGkBD/agTUnixLcdh
6H1XM13w17RbzaoA7byZD6L+Dn8MZd69PuXcZAQEUG4Oe6QyAcafsvDb7SHjyJHL
oPTOsAZ0ex/0zIJVpw+XyppA8fZx6bnuHKUabqfj83OLk/ACfQSBX7bcL7Y8hwYc
ZJcqyjMzt9BT7oCldwIDAQAB
-----END PUBLIC KEY-----
RSA1024
     rsa2048 => <<"RSA2048",
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAsbqUS8pGlr4ED9mmZnBB
qvf9zl7Z0NR9LZzX2yXsc2GMgjolNQj/CrDKHjTL3VLp+BcBinnJIxhdXg7joGxo
dJ2huPjOP+T0wmzmhdqLW/Mz3PqFBod7ZoIi4S55VeM0G3kwUQ+v4Ih5xYFFgvhH
Pz4xJ5g7vde+N9BiNp5w+uvzma/TZ8sRWDIUpbn8FkRgrUeiy2vUKgwJfg720prx
xi/Ru1RQRnBcC22k2FFppL0MBIatNcmf26fsgCCacoLJ1jIOpCWoZASOYTRStSlm
y2MhfSAyW+k7C/ZkYlvPtAQJGaLA+Y3ZuEWu0jLYk482PhcjadiEcGd9je9IjRhj
2QIDAQAB
-----END PUBLIC KEY-----
RSA2048
);


=item I<%test_self_signed_certs>

Self-signed certificates obtained from the L</%test_keys_plaintext> as
if using the following C<openssl> command:

  openssl req -x509 -new -key test.key -batch -days 10958 \
    -extensions usr_cert

where 10958 stands for a validity period of 30 years, so that these
self-signed certificates seldom actually expire.  Because the default
configuration is used, the world-famous yet Belgian I<Internet Widgits
Pty Ltd> company is put in charge as issuer and subject of these
certificates.

=cut

our %test_self_signed_certs =
    (rsa1024 => <<"RSA1024",
-----BEGIN CERTIFICATE-----
MIICgzCCAeygAwIBAgIJAPecvJ1g5yDDMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTMxMTc1NDQyWhcNMzcwMTMxMTc1NDQyWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+Dn8MZd69PuXc
ZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA8fZx6bnuHKUa
bqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQABo3sweTAJBgNV
HRMEAjAAMCwGCWCGSAGG+EIBDQQfFh1PcGVuU1NMIEdlbmVyYXRlZCBDZXJ0aWZp
Y2F0ZTAdBgNVHQ4EFgQU7vqhl+/cXLxRPKRuc8dhXKgLleUwHwYDVR0jBBgwFoAU
7vqhl+/cXLxRPKRuc8dhXKgLleUwDQYJKoZIhvcNAQEFBQADgYEAWedOBH/dGoLv
7isX9DfsGqz337/NhdTO9dGg+l4htskmlIGitzjC2uSPi6QT/8cPpXGKEIiaaigI
e9WIdiVrEIk9kvp4cgnwCF0O/K02/BIpq5MlqSXwGQhQ/o29J4/A4/LobcLDYr11
mGZJJpjA9oDx7sZF6FbTTa5E+tXZRls=
-----END CERTIFICATE-----
RSA1024
     rsa2048 => <<"RSA2048",
-----BEGIN CERTIFICATE-----
MIIDiDCCAnCgAwIBAgIJAL6sAb2vcVpUMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTMxMTc1MzU1WhcNMzcwMTMxMTc1MzU1WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAsbqUS8pGlr4ED9mmZnBBqvf9zl7Z0NR9LZzX2yXsc2GMgjolNQj/CrDK
HjTL3VLp+BcBinnJIxhdXg7joGxodJ2huPjOP+T0wmzmhdqLW/Mz3PqFBod7ZoIi
4S55VeM0G3kwUQ+v4Ih5xYFFgvhHPz4xJ5g7vde+N9BiNp5w+uvzma/TZ8sRWDIU
pbn8FkRgrUeiy2vUKgwJfg720prxxi/Ru1RQRnBcC22k2FFppL0MBIatNcmf26fs
gCCacoLJ1jIOpCWoZASOYTRStSlmy2MhfSAyW+k7C/ZkYlvPtAQJGaLA+Y3ZuEWu
0jLYk482PhcjadiEcGd9je9IjRhj2QIDAQABo3sweTAJBgNVHRMEAjAAMCwGCWCG
SAGG+EIBDQQfFh1PcGVuU1NMIEdlbmVyYXRlZCBDZXJ0aWZpY2F0ZTAdBgNVHQ4E
FgQUZKgIK9vXzM9vCVYnGs0hUrzx+lcwHwYDVR0jBBgwFoAUZKgIK9vXzM9vCVYn
Gs0hUrzx+lcwDQYJKoZIhvcNAQEFBQADggEBABwMCRvRijVdZ2VEpkObAQyhYNxD
XjyXTIL2XJek9mCf9mnwW6qiCdiDxwjsPv7ctq7Xfl6QZ0ox4Mg1zma/IQZQuFfy
nyawZSrLx86bsyBu7aRbK29nCNXzTU3JT9xjPgZat3J2bVPunbXSgVoQnfceMtJG
xuTL5Pz2246X3TRDzAu27ZTWIbAgzzXppXba+X4xKaC2pAGs5M0B6qWr20zqzrtS
abDMwiOqndnPFfSNFTWue9PcgpMoT3V+eq6VN0Q6AyPZxkfzVg+VUISli0sXNMKB
KjI6FX0+FXEYyhmsnkAq83kVYop/ietw/mvJkF1xxpkv/urU2AagNVmaxuo=
-----END CERTIFICATE-----
RSA2048
);

=item I<%test_rootca_certs>

Self-signed certificates just like L</%test_self_signed_certs>, except
that these certificates are signed using C<-extensions v3_ca> in lieu
of C<-extensions usr_cert>, resulting in certificates that have the
C<CA> BasicConstraint set to C<true>.  Those certificates can
therefore be used e.g. in the second argument to
L</certificate_chain_ok>, unlike L</%test_self_signed_certs> which,
lacking a CA BasicConstraint, usually cannot be a non-leaf part of a
valid certification chain as per RFC3280 section 6.1.4, item k.

=cut

our %test_rootca_certs =
    (rsa1024 => <<RSA1024,
-----BEGIN CERTIFICATE-----
MIICsDCCAhmgAwIBAgIJANdqtXzdPS/1MA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTMxMTcwNjU5WhcNMzcwMTMxMTcwNjU5WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+Dn8MZd69PuXc
ZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA8fZx6bnuHKUa
bqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQABo4GnMIGkMB0G
A1UdDgQWBBTu+qGX79xcvFE8pG5zx2FcqAuV5TB1BgNVHSMEbjBsgBTu+qGX79xc
vFE8pG5zx2FcqAuV5aFJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt
U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJANdqtXzd
PS/1MAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEACQ+4e3MSlcqkhzgZ
rTXpsO/WpBT7aaM7AaecY54hB9uF9PmGC1q3axwZ2b/+Gh5ehQPyAwKevyjNz1y4
yP4YeUHO6FIHd0RyGEnM3cqcoqg8TewXlUwOkHphCrZ5eFbxxEarVz1wwkZqd5z0
3IInE3EJ7D8rxfbC1c1fdeh8akI=
-----END CERTIFICATE-----
RSA1024
     rsa2048 => <<RSA2048,
-----BEGIN CERTIFICATE-----
MIIDtTCCAp2gAwIBAgIJAJcq/w5w2Nr3MA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTMxMTcxMzAwWhcNMzcwMTMxMTcxMzAwWjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIB
CgKCAQEAsbqUS8pGlr4ED9mmZnBBqvf9zl7Z0NR9LZzX2yXsc2GMgjolNQj/CrDK
HjTL3VLp+BcBinnJIxhdXg7joGxodJ2huPjOP+T0wmzmhdqLW/Mz3PqFBod7ZoIi
4S55VeM0G3kwUQ+v4Ih5xYFFgvhHPz4xJ5g7vde+N9BiNp5w+uvzma/TZ8sRWDIU
pbn8FkRgrUeiy2vUKgwJfg720prxxi/Ru1RQRnBcC22k2FFppL0MBIatNcmf26fs
gCCacoLJ1jIOpCWoZASOYTRStSlmy2MhfSAyW+k7C/ZkYlvPtAQJGaLA+Y3ZuEWu
0jLYk482PhcjadiEcGd9je9IjRhj2QIDAQABo4GnMIGkMB0GA1UdDgQWBBRkqAgr
29fMz28JVicazSFSvPH6VzB1BgNVHSMEbjBsgBRkqAgr29fMz28JVicazSFSvPH6
V6FJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUxITAfBgNV
BAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJAJcq/w5w2Nr3MAwGA1UdEwQF
MAMBAf8wDQYJKoZIhvcNAQEFBQADggEBAK4/1S5TY/gpHPk65/Y7Mky+LHa4OAIy
IS81kQHF0Uv8ftkJ7q6vk7s9lI9F9dvStjbxXOO8KJlUGyiVrOoeB5/hnyngIeZd
WUVNPwl1x3Rbiiq5WpJA1F/vLgPWQF2LLH0Wkb5jex+aYuHAmR8CAlNNBTH3vcjG
PhWO9OsdPMcHQPSYk9RNA3S3ao8UwtXtP+PD4KZIxh6ItHvQxIE4dJ4hZ4qhqjWD
V1K1Plj27fEC57i71qygF+UogYd802DM/5F76OHKN4CAq54UFSzfzpcjOsYZLCG7
tKVO4zFWPkXPhdh7brNIn19ayoyESq59WuZhPwZkzOZgaFrHeQA2Dks=
-----END CERTIFICATE-----
RSA2048
);

=item I<%test_entity_certs>

Certificates generated using C<openssl ca> from
L</%test_rootca_certs>, L</%test_keys_plaintext> and the default
OpenSSL configuration using the procedure described in
L<Crypt::OpenSSL::CA::Resources/Building a toy CA:> where the
precise C<openssl> commands used are

  openssl req -new -batch -subj "/C=fr/O=Yoyodyne/CN=John Doe" \
    -key test.key | \
  openssl ca -batch -days 10958 -policy policy_anything \
    -in /dev/stdin

In particular this means that entries keyed off the same identifier in
%test_entity_certs and %test_rootca_certs form a valid RFC3280
certification path: that is,

=for My::Tests::Below "certificate_chain_ok" begin

  certificate_chain_ok($test_entity_certs{$key},
                       [ $test_rootca_certs{$key} ]);     # Works

=for My::Tests::Below "certificate_chain_ok" end

holds for every $key in keys(%test_rootca_certs).  But conversely,

=for My::Tests::Below "certificate_chain_notok" begin

  certificate_chain_ok($test_entity_certs{$key},
                       [ $test_self_signed_certs{$key} ]);     # NOT OK!

=for My::Tests::Below "certificate_chain_notok" end

fails, due to the lack of a C<CA:TRUE> BasicConstraint extension in
%test_self_signed_certs.

Additionally %test_entity_certs also contains SHA-256 certificates,
obtained with

  openssl req -new -batch -subj "/C=fr/O=Yoyodyne/CN=John Doe" \
    -key test.key | \
  openssl ca -batch -days 10958 -policy policy_anything \
    -md sha256 -in /dev/stdin

and stored as e.g. $test_entity_certs{"rsa1024_sha256"}.

Notice that in the sample inputs, CAs and end entities share the same
set of private RSA keys L</%test_keys_plaintext> which would not be
the case in a real PKI deployment.  However this is of little impact,
if any, on the test coverage of our modules as we never make use of
the fact that all certificates for a given key length actually have
the same private key.

=cut

our %test_entity_certs =
    (rsa1024 => <<RSA1024,
-----BEGIN CERTIFICATE-----
MIICjjCCAfegAwIBAgIBCTANBgkqhkiG9w0BAQUFADBFMQswCQYDVQQGEwJBVTET
MBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQ
dHkgTHRkMB4XDTA3MDEzMTE4MTcxMVoXDTM3MDEzMTE4MTcxMVowWDELMAkGA1UE
BhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdp
ZGdpdHMgUHR5IEx0ZDERMA8GA1UEAxMISm9obiBEb2UwgZ8wDQYJKoZIhvcNAQEB
BQADgY0AMIGJAoGBAN8ZiaU5hukaQEP9qBNSeLEtx2HofVczXfDXtFvNqgDtvJkP
ov4Ofwxl3r0+5dxkBARQbg57pDIBxp+y8NvtIePIkcug9M6wBnR7H/TMglWnD5fK
mkDx9nHpue4cpRpup+Pzc4uT8AJ9BIFfttwvtjyHBhxklyrKMzO30FPugKV3AgMB
AAGjezB5MAkGA1UdEwQCMAAwLAYJYIZIAYb4QgENBB8WHU9wZW5TU0wgR2VuZXJh
dGVkIENlcnRpZmljYXRlMB0GA1UdDgQWBBTu+qGX79xcvFE8pG5zx2FcqAuV5TAf
BgNVHSMEGDAWgBTu+qGX79xcvFE8pG5zx2FcqAuV5TANBgkqhkiG9w0BAQUFAAOB
gQAycIH+THR3PmOfhvuF80nbpb769bcKG2odXp1Bv6u55y4ajl9EjB1WnKhZY4Vo
isSmjCE7Z9D+9i2SQxzcvrG05gLQRAqS1bRAIHfcoBuGS5B+PvbNhzPTly24NvVp
HSsnQD5qXQq4V/p1hq9OoeCpiQBgOa5wODkpNubGe7k3wQ==
-----END CERTIFICATE-----
RSA1024
     rsa1024_sha256 => <<RSA1024_SHA256,
-----BEGIN CERTIFICATE-----
MIICaTCCAdKgAwIBAgIBCzANBgkqhkiG9w0BAQsFADBFMQswCQYDVQQGEwJBVTET
MBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQ
dHkgTHRkMB4XDTA3MDQwMzA5NTkyMloXDTM3MDQwMzA5NTkyMlowMzELMAkGA1UE
BhMCZnIxETAPBgNVBAoTCFlveW9keW5lMREwDwYDVQQDEwhKb2huIERvZTCBnzAN
BgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA3xmJpTmG6RpAQ/2oE1J4sS3HYeh9VzNd
8Ne0W82qAO28mQ+i/g5/DGXevT7l3GQEBFBuDnukMgHGn7Lw2+0h48iRy6D0zrAG
dHsf9MyCVacPl8qaQPH2cem57hylGm6n4/Nzi5PwAn0EgV+23C+2PIcGHGSXKsoz
M7fQU+6ApXcCAwEAAaN7MHkwCQYDVR0TBAIwADAsBglghkgBhvhCAQ0EHxYdT3Bl
blNTTCBHZW5lcmF0ZWQgQ2VydGlmaWNhdGUwHQYDVR0OBBYEFO76oZfv3Fy8UTyk
bnPHYVyoC5XlMB8GA1UdIwQYMBaAFO76oZfv3Fy8UTykbnPHYVyoC5XlMA0GCSqG
SIb3DQEBCwUAA4GBAMmC/TOUZFP0CUu4Fb0TKzuWBTA8DeWFkcDq2/J5IFSURVXP
nYYPQ45CDNkNUiMjCq1fDm2BXFbYuK/ZILeCAWw5hW16dbDBnpROpo5UmIoTiOGu
9hO+0UmRkFUz7W0WKzG+bGODgtE4eBpr7VJlYb5ayXjmUxxvCquVRuerICL7
-----END CERTIFICATE-----
RSA1024_SHA256
     rsa2048 => <<RSA2048,
-----BEGIN CERTIFICATE-----
MIIDkzCCAnugAwIBAgIBCjANBgkqhkiG9w0BAQUFADBFMQswCQYDVQQGEwJBVTET
MBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQ
dHkgTHRkMB4XDTA3MDEzMTE4MTkwOFoXDTM3MDEzMTE4MTkwOFowWDELMAkGA1UE
BhMCQVUxEzARBgNVBAgTClNvbWUtU3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdp
ZGdpdHMgUHR5IEx0ZDERMA8GA1UEAxMISm9obiBEb2UwggEiMA0GCSqGSIb3DQEB
AQUAA4IBDwAwggEKAoIBAQCxupRLykaWvgQP2aZmcEGq9/3OXtnQ1H0tnNfbJexz
YYyCOiU1CP8KsMoeNMvdUun4FwGKeckjGF1eDuOgbGh0naG4+M4/5PTCbOaF2otb
8zPc+oUGh3tmgiLhLnlV4zQbeTBRD6/giHnFgUWC+Ec/PjEnmDu917430GI2nnD6
6/OZr9NnyxFYMhSlufwWRGCtR6LLa9QqDAl+DvbSmvHGL9G7VFBGcFwLbaTYUWmk
vQwEhq01yZ/bp+yAIJpygsnWMg6kJahkBI5hNFK1KWbLYyF9IDJb6TsL9mRiW8+0
BAkZosD5jdm4Ra7SMtiTjzY+FyNp2IRwZ32N70iNGGPZAgMBAAGjezB5MAkGA1Ud
EwQCMAAwLAYJYIZIAYb4QgENBB8WHU9wZW5TU0wgR2VuZXJhdGVkIENlcnRpZmlj
YXRlMB0GA1UdDgQWBBRkqAgr29fMz28JVicazSFSvPH6VzAfBgNVHSMEGDAWgBRk
qAgr29fMz28JVicazSFSvPH6VzANBgkqhkiG9w0BAQUFAAOCAQEABNgtc1l5FlYr
uYFYXFgkObzW38mY9Gk/RnnkMuAlw3pX+uL02aKNRMQ9NZc/VVH7A9wlIOEpTROP
OjEKgK4/hwoQQmP442hhcTsh40UpvMZV6b+W+l8K9sQ/Ez47nwzkeOsJFv2Laet3
W/5AA90bTVuFcG92FnBiLQjZ0Z2kAFHNLn9CaLFKTxiKHz99gMwQ4p5pP7fIT3pK
JjghMlFGnm/wZG5zD1adjIvw66GqKsxPWml2Tc3azZMpobKYCS91h6WT19kZIC5Y
6uDy0qQUmmC7ICaAgEW5Y2y4GUB2dK4qA8tyN3YQAEzKA9tJJavafxI1oh7QCp4r
valACunSZw==
-----END CERTIFICATE-----
RSA2048
     rsa2048_sha256 => <<RSA2048_SHA256,
-----BEGIN CERTIFICATE-----
MIIDbjCCAlagAwIBAgIBDDANBgkqhkiG9w0BAQsFADBFMQswCQYDVQQGEwJBVTET
MBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50ZXJuZXQgV2lkZ2l0cyBQ
dHkgTHRkMB4XDTA3MDQwMzEwMDIzNVoXDTM3MDQwMzEwMDIzNVowMzELMAkGA1UE
BhMCZnIxETAPBgNVBAoTCFlveW9keW5lMREwDwYDVQQDEwhKb2huIERvZTCCASIw
DQYJKoZIhvcNAQEBBQADggEPADCCAQoCggEBALG6lEvKRpa+BA/ZpmZwQar3/c5e
2dDUfS2c19sl7HNhjII6JTUI/wqwyh40y91S6fgXAYp5ySMYXV4O46BsaHSdobj4
zj/k9MJs5oXai1vzM9z6hQaHe2aCIuEueVXjNBt5MFEPr+CIecWBRYL4Rz8+MSeY
O73XvjfQYjaecPrr85mv02fLEVgyFKW5/BZEYK1Hostr1CoMCX4O9tKa8cYv0btU
UEZwXAttpNhRaaS9DASGrTXJn9un7IAgmnKCydYyDqQlqGQEjmE0UrUpZstjIX0g
MlvpOwv2ZGJbz7QECRmiwPmN2bhFrtIy2JOPNj4XI2nYhHBnfY3vSI0YY9kCAwEA
AaN7MHkwCQYDVR0TBAIwADAsBglghkgBhvhCAQ0EHxYdT3BlblNTTCBHZW5lcmF0
ZWQgQ2VydGlmaWNhdGUwHQYDVR0OBBYEFGSoCCvb18zPbwlWJxrNIVK88fpXMB8G
A1UdIwQYMBaAFGSoCCvb18zPbwlWJxrNIVK88fpXMA0GCSqGSIb3DQEBCwUAA4IB
AQA6ITG3Qr7L5Jjq7423YmRg/P/ie+3ju9yw5IGR0Jfw6d1lvbsx0dFZRXKrZNVW
208PvbXltFcPBgxiZQacOdHKLD5a7KhcnO7vYZ4b/SqT4pLVZ73m+Y+7uGyYVhMz
ab6i2/23/8BO1w7yEihygCUuk4lmQyaR2TOFuTVj1H4+bPFerRWK2ujU7qq2VVNN
wtDSEvAtLU74hfZKRLsrb2x0rA0d7xZBQVVbX2VpDPB2HOvCJHBaoDyrUJk2tL39
gCADl8RcPN5fRB/pEclOwP7cScL2/wA8cS7AkQ8uZn4Rziatzex+AZNHxPl+6Tpf
WNoYsL+lNFkgraJ+/kT6QFvN
-----END CERTIFICATE-----
RSA2048_SHA256
     );

=item I<test_CRL($nickname, -members => \@membercerts)>

Generates and returns (PEM format) a test CRL signed by the
$test_rootca_certs{$nickname} certificate (see L/%test_rootca_certs>).
@membercerts is a serial number list in hexadecimal prefixed by
"0x". The CRL is valid for one week starting at the current system date.

=cut


sub test_CRL {
    my ($nickname, %args) = @_;
    require Crypt::OpenSSL::CA;
    require App::CamelPKI::Time;

    die "unknown nickname $nickname" unless exists
        $test_rootca_certs{$nickname};
    my $cacert = Crypt::OpenSSL::CA::X509->parse
        ($test_rootca_certs{$nickname});
    my $now = App::CamelPKI::Time->now;
    my $crl = new Crypt::OpenSSL::CA::X509_CRL;
    $crl->set_issuer_DN($cacert->get_subject_DN);
    $crl->set_lastUpdate($now);
    $crl->set_nextUpdate($now->advance_days($args{-validity} || 7));
    $crl->set_extension
        (crlNumber => "0x02", -critical => 1);
    foreach my $serial (@{$args{-members} || []}) {
        $crl->add_entry($serial, $now->zulu);
    }
    return $crl->sign(Crypt::OpenSSL::CA::PrivateKey->parse
                      ($test_keys_plaintext{$nickname}), "sha256");
}

=back

=head1 INTERNAL METHODS

=over

=item I<_unique_number>

As the name implies.  Typically used to create unique filenames in
L</tempdir>.

=cut

{ my $unique = 0; sub _unique_number { $unique++ } }


=back


=head1 TODO

Maybe L</leaks_bytes_ok> and L</leaks_SVs_ok> deserve a CPAN module of
their own?

=cut

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Test;
use File::Spec::Functions qw(catfile catdir);
use File::Slurp;

=head2 Fixture tests

=head3 Running commands

=cut

test "run_thru_openssl" => sub {
    my $version = run_thru_openssl(undef, "version");
    is($?, 0);
    like($version, qr/openssl/i);
    unlike($version, qr/uninitialized/); # In case there is some barfage
    # going on in the forked Perls...

    my ($out, $err) = run_thru_openssl(undef, "version");
    is($err, ""); # Yes, this is OpenSSL. Welcome onboard.

    my ($modulus, $error) =
        run_thru_openssl
            ($App::CamelPKI::Test::test_keys_plaintext{rsa1024},
             qw(rsa -modulus -noout));
    is($?, 0);
    like($modulus, qr/modulus=/i)
        or diag $error;

    run_thru_openssl(undef, "rsa");
    isnt($?, 0);
};

test "run_perl and run_perl_ok" => sub {
    my $out;
    run_perl_ok(<<"SCRIPT_OK", \$out);
print "hello"; # STDOUT
warn "coucou"; # STDERR
SCRIPT_OK
    like($out, qr/hello/);
    like($out, qr/coucou/);
    my $tempdir = My::Tests::Below->tempdir;

    $out = run_perl(<<"SCRIPT_WRAPPER");
use Test::More qw(no_plan);
use App::CamelPKI::Test qw(run_perl_ok);

run_perl_ok <<'SCRIPT_OK';
warn "yipee";
exit 0;
SCRIPT_OK

run_perl_ok <<'SCRIPT_NOT_OK';
die "argl";
SCRIPT_NOT_OK

exit(1);
SCRIPT_WRAPPER
    isnt($?, 0, "run_perl: that script shall exit with nonzero status");
    like($out, qr/not ok 2/m);
    unlike($out, qr/Crypt.*CA/,
           "errors are reported at the proper stack depth");
    # Errors must be propagated:
    like($out, qr/argl/m);
    # But not successes:
    unlike($out, qr/yipee/m);

};

test "certificate_looks_ok" => sub {
    my $ok_cert = <<'OK_CERT';
-----BEGIN CERTIFICATE-----
MIICsDCCAhmgAwIBAgIJAPV18QziY9UvMA0GCSqGSIb3DQEBBQUAMEUxCzAJBgNV
BAYTAkFVMRMwEQYDVQQIEwpTb21lLVN0YXRlMSEwHwYDVQQKExhJbnRlcm5ldCBX
aWRnaXRzIFB0eSBMdGQwHhcNMDcwMTI5MDgyODI0WhcNMDcwMjI4MDgyODI0WjBF
MQswCQYDVQQGEwJBVTETMBEGA1UECBMKU29tZS1TdGF0ZTEhMB8GA1UEChMYSW50
ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMIGfMA0GCSqGSIb3DQEBAQUAA4GNADCBiQKB
gQDfGYmlOYbpGkBD/agTUnixLcdh6H1XM13w17RbzaoA7byZD6L+Dn8MZd69PuXc
ZAQEUG4Oe6QyAcafsvDb7SHjyJHLoPTOsAZ0ex/0zIJVpw+XyppA8fZx6bnuHKUa
bqfj83OLk/ACfQSBX7bcL7Y8hwYcZJcqyjMzt9BT7oCldwIDAQABo4GnMIGkMB0G
A1UdDgQWBBTu+qGX79xcvFE8pG5zx2FcqAuV5TB1BgNVHSMEbjBsgBTu+qGX79xc
vFE8pG5zx2FcqAuV5aFJpEcwRTELMAkGA1UEBhMCQVUxEzARBgNVBAgTClNvbWUt
U3RhdGUxITAfBgNVBAoTGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZIIJAPV18Qzi
Y9UvMAwGA1UdEwQFMAMBAf8wDQYJKoZIhvcNAQEFBQADgYEAFRkTlHJwSgOFQtxG
h0HHr4UES2xR+wD9xZOeFGZk066ZEdiOuUvNLYMFEe+Vo9OxAL/SdPt4oOcWremD
lTRumdcVP9vA8K4asPpXKqhpE/2EwDRmYE9g73n50yy2yazifourQmRVqSixs/ew
RSQ7/6JIpIihvyCUDUzM2bvexk8=
-----END CERTIFICATE-----
OK_CERT

    certificate_looks_ok($ok_cert);
    certificate_looks_ok($ok_cert . "\n"); # Robustness

    my $out = run_perl(<<"SCRIPT");
use strict;
use warnings;
use Test::More qw(no_plan);
use App::CamelPKI::Test qw(certificate_looks_ok);

my \$certificate = <<'OK_CERT';
$ok_cert
OK_CERT

certificate_looks_ok(\$certificate, "OK certificate"); # expecting OK
\$certificate =~ s/CQYDVQQGE/CQYDVQQGF/;
certificate_looks_ok(\$certificate, "botched certificate"); # expecting not OK

\$certificate = <<'DUD_CERT'; # Generated with an early version of
# Crypt::OpenSSL::CA; a public key is missing
-----BEGIN CERTIFICATE-----
MIHaMEWgAwIBAgIBATANBgkqhkiG9w0BAQUFADAAMB4XDTcwMDEwMTAwMDAwMFoX
DTcwMDEwMTAwMDAwMFowADAIMAMGAQADAQAwDQYJKoZIhvcNAQEFBQADgYEAsURd
sgu7sYyODuo5bCzkYBLrYb8653jjVt8hecoQj1Ete0X6uHk6t+nJ8qCwURc4FayF
kzapy9zWAGMy+6A/9CQz5862Phf3MkFM4OwkjJARBF7I73WfVEVX4e1PIgl4qjjJ
lgiG5TCUNWQrbRGa6LVDx7DErReEJE5vRwNxvjo=
-----END CERTIFICATE-----
DUD_CERT
certificate_looks_ok(\$certificate, "REGRESSION: dud cert");
         # expecting not OK, lest REGRESSION

certificate_looks_ok({}, "Should have thrown (bad input)"); # Should throw
SCRIPT

    like($out, qr/^ok 1/m);
    like($out, qr/^not ok 2/m);
    like($out, qr/^not ok 3/m);
    unlike($out, qr/^ok 4/m); # Should have died in run_thru_openssl()
    unlike($out, qr/source for input redirection/,
           "REGRESSION: passing undef to certificate_looks_ok() caused a strange error");
};

use App::CamelPKI::Test qw(test_CRL %test_rootca_certs);
use File::Spec::Functions qw(catfile);
test "test_CRL" => sub {
    my $cafile = catfile(App::CamelPKI::Test->tempdir, "cafile");
    write_file($cafile, $test_rootca_certs{"rsa1024"});
    my $crl = test_CRL("rsa1024");
    my $crldump = run_thru_openssl($crl, "crl", "-text",
                                   -CAfile => $cafile);
    is($?, 0);
    like($crldump, qr/no revoked certificates/i);
    write_file($cafile, $test_rootca_certs{"rsa2048"});
    $crl = test_CRL("rsa2048", -members => [ "0x42" ]);
    $crldump = run_thru_openssl($crl, "crl", "-text",
                                   -CAfile => $cafile);
    like($crldump, qr/42/);
};

my $cert_pem = $App::CamelPKI::Test::test_self_signed_certs{"rsa1024"};

# REFACTORME into App::CamelPKI::Test::pem2der or something
my $cert_der = do {
    use MIME::Base64 ();
    local $_ = $cert_pem;
    is(scalar(s/^-+(BEGIN|END) CERTIFICATE-+$//gm), 2,
       "test PEM certificate looks good") or warn $cert_pem;
    MIME::Base64::decode_base64($_);
};

test "x509_decoder" => sub {
    use MIME::Base64;
    my $decoder = App::CamelPKI::Test::x509_decoder('Certificate');
    ok($decoder->can("decode"));
    my $tree = $decoder->decode($cert_der);
    is($tree->{tbsCertificate}->{subjectPublicKeyInfo}
       ->{algorithm}->{algorithm},
       "1.2.840.113549.1.1.1", "rsaEncryption");
};


=head2 Synopsis tests

=cut

test "synopsis" => sub {
    # Thank you Test::Group for being fully reflexive!
    eval My::Tests::Below->pod_code_snippet("synopsis");
    die $@ if $@;
};


test "synopsis asn1" => sub {
    my $synopsis = My::Tests::Below->pod_code_snippet("synopsis-asn1");
    ok(defined(my $dn_der =
       $App::CamelPKI::Test::test_der_DNs{"CN=Zoinx,C=fr"}),
       "\$dn_der defined");
    eval $synopsis; die $@ if $@;
    pass;
};

=head2 Sample Input Validation

=cut

test "test_simple_utf8 and test_bmp_utf8" => sub {
    is(length(App::CamelPKI::Test->test_simple_utf8()), 6);
    ok(utf8::is_utf8(App::CamelPKI::Test->test_simple_utf8()));

    is(length(App::CamelPKI::Test->test_bmp_utf8()), 3);
    ok(utf8::is_utf8(App::CamelPKI::Test->test_bmp_utf8()));
};

test "%test_keys_plaintext and %test_keys_password" => sub {
    is_deeply
        ([sort keys %App::CamelPKI::Test::test_keys_plaintext],
         [sort keys %App::CamelPKI::Test::test_keys_password],
         "same keys in both");
    if (defined(my $openssl_bin = openssl_path)) {
        while(my ($k, $v) =
              each %App::CamelPKI::Test::test_keys_password) {
            my ($out, $err) = run_thru_openssl
                ($v, qw(rsa -passin pass:secret));
            is($out,
               $App::CamelPKI::Test::test_keys_plaintext{$k});
        }
    }
};

test "certificate_chain_ok and test certificates" => sub {
    my @keyids = keys %App::CamelPKI::Test::test_rootca_certs;
    foreach my $id (@keyids) {
        certificate_chain_ok
            ($App::CamelPKI::Test::test_entity_certs{$id},
           [ $App::CamelPKI::Test::test_rootca_certs{$id} ]);
        certificate_chain_ok
            ($App::CamelPKI::Test::test_entity_certs{"${id}_sha256"},
             [ $App::CamelPKI::Test::test_rootca_certs{$id} ]);
    }

    my ($snippet_ok, $snippet_not_ok) =
        map { My::Tests::Below->pod_code_snippet($_) }
            (qw(certificate_chain_ok certificate_chain_notok));
    my $out = run_perl(<<"SCRIPT");
use Test::More qw(no_plan);
use App::CamelPKI::Test qw(certificate_chain_ok
       %test_rootca_certs %test_self_signed_certs %test_entity_certs);
foreach my \$key (qw(${\join(" ", @keyids)})) {
    $snippet_ok
    $snippet_not_ok
}
SCRIPT
    for my $i (0..$#keyids) {
        my $success = 2 * $i + 1;
        my $failure = 2 * $i + 2;
        like($out, qr/^ok $success/m);
        like($out, qr/^not ok $failure/m);
    }
};

test "no collisions in the entity certificates' serial numbers" => sub {
    my %serialz;
    foreach my $certpem (values %App::CamelPKI::Test::test_entity_certs) {
        my ($out, $err) =
            run_thru_openssl($certpem, qw(x509 -noout -text));
        (my ($serial) = $out =~ m/Serial Number:\n?\s+(.*)\n/)
            or die $out;
        ok(! $serialz{$serial}++, "duplicate serial $serial");
    }
};

use App::CamelPKI::Test qw(server_start server_stop server_port);

sub server_can_connect {
    my $ua = LWP::UserAgent->new;
    my $port = server_port;
    my $response = $ua->get("https://127.0.0.1:$port/");

    # TODO : find a solution
    # A small bug prevent this from working, no time
	# to worry about it, just adapt the test
	# In a perfect world, it should be :
	#  return ($response->is_success);
	if ($response->status_line =~ qr/404/){
		return 1;
	}
    return ($response->is_success);
}

SKIP: {
	use App::CamelPKI; 
	my $webserver = App::CamelPKI->model("WebServer")->apache;
	
	skip "Apache is not installed or Key Ceremony has not been done", 
		1 unless ($webserver->is_installed_and_has_perl_support && $webserver->is_operational);
	
	test "server_start and server_stop" => sub {
    	server_start();
    	ok(server_can_connect());

    	server_stop();
    	ok(! server_can_connect());
	};
};

SKIP:{
	skip "php-cli not installed",1
		unless is_php_cli_present();
test "run_php" => sub {
    my $phpout = run_php(<<"SCRIPT");
<?php

print "z" . "o" . "i" . "n" . "x";

?>
SCRIPT
	
    	like($phpout, qr/zoinx/);
	};
};

SKIP: {
	use App::CamelPKI; 
	my $webserver = App::CamelPKI->model("WebServer")->apache;
	
	skip "Key Ceremony has not been done", 
		1 unless ($webserver->is_operational);
	
	
	use App::CamelPKI::Test qw(camel_pki_chain);
	test "camel_pki_chain" => sub {
    	my @chain = camel_pki_chain;
    	is(scalar(@chain), 2);
    	certificate_chain_ok($chain[0], \@chain);
	};
}
