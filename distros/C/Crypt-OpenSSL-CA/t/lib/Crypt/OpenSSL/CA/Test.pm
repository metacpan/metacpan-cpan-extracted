#!perl -w

package Crypt::OpenSSL::CA::Test;

use warnings;
use strict;

=head1 NAME

B<Crypt::OpenSSL::CA::Test> - Testing L<Crypt::OpenSSL::CA>

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

  use Crypt::OpenSSL::CA::Test qw(:default %test_der_DNs);
  use Test::Group;

  my $utf8 = Crypt::OpenSSL::CA::Test->test_simple_utf8();

  run_perl_ok(<<"SCRIPT");
  use Crypt::OpenSSL::CA::Test;
  warn "Hello world";
  SCRIPT

  skip_next_test "Devel::Leak needed" if cannot_check_SV_leaks;
  test "leaky code" => sub {
     leaks_SVs_ok {
        # Do stuff
     }, -max => 6;
  };

  skip_next_test "Devel::Mallinfo needed" if cannot_check_bytes_leaks;
  test "even leakier code" => sub {
     leaks_bytes_ok {
       # Do stuff
     }, -max => 51200;
  };

=for My::Tests::Below "synopsis" end

=for My::Tests::Below "synopsis-asn1" begin

 use Crypt::OpenSSL::CA::Test qw(x509_decoder);

 my $dn_as_tree = x509_decoder('Name')->decode($dn_der);

=for My::Tests::Below "synopsis-asn1" end

=head1 DESCRIPTION

This module provides some handy utility functions for testing
L<Crypt::OpenSSL::CA>.  L</leaks_bytes_ok> and L</leaks_SVs_ok> are
especially handy for testing XS or Inline::C stuff.

=head1 EXPORTED FUNCTIONS

All functions described in this section factor some useful test
tactics and are exported by default.  The L</SAMPLE INPUTS> may also
be exported upon request.

=cut

use Test::Builder;
use Test::More;
use Test::Group;
use File::Path ();
use File::Spec ();
use File::Slurp ();
use File::Temp ();

use base 'Exporter';
BEGIN {
    our @EXPORT =
        qw(openssl_path run_thru_openssl
           dumpasn1_available run_dumpasn1
           run_perl run_perl_ok run_perl_script run_perl_script_ok
           errstack_empty_ok
           certificate_looks_ok
           certificate_chain_ok certificate_chain_invalid_ok
           cannot_check_SV_leaks leaks_SVs_ok
           cannot_check_bytes_leaks leaks_bytes_ok
           x509_schema x509_decoder);
    our @EXPORT_OK = (@EXPORT,
                      qw(test_simple_utf8 test_bmp_utf8
                         @test_DN_CAs
                         %test_der_DNs
                         %test_public_keys
                         %test_reqs_SPKAC %test_reqs_PKCS10
                         %test_keys_plaintext %test_keys_password
                         %test_self_signed_certs %test_rootca_certs
                         %test_entity_certs
                         ));
    our %EXPORT_TAGS = ("default" => \@EXPORT);
}

=head2 openssl_path

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

=head2 run_thru_openssl ($stdin_text, $arg1, $arg2, ...)

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

    my ($out, $err);
    IPC::Run::run(\@cmdline, \$data, \$out, wantarray ? \$err : \$out);

    # Under FreeBSD-amd64 6.2's OpenSSL 0.9.7e-p1 25 Oct 2004, the
    # return code of "openssl crl" is unreliable (see eg
    # http://www.nntp.perl.org/group/perl.cpan.testers/1042233):
    if ($cmdline[1] eq "crl") {
        $? = 0 if $? == 1 << 8;
    }
    return wantarray ? ($out, $err) : $out;
}

=head2 dumpasn1_available ()>

Returns true iff the I<dumpasn1> command can be found in $ENV{PATH}.

=cut

use File::Which ();
sub dumpasn1_available { not(not File::Which::which("dumpasn1")) }

=head2 run_dumpasn1 ($der)

Runs the I<dumpasn1> command (found in $ENV{PATH}) on $der and returns
its output.  Throws an exception if dumpasn1 fails for some reason.
See also L</dumpasn1_available>.

=cut

sub run_dumpasn1 {
    my ($der) = @_;
    my $out;
    IPC::Run::run(["dumpasn1", "-"], \$der, \$out, \$out);
    die "dumpasn1 failed with code $?" if $?;
    return $out;
 }


=head2 run_perl ($scripttext)

Runs $scripttext in a sub-Perl interpreter, returning the text of its
combined stdout and stderr as a single string.  $? is set to the exit
value of same.

=head2 run_perl_ok ($scripttext)

=head2 run_perl_ok ($scripttext, \$stdout)

=head2 run_perl_ok ($scripttext, \$stdout, $testname)

Like L</run_perl> but simultaneously asserts (using L<Test::More>)
that the exit value is successful.  The return value of the sub is the
status of the assertion; the output of $scripttext (that is, the
return value of the underlying call to I<run_perl>) is transmitted to
the caller by modifying in-place the scalar reference passed as the
second argument, if any.  Additionally the aforementioned output is
passed to L<Test::More/diag> if the script does exit with nonzero
status.

=head2 run_perl_script ($scriptname)

=head2 run_perl_script_ok ($scriptname, \$stdout, $testname)

Like L</run_perl> resp L</run_perl_ok> except that the script is
specified as a file name instead of Perl text.

=cut

sub run_perl {
    my ($scripttext) = @_;

    Carp::croak "Bizarre first argument passed to run_perl()"
        if (! defined($scripttext) || ref($scripttext));

    if ($ENV{DEBUG}) {
        my $scriptdir = File::Spec->catdir(_tempdir(), "run_perl_ok");
        File::Path::mkpath($scriptdir);
        my $scriptfile = File::Spec->catfile
            ($scriptdir, sprintf("run_perl_ok_%d_%d", $$,
                                 _unique_number()));
        File::Slurp::write_file($scriptfile, $scripttext);
        diag(<<"FOR_CONVENIENCE");
run_perl: a copy of the script to run was saved in $scriptfile
to ease debugging.
FOR_CONVENIENCE
    }

    my ($stdout, $stderr);
    IPC::Run::run([_perl_cmdline()], \$scripttext, \$stdout, \$stderr);
    return $stdout . $stderr;
}

sub run_perl_script {
  my ($scriptfile) = @_;

  my ($stdout, $stderr);
  IPC::Run::run([_perl_cmdline(), $scriptfile], \"", \$stdout, \$stderr);
  return $stdout . $stderr;
}

BEGIN { foreach my $functionname (qw(run_perl run_perl_script)) {
  my $ok_wrapper = sub {
    my ($code, $outref, $testname) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    $testname ||= $functionname;
    my $out = __PACKAGE__->can($functionname)->($code);
    $$outref = $out if ref($outref) eq "SCALAR";
    my $retval = is($?, 0, $testname);
    diag($out) if ! $retval;
    return $retval;
  };
  no strict "refs";
  *{"${functionname}_ok"} = $ok_wrapper;
}}

=head2 _perl_cmdline ()

Computes (with cache) and returns the command line to invoke sub-Perls
as on behalf of L</run_perl> and L</run_perl_script> while (more or
less) preserving @INC.

Returns the name of the Perl binary and a list of C<-I> command line
switches that should be passed as part of an invocation of
<perlfunc/system> or similar.  The C<-I> paths returned are exactly
the elements in the current @INC that are B<not> part of the Perl
interpreter's compiled-in @INC.

=cut

{
    my @perlcmdline;
    sub _perl_cmdline {
        return @perlcmdline if @perlcmdline;
        my ($perl) = ($^X =~ m/^(.*)$/); # Untainted

        # There might be a more elegant way of fetching the pristine
        # @INC set...
        my ($indent, $orig_inc);
        {
            local $ENV{PERL5LIB};
            ( ($indent, $orig_inc) = `$perl -V` =~ m/^( *)\@INC:\n(.*)\Z/sm )
              or die <<"FAIL";
Couldn't find original \@INC in the output of $perl -V.
FAIL
        }
        my %orig_inc_set;
        foreach (split m{$/}, $orig_inc) {
            last unless m/^$indent +(.*?)$/;
            $orig_inc_set{$1}++;
        }

        @perlcmdline = ($perl, (map { -I => $_ } (grep {! $orig_inc_set{$_} } @INC)));
        diag(join(" ", @perlcmdline)) if $ENV{DEBUG};
        return @perlcmdline;
    }
}

=head2 errstack_empty_ok ()

Asserts that OpenSSL's error stack is empty, and clears it if not.  To
be run at the end of every test.

=cut

sub errstack_empty_ok {
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    # Net::SSLeay provides an undocumented access to OpenSSL's ERR_
    # API.  Fortunately, thanks to my newly acquired XS-Fu, reading
    # the source was a piece of cake!
    require Net::SSLeay;
    my $errcount = 0;
    while(my $error = Net::SSLeay::ERR_get_error()) {
        diag(Net::SSLeay::ERR_error_string($error));
        $errcount++;
    }
    return is($errcount, 0, "number of errors found on OpenSSL's stack");
}

=head2 cannot_check_SV_leaks ()

Returns true iff L<Devel::Leak> is unavailable.

=cut

sub cannot_check_SV_leaks { ! eval { require Devel::Leak } }

=head2 cannot_check_bytes_leaks ()

Returns true iff L<Devel::Mallinfo> is unavailable or does nothing on
this platform (eg MacOS).

=cut

sub cannot_check_bytes_leaks {
    return 1 if ! eval { require Devel::Mallinfo };
    return (! exists Devel::Mallinfo::mallinfo()->{uordblks});
}

=head2 leaks_SVs_ok ($coderef, %named_arguments)

Executes $coderef and asserts (with L<Test::More>) that it doesn't
leak Perl SVs (checked using L<Devel::Leak>).  As a tester, you should
arrange for $coderef to manipulate about 10 SVs; smaller leaks will
not be detected (see I<-max> below).

Available named arguments are:

=over

=item I<< -name => $testname >>

The name of the test, as in the second argument to L<Test::Builder/ok>.

=item I<< -max => $threshold >>

The minimum number of leaked SVs to look for.  The default is 6.
Setting this too low will trigger false positives, as L<Devel::Leak>
needs a couple of SVs of its own.

=back

=cut

sub leaks_SVs_ok (&@) {
    my ($coderef, %args) = @_;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    require Devel::Leak;
    my $handle; my $count = Devel::Leak::NoteSV($handle);
    $coderef->();
    my $consumed_SVs = Devel::Leak::CheckSV($handle) - $count;
    cmp_ok($consumed_SVs, "<=", ($args{-max} || 6), ($args{-name} || "leaks_SVs_ok"));
}


=head2 leaks_bytes_ok ($coderef)

=head2 leaks_bytes_ok ($coderef, $testname)

Executes $coderef and asserts (with L<Test::More>) that it doesn't
leak memory (checked using L<Devel::Mallinfo>).  As a tester, you
should arrange for $coderef to manipulate about 100k of memory;
smaller leaks will not be detected (see I<-max> below).

Available named arguments are:

=over

=item I<< -name => $testname >>

The name of the test, as in the second argument to L<Test::Builder/ok>.

=item I<< -max => $threshold >>

The minimum number of leaked bytes to look for.  The default is 51200.
Setting this too low will trigger false positives, as Perl does some
funky memory management eg in hash tables and that may cause jitter in
the memory consumption as measured from malloc's point of view.

=back

=cut

sub leaks_bytes_ok (&@) {
    my ($coderef, %args) = @_;
    require Devel::Mallinfo;

    my $size_before = Devel::Mallinfo::mallinfo()->{uordblks} || 0;

    $coderef->();

    my $size_after = Devel::Mallinfo::mallinfo()->{uordblks} || 0;

    my $consumption = $size_after - $size_before;
    local $Test::Builder::Level = $Test::Builder::Level + 1;
    cmp_ok($consumption, "<", ($args{-max} || 51200),
          $args{-name} || "leaks_bytes_ok");
}

=head2 certificate_looks_ok ($pem_certificate)

=head2 certificate_looks_ok ($pem_certificate, $test_name)

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

=head2 certificate_chain_ok ($pem_certificate, \@certchain )

=head2 certificate_chain_ok ($pem_certificate, \@certchain , $test_name)

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
${$testname ? \"$testname: " : \""}Ignoring a non-CA certificate that was
passed as part of the chain.
WARNING
    } @$certchain;
    fail("no remaining certificates in chain"), return undef
        if ! @certchain;

    my $bundlefile = File::Spec->catfile
        (_tempdir(), sprintf("ca-bundle-%d-%d.crt", $$,
                             _unique_number()));
    File::Slurp::write_file($bundlefile,
                            join("\n", @certchain));
    return scalar run_thru_openssl($cert, qw(verify),
                                   -CAfile => $bundlefile);
}

=head2 certificate_chain_invalid_ok ($pem_certificate, \@certchain )

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

=head2 x509_schema ()

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

=head2 x509_decoder ($name)

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

=head1 SAMPLE INPUTS

I<Crypt::OpenSSL::CA::Test> also provides a couple of constants and
class methods to serve as inputs for tests.  All such symbols are
exportable, but not exported by default (see L</SYNOPSIS>) and they
start with I<test_>, so as to be clearly identified as sample data in
the test code.

=head2 test_simple_utf8 ()

=head2 test_bmp_utf8 ()

Two constant functions that return test strings for testing the UTF-8
capabilities of I<Crypt::OpenSSL::CA>.  Both strings are encoded
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

=head2 %test_der_DNs

Contains a set of DER-encoded DNs. The keys are the DNs in
L<Crypt::OpenSSL::CA::Resources/RFC4514> notation, and the values are
strings of bytes.  Available DN keys for now are C<CN=Zoinx,C=fr>.

=cut

## You can generate more using Crypt::OpenSSL::CA itself using a
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

=head2 @test_DN_CAs

The DN used in all CA and self-signed certificates, namely
L</%test_self_signed_certs>, L</%test_rootca_certs> and friends. Set
in the same order as the parameters to the I<new> function in
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::X509_NAME>.

=cut

our @test_DN_CAs = (C => "AU", ST => "Some-State",
                    O => "Internet Widgits Pty Ltd");

=head2 %test_reqs_SPKAC

Certificate signing requests (CSRs) in Netscape
L<Crypt::OpenSSL::CA::AlphabetSoup/SPKAC> format, as if generated by

  openssl spkac -key test.key -challenge secret

but without the trailing newline, and with the leading C<SPKAC=> removed.

=cut

our %test_reqs_SPKAC =
    (rsa1024 => "MIIBQDCBqjCBnzANBgkqhkiG9w0BAQEFAAOBjQAwgYkCgYEA3xmJpTmG6RpAQ/2oE1J4sS3HYeh9VzNd8Ne0W82qAO28mQ+i/g5/DGXevT7l3GQEBFBuDnukMgHGn7Lw2+0h48iRy6D0zrAGdHsf9MyCVacPl8qaQPH2cem57hylGm6n4/Nzi5PwAn0EgV+23C+2PIcGHGSXKsozM7fQU+6ApXcCAwEAARYGc2VjcmV0MA0GCSqGSIb3DQEBBAUAA4GBAMpl9v+6SSQt0yGlmg20bZEz9jiTzbD3UX6vdCdIdYuksTnVrTarVTi6zMSAK/me+fo+54LbZxqxFVjrnz1eg7yUQkvjfrs/HGDpdBoWHvw3+iePK8DHlaipolACNF+OyoMryl5gqRPhV6FosHiiD9QQ4IY7GSMKMr5iQ/pwlAGx",
     rsa2048 => "MIICRjCCAS4wggEiMA0GCSqGSIb3DQEBAQUAA4IBDwAwggEKAoIBAQCxupRLykaWvgQP2aZmcEGq9/3OXtnQ1H0tnNfbJexzYYyCOiU1CP8KsMoeNMvdUun4FwGKeckjGF1eDuOgbGh0naG4+M4/5PTCbOaF2otb8zPc+oUGh3tmgiLhLnlV4zQbeTBRD6/giHnFgUWC+Ec/PjEnmDu917430GI2nnD66/OZr9NnyxFYMhSlufwWRGCtR6LLa9QqDAl+DvbSmvHGL9G7VFBGcFwLbaTYUWmkvQwEhq01yZ/bp+yAIJpygsnWMg6kJahkBI5hNFK1KWbLYyF9IDJb6TsL9mRiW8+0BAkZosD5jdm4Ra7SMtiTjzY+FyNp2IRwZ32N70iNGGPZAgMBAAEWBnNlY3JldDANBgkqhkiG9w0BAQQFAAOCAQEAd3JfT2QEo8pBHhQFlh9PDfc3OhL7z0IcebcDL7kslxB5JViuzKMce/+68RoQ9eaepmVunXxVIJEauNp5LrZatxODp8kOsJI86HD1ChMVqrr6DZi6ulBEXst2kvzkEwVN24Hm5t80hGK8jnZtN86iIXk4iA7iEiniTO7qVhq3kEIouV6fprOk2P8bZ24OlVQ0+1Lp4h5EKajRQZoacnK4IGUTNXEGdAI17ID/qf8sqKZQtiqrRXGAQqbx3bxk8aLUm8OhmyeGett75H0n956MNPJiwDy9ftcUnyiuHHYGKq6SZNNs4mKOjnSnz3D9DhUCbJkfG2FbCkRsMl8SHARoyA==",
    );

=head2 %test_reqs_PKCS10

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

=head2 %test_keys_plaintext

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

=head2 %test_keys_password

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

=head2 %test_public_keys

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


=head2 %test_self_signed_certs

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

=head2 %test_rootca_certs

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

=head2 %test_entity_certs

Certificates generated using C<openssl ca> from
L</%test_rootca_certs>, L</%test_keys_plaintext> and the default
OpenSSL configuration using the procedure described in
L<Crypt::OpenSSL::CA::Resources/Building a toy CA:> where the
precise C<openssl> commands used are

  openssl req -new -batch -subj "/C=fr/O=Yoyodyne/CN=John Doe" \
    -key test.key | \
  openssl ca -batch -days 10958 -in /dev/stdin

In particular this means that entries keyed off the same identifier in
%test_entity_certs and %test_rootca_certs form a valid RFC3280
certification path: that is,

=for My::Tests::Below "certificate_chain_ok" begin

  certificate_chain_ok($test_entity_certs{$id},
                       [ $test_rootca_certs{$id} ]);     # Works

=for My::Tests::Below "certificate_chain_ok" end

holds for every valid $id.  But conversely,

=for My::Tests::Below "certificate_chain_notok" begin

  certificate_chain_ok($test_entity_certs{$id},
                       [ $test_self_signed_certs{$id} ]);     # NOT OK!

=for My::Tests::Below "certificate_chain_notok" end

fails, due to the lack of a C<CA:TRUE> BasicConstraint extension in
%test_self_signed_certs.

Notice that in the sample inputs, CAs and end entities share the same
set of private RSA keys L</%test_keys_plaintext> which would not be
the case in a real PKI deployment.  However this is of little impact,
if any, on the test coverage of I<Crypt::OpenSSL::CA> as we never make
use of the fact that all certificates for a given key length actually
have the same private key.

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
     );

=head1 INTERNAL METHODS

=head2 _tempdir

Returns a temporary directory e.g. for storing the C<ca-bundle.crt>
for L</certificate_chain_ok>.

=cut

{
    my $cached;
    sub _tempdir {
        return My::Tests::Below->tempdir if
            (My::Tests::Below->can("tempdir"));
        return $cached if defined $cached;
        return ($cached = File::Temp::tempdir
                ("perl-Crypt-OpenSSL-CA-Test-XXXXXX",
                 TMPDIR => 1, ($ENV{DEBUG} ? () : (CLEANUP => 1))));
    }
}

=head2 _unique_number

As the name implies.  Typically used to create unique filenames in
L</_tempdir>.

=cut

{ my $unique = 0; sub _unique_number { $unique++ } }


=head1 TODO

Maybe L</leaks_bytes_ok> and L</leaks_SVs_ok> deserve a CPAN module of
their own?

=cut

require My::Tests::Below unless caller;
1;

__END__

=head1 TEST SUITE

=cut

use Test::More "no_plan";
use Test::Group;
use Crypt::OpenSSL::CA::Test;

=head2 Fixture Tests

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
            ($Crypt::OpenSSL::CA::Test::test_keys_plaintext{rsa1024},
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
use Test::More no_plan => 1;
use Crypt::OpenSSL::CA::Test qw(run_perl_ok);

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

test "errstack_empty_ok" => sub {
    errstack_empty_ok();
    my $out = run_perl(<<"SCRIPT_NOT_OK");
use Test::More no_plan => 1;
use Crypt::OpenSSL::CA::Test qw(errstack_empty_ok);
use Net::SSLeay;

is(Net::SSLeay::BIO_new_file("/no/such/file_", "r"), 0); # OK
errstack_empty_ok(); # not OK

SCRIPT_NOT_OK

    like($out, qr/^ok 1/m);
    like($out, qr/^not ok 2/m);
    like($out, qr/at.* line/, "errors are reported");
    # Grr, "like" won't let $1 through:
    my ($filename) = $out =~ m/(.*) line/;
    unlike($filename, qr/Crypt.*CA/,
           "errors are reported at the proper stack depth");
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
use Test::More no_plan => 1;
use Crypt::OpenSSL::CA::Test qw(certificate_looks_ok);

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

=head2 Leak tests

=cut

begin_skipping_tests unless
    eval { require Devel::Leak; require Devel::Mallinfo; };
test "no leak" => sub {
    leaks_SVs_ok { };
    leaks_bytes_ok { };
};

test "leaking scalars" => sub {
    my $leakyscript = <<'LEAKYSCRIPT';
use Test::More no_plan => 1;
use Crypt::OpenSSL::CA::Test;
sub leak {
   for (1..20) {
     my $yin = {};
     my $yang = { yin => $yin };
     $yin->{yang} = $yang;
   }
}

leaks_bytes_ok { leak };
leaks_SVs_ok { leak };
LEAKYSCRIPT

    my $out = run_perl($leakyscript);
    is($? & 255, 0, "we don't get signal");

    like($out, qr/^ok 1/m);
    like($out, qr/^not ok 2/m);
    unlike($out, qr/Crypt.*CA/,
           "errors are reported at the proper stack depth");
};

skip_next_test if cannot_check_bytes_leaks; # Eg MacOS
test "leaking bytes" => sub {
    my $leakyscript = <<'LEAKYSCRIPT';
use Test::More no_plan => 1;
use Crypt::OpenSSL::CA::Test;
sub leak {
    # Perl is getting smarter and smarter in memory mgmt, and we need
    # to ward off constant folding for that test to fail as expected:
    push(our @a, "abcde" x (10000 + scalar @a));
}

leaks_bytes_ok { leak() };
leaks_SVs_ok { leak() };
LEAKYSCRIPT

    my $out = run_perl($leakyscript);
    is($? & 255, 0, "we don't get signal");
    like($out, qr/^not ok 1/m);
    like($out, qr/^ok 2/m);
    unlike($out, qr/Crypt.*CA/,
           "errors are reported at the proper stack depth");
};

my $cert_pem = $Crypt::OpenSSL::CA::Test::test_self_signed_certs{"rsa1024"};

# REFACTORME into Crypt::OpenSSL::CA::Test::pem2der or something
my $cert_der = do {
    use MIME::Base64 ();
    local $_ = $cert_pem;
    is(scalar(s/^-+(BEGIN|END) CERTIFICATE-+$//gm), 2,
       "test PEM certificate looks good") or warn $cert_pem;
    MIME::Base64::decode_base64($_);
};

test "x509_decoder" => sub {
    use MIME::Base64;
    my $decoder = Crypt::OpenSSL::CA::Test::x509_decoder('Certificate');
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
       $Crypt::OpenSSL::CA::Test::test_der_DNs{"CN=Zoinx,C=fr"}),
       "\$dn_der defined");
    eval $synopsis; die $@ if $@;
    pass;
};

=head2 Sample Input Validation

=cut

test "test_simple_utf8 and test_bmp_utf8" => sub {
    is(length(Crypt::OpenSSL::CA::Test->test_simple_utf8()), 6);
    ok(utf8::is_utf8(Crypt::OpenSSL::CA::Test->test_simple_utf8()));

    is(length(Crypt::OpenSSL::CA::Test->test_bmp_utf8()), 3);
    ok(utf8::is_utf8(Crypt::OpenSSL::CA::Test->test_bmp_utf8()));
};

test "%test_keys_plaintext and %test_keys_password" => sub {
    is_deeply
        ([sort keys %Crypt::OpenSSL::CA::Test::test_keys_plaintext],
         [sort keys %Crypt::OpenSSL::CA::Test::test_keys_password],
         "same keys in both");
    if (defined(my $openssl_bin = openssl_path)) {
        while(my ($k, $v) =
              each %Crypt::OpenSSL::CA::Test::test_keys_password) {
            my ($out, $err) = run_thru_openssl
                ($v, qw(rsa -passin pass:secret));
            is($out,
               $Crypt::OpenSSL::CA::Test::test_keys_plaintext{$k});
        }
    }
};

test "certificate_chain_ok and test certificates" => sub {
    my @keyids = keys %Crypt::OpenSSL::CA::Test::test_rootca_certs;
    foreach my $id (@keyids) {
        certificate_chain_ok
            ($Crypt::OpenSSL::CA::Test::test_entity_certs{$id},
           [ $Crypt::OpenSSL::CA::Test::test_rootca_certs{$id} ]);
    }

    my ($snippet_ok, $snippet_not_ok) =
        map { My::Tests::Below->pod_code_snippet($_) }
            (qw(certificate_chain_ok certificate_chain_notok));
    my $out = run_perl(<<"SCRIPT");
use Test::More no_plan => 1;
use Crypt::OpenSSL::CA::Test qw(certificate_chain_ok
       %test_rootca_certs %test_self_signed_certs %test_entity_certs);
foreach my \$id (qw(${\join(" ", @keyids)})) {
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
