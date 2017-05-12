#!perl -w

package App::CamelPKI::CA;
use strict;
use warnings;

=head1 NAME

App::CamelPKI::CA - Model of a Certificate Authority in Camel-PKI.

=head1 SYNOPSIS

Supposing C<App::CamelPKI::CertTemplate::Foo> is as described in
L<App::CamelPKI::CertTemplate/SYNOPSIS>:

=for My::Tests::Below "synopsis" begin

  my $ca = App::CamelPKI::CA->load($directory, $cadb)->facet_operational;
  $ca->issue("App::CamelPKI::CertTemplate::Foo", $pubkey,
             name => "Joe", uid => 42);
  $ca->issue("App::CamelPKI::CertTemplate::Foo", $pubkey,
             name => "Fred", uid => 43);
  my ($joecert, $fredcert) = $ca->commit();
  $ca->revoke("App::CamelPKI::CertTemplate::Foo", $joecert);
  $ca->commit();
  my $crl = $ca->issue_crl;

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

The Certificate Authority defined in RFC3039 and following is a
software component which issue and revoke X509 certificates. It's the
master piece of any PKIX implementation. See L</REFERENCES> for more
informations.

I<App::CamelPKI::CA> use L<Crypt::OpenSSL::CA> for cyptographic operations,
and L<Catalyst::Model::DBIC> in a SQLite database for persistence.
I<App::CamelPKI::CA> is very flexible, and deleguates most of the certificate
policy choices to the <App::CamelPKI::CertTemplate> subclass which can be
freely coded.

=head2 Coherence

As any ACID database, I<App::CamelPKI::CA> impose coherence checks to
incomming transactions. Theses constraints are flexible, in the way
that a part of their implementation is deleguated to the certificate
templates; future extensions of Camel-PKI could extends this flexibility,
deleguating more responsability on the templating part.

I<App::CamelPKI::CA> impose the following coherence constraints:

=over

=item B<It's prohibited to issue a certificate without commiting the
transation>

It's a security requirement, as any issued certificate may be revoked
(which could be impossible if the database could lost its track). That's
why L</commit> and not L</issue> which returns newly build certificates.

=item B<It's prohibited to certificate and revoke the same certificate
in the same transaction>

The template has no mean - yet - to bypass this restriction, and there
is few (if no) rationale to change this behavior, as this operation
has no sens in the PKIX context.

=item B<The certificate template may revoke old certificates when the
CA creates new ones>

By the means of the
L<App::CamelPKI::CertTemplate/test_certificate_conflict> method, the certificate
template may indicate to the CA that some already issued certificates are
conflicting with some of the newly asked ones in the current transaction.
For now, the CA honors the template request revoking old certificates; Future
version of this CA will be able to cancel the transaction albeith the said
certificates are already revoked, or certify bypassing the template policy.

Note that certificates created during the I<same transaction> are not
concerned by I<test_certificate_conflict()>, and will not be visible in the
database facet used by this method. To test the internal coherence of the
transaction, I<test_issued_certs_coherent()> is used, as indicated hereafter.

=item B<the certificate template may block some certificate combinations>

Using the
L<App::CamelPKI::CertTemplate/test_issued_certs_coherent> method, the certificate
template has the right of veto to cancel the transaction if it detects than
some certificates are conflicting with some others (for example because they
contains the same nominative informations).

=back

=head1 CAPABILITY DISCIPLINE

The ownership of one instance of C<App::CamelPKI::CA> gives privilege to
modify certificate an key, read certificate (but not the key), issue
a CRL, issue and revoke certificates in any existing 
L<App::CamelPKI::CertTemplate>, and to performs maintenance operations on
the database.

The L</facet_operational>, L</facet_certtemplate> and 
L</facet_readonly> facets helps to restrict theses privileges.

=cut

use Class::Facet;
use File::Spec::Functions qw(catdir catfile);
use File::Path qw(mkpath);
use File::Slurp;
use Crypt::OpenSSL::CA;
use App::CamelPKI::Error;
use App::CamelPKI::RestrictedClassMethod ':Restricted';
use App::CamelPKI::Time;
use App::CamelPKI::CADB;
use App::CamelPKI::CertTemplate;
use App::CamelPKI::Certificate;
use App::CamelPKI::PublicKey;
use App::CamelPKI::CRL;

=head1 CLASS CONSTRUCTORS AND METHODS

=head2 load($directory, $cadb)

Restricted constructor (See L<App::CamelPKI::RestrictedClassMethod>).
Load the cryptographic material (private keys and certificates)
from $directory, creating it if needed, and use $cadb, an read-write
instance of L<App::CamelPKI::CADB>, as storage backend.

=cut

sub load : Restricted {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS") if (@_ != 3);
    my ($class, $directory, $cadb) = @_;
    if (! -d $directory) {
        mkpath($directory) or
            throw App::CamelPKI::Error::IO("cannot create directory",
                                      -IOfile => $directory);
    }
    return bless {
                  db => $cadb,
                  cryptdir => $directory,
                 }, $class;
}


=head1 METHODS

=head2 set_keys(-certificate => $cert, -key => $key)

Install the certificate and private key passed in argument in the
CA permanent storage space. The CA is unable to issue certificates
and CRLs until this step is not completed.
$cert is an L<App::CamelPKI::Certificate> object, and $key is an
L<App::CamelPKI::PrivateKey> object.

=cut

sub set_keys {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, @args) = @_;
    while(my ($k, $v) = splice(@args, 0, 2)) {
        if ($k eq "-certificate") {
            write_file($self->_certificate_path,
                       $v->serialize(-format => "PEM"));
        } elsif ($k eq "-key") {
            write_file($self->_key_path,
                       $v->serialize(-format => "PEM"));
        } else {
            throw App::CamelPKI::Error::Internal
                ("INCORRECT_ARGS",
                 -details => "Unknown cryptographic material",
                 -type => $k);
        }
    }
}

=head2 is_operational()

Returns true only if a key and a certificate has been added to this CA
using L</set_keys>.

=cut

sub is_operational {
    my ($self) = @_;
    return (-r $self->_certificate_path && -r $self->_key_path);
}

=head2 database()

Returns a B<read only> instance of L<App::CamelPKI::CADB>> which modelise
the CA database. (The read/write access is reserved to the only 
I<App::CamelPKI::CA> class.)

=cut

sub database { shift->{db}->facet_readonly }

=head2 certificate()

Returns the CA certificate, in the form of an L<App::CamelPKI::Certificate>
object.

=cut

sub certificate {
    my ($self) = @_;
    $self->{certificate} ||= App::CamelPKI::Certificate->load
        ($self->_certificate_path);
}

=head2 issue($certtemplate, $pubkey, $key1 => $val1, ...)

Issue on to many new certificates. $pubkey is a public key, in the
form of an L<App::CamelPKI::PublicKey> object. $certtemplate is the name
of a subclass of L<App::CamelPKI::CertTemplate>; $key1 => $val1, ... are
nominatives parameters to pass to $certtemplate for him to generate
associated certificates (see details in 
L<App::CamelPKI::CertTemplate/prepare_certificate> and
L<App::CamelPKI::CertTemplate/list_keys>).

Internally, I<sign> control arguments, and the calls

  $certtemplate->test_certificate_conflict($db, $key1 => $val1, ...)

to verify if the certificate to create is compliant to the existing
certificates. If it's ok, I<sign> invokes

  $certtemplate->prepare_certificate($cacert, $newcert, $key1 => $val1, ...)

At last, I<sign> fix the serial number, conforming to the current CA status,
and records the certificate in database. The certificate may then be retrieved
using L</commit>.

=cut

sub issue {
    my ($self, $template, $pubkey, @opts) = @_;

    # Note the explicit class call: so the template has no authority
    # to overload this method at will.
    my %dbopts = $template->App::CamelPKI::CertTemplate::normalize_opts(@opts);
    delete $dbopts{time}; # Sémantique réservée
    $dbopts{template} = $template;
    my %templateopts = %dbopts;
    $templateopts{time} = App::CamelPKI::Time->now->zulu;

    foreach my $conflictcert
        ($template->test_certificate_conflict
         ($self->database_facet($template), %templateopts)) {
        # FIXME: should be more flexible (refuse the operation
        # instead of revoking conflicting certificates, or give the
        # "superseded" reason in the CRL...)
        $self->revoke($template, $conflictcert) unless
            grep {$conflictcert->equals($_->{cert})} @{$self->{signed}};
    }

    my $cert = Crypt::OpenSSL::CA::X509->new
        ($pubkey->as_crypt_openssl_ca_publickey);
    $template->prepare_certificate
        ($self->certificate, $cert, %templateopts);
    $cert->set_serial(sprintf("0x%x",
                              $self->{db}->next_serial("certificate")));
    $cert = App::CamelPKI::Certificate->parse
        ($cert->sign($self->_private_key,
                     $template->signature_hash));
    push @{$self->{signed}}, { cert => $cert, opts => \%dbopts };
    return;
}

=head2 revoke($certtemplate, $certificate, %options)

Marks $certificate, an object of the L<App::CamelPKI::Certificate> class,
which has been certified via the $certtemplate template, as revoked.
It's prohibited to revoke a certificate that has just been certified
in the current transaction (see L</Coherence>); If this situation
is detected, triggers an exception. In the same way, the template
may cause additional revocations following the revocation of
 $certificate (see L<App::CamelPKI::CertTemplate/test_cascaded_revocation>).

This method is delegated to L<App::CamelPKI::CADB/revoke>, and recognized named
options are documented at this section.

=cut

sub revoke {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, $template, $cert, %options) = @_;
    throw App::CamelPKI::Error::Internal("INCORRECT_ARGS")
        if (! defined $cert);

    throw App::CamelPKI::Error::Privilege
        ("Attempt to revoke a certificate foreign to this template",
         -certificate => $cert,
         -template => $template)
            unless $self->database_facet($template)
                ->search(-certificate => $cert,
                         -revoked => undef)->count;
    $self->{db}->revoke($cert, %options);
}

=head2 commit()

Records all writes in database, and returns the certificate list issued
with L</sign> scince the creation of the object or scince the previous
call to I<commit>. Certificates are returned in the form of a list of
L<App::CamelPKI::Certificate> objects, in the same order as the corresponding
call to L</sign>.

=cut

sub commit {
    my ($self) = @_;

    my @signed = @{delete($self->{signed}) || []};

    my $checks = {};
    push @{$checks->{$_->{opts}->{template}}}, $_ foreach @signed;
    $_->test_issued_certs_coherent(@{$checks->{$_}}) foreach
        (keys %$checks);

    my @retval;
    foreach my $signed (@signed) {
        $self->{db}->add($signed->{cert}, %{$signed->{opts}});
        push(@retval, $signed->{cert});
    }
    $self->{db}->commit;

    return @retval;
}

=head2 issue_crl(-option1 => $val1, ...)

Builds a CRL taking account of previously marked as revoked certificates
in database, and returns it in the form of an L<App::CamelPKI::CRL> object.

Recognized named options are:

=over

=item I<< -validity => $days >>

Allows to specify the validity duration of the CRL. Default value is 7
days.

=item I<< -signature_hash => $hashname >>

Allows to specify the cryptographic algorithm to use for the CRL
signing, on the form of a name (for example "sha256").
The default value is "sha256", as "md5" and "sha1" are not recommanded
due to progress done in their cryptanalysis
(L<http://www.win.tue.nl/~bdeweger/CollidingCertificates/>).

=back

=cut

sub issue_crl {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, %opts) = @_;
    $opts{-validity} ||= 7;
    $opts{-signature_hash} ||= "sha256";

    my $crl = new Crypt::OpenSSL::CA::X509_CRL;
    $crl->set_issuer_DN($self->certificate->as_crypt_openssl_ca_x509
                        ->get_subject_DN);
    my $now = App::CamelPKI::Time->now;
    $crl->set_lastUpdate($now);
    $crl->set_nextUpdate($now->advance_days($opts{-validity}));
    $crl->set_extension
        ("crlNumber", sprintf("0x%x", $self->{db}->next_serial("crl")),
         -critical => 1);
    $crl->set_extension("authorityKeyIdentifier",
                        { keyid => $self->certificate->
                          as_crypt_openssl_ca_x509->get_subject_keyid });

    for(my $cursor = $self->{db}->search(-initially_valid_at => "now",
                                   -revoked => 1);
        $cursor->has_more; $cursor->next) {
        my $serial = $cursor->certificate->get_serial;
        my $time = $cursor->revocation_time;
        my $reason = $cursor->revocation_reason;
        my $ctime = $cursor->compromise_time;
        my $holdoid = $cursor->hold_instruction;

        $crl->add_entry
            ($serial, $time,
             (defined($reason) ? (-reason => $reason) : ()),
             (defined($ctime) ? (-compromise_time => $ctime) : ()),
             (defined($holdoid) ? (-hold_instruction => $holdoid) : ()),
            );
    }

    return App::CamelPKI::CRL->parse($crl->sign($self->_private_key,
                                           $opts{-signature_hash}));
}

=head2 get_certificates_issued()

Builds a list of certificates already issued by the CA and not revoked.
Certificates are returned as an array of L<App::CamelPKI::Certificate>.

=cut

sub get_certificates_issued(){
	my ($self) = @_;
	my @certs;

    for(my $cursor = $self->{db}->search();        
        $cursor->has_more; $cursor->next) {
        	push @certs, $cursor->certificate;
    }
	return @certs;
}

=head2 get_certificates_revoked()

Builds a list of certificates already issued by the CA and not revoked.
Certificates are returned as an array of L<App::CamelPKI::Certificate>.

=cut

sub get_certificates_revoked(){
	my ($self) = @_;
	my @certs;

    for(my $cursor = $self->{db}->search(-revoked => 1);        
        $cursor->has_more; $cursor->next) {
        	push @certs, $cursor->certificate;
    }
	return @certs;
}

=head2 get_certificate_by_serial($serial)

Builds a list of certificates already issued by the CA and not revoked.
Certificates are returned as an array of L<App::CamelPKI::Certificate>.

=cut

sub get_certificate_by_serial(){
	my ($self, $serial) = @_;
	
    for(my $cursor = $self->{db}->search( -serial=>$serial, -revoked=>undef ); $cursor->has_more; $cursor->next) {
        	warn "on est bon";
        	return $cursor->certificate;
    }
}

=head2 rescind()

Cancels the ingoing transaction and let the object in an unusable
status. Invoked automatically in case of a template exception.

=cut

sub rescind { die "UNIMPLEMENTED" }

=head1 FACETS

=head2 database_facet($certtemplate)

Returns a facet of the CA database (as passed to L</load>) resticted
in read only and using a filter that only allow to consult certificates
generated using $certtemplate as first parameters issued to L</issue>.

=cut

sub database_facet {
    my ($self, $template) = @_;

    my $retval = Class::Facet->make("App::CamelPKI::CA::CADBFacet",
                                    $self->database);
    $retval->{template} = $template;
    return $retval;

    package App::CamelPKI::CA::CADBFacet;

    use Class::Facet from => "App::CamelPKI::CADB",
        on_error => \&App::CamelPKI::Error::Privilege::on_facet_error,
        delegate => [ qw(max_serial) ];

    sub search {
        my ($facetself, $trueself) = Class::Facet->selves(\@_);
        return $trueself->search(template => $facetself->{template}, @_);
    }
}

=head2 facet_readonly()

Returns a copy of this object in read only: only L</certificate> and
L</database> methods can be invoked.

=cut

sub facet_readonly {
    return Class::Facet->make("App::CamelPKI::CA::FacetReadonly", shift);

    package App::CamelPKI::CA::FacetReadonly;

    use Class::Facet from => "App::CamelPKI::CA",
        on_error => \&App::CamelPKI::Error::Privilege::on_facet_error,
            delegate => [qw(rescind certificate is_operational database
                            database_facet)];

    # Cascading facets (yow!)
    BEGIN { foreach my $methname
                (qw(facet_readonly facet_crl_only
                    facet_certtemplate facet_operational)) {
                    no strict "refs";
                    *{"$methname"} = \&{"App::CamelPKI::CA::$methname"};
                }
        }
}

=head2 facet_crl_only()

Returns a copy of this object with restricted privileges: besides the
read-only accessors (see L</facet_readonly>), a holder of a reference
to the returned object only has the right to issue a new CRL.  This is
an appropriate level of privilege to hand out to an unauthenticated
user.

=cut

sub facet_crl_only {
    return Class::Facet->make("App::CamelPKI::CA::FacetCRLOnly", shift);

    package App::CamelPKI::CA::FacetCRLOnly;
    BEGIN { our @ISA = qw(App::CamelPKI::CA::FacetReadonly); }
    use Class::Facet delegate => "issue_crl";
}


=head2 facet_certtemplate($certtemplate)

Returns a copy of this object with restricted privileges: among the
methods that writes, only L</certificate>, L</commit>, L</issue>,
L</revoke> and L</database> can be invoked, and for the last three
methods, access is restricted to certificates belonging to
$certtemplate. The returned object represents the right to generate
and to revoke certificates in a specific template.

=cut

sub facet_certtemplate {
    my ($self, $certtemplate) = @_;

    my $facet = Class::Facet->make("App::CamelPKI::CA::FacetCertTemplate",
                                   $self);
    $facet->{certtemplate} = $certtemplate;
    return $facet;

    package App::CamelPKI::CA::FacetCertTemplate;

    BEGIN { our @ISA = qw(App::CamelPKI::CA::FacetReadonly) };

    use Class::Facet delegate => [qw(issue_crl commit)];

    # Still meta-programming a bit, but I don't think Class::Facet could
    # help me much here and remain generic.
    BEGIN { foreach my $methname (qw(issue revoke)) {
        my $method = sub {
            my ($facetself, $trueself) = Class::Facet->selves(\@_);
            throw App::CamelPKI::Error::Privilege
                ("Unauthorized certificate template $_[0]")
                    if ($_[0] && $_[0] ne $facetself->{certtemplate});
            unshift @_, $trueself;
            goto $trueself->can($methname);
        };
        { no strict "refs"; *{"$methname"} = $method; }
    } }

  sub database {
      my $self = shift;
      return $self->{delegate}->database_facet($self->{certtemplate});
  }
}

=head2 facet_operational()

Returns a copy of this object with restricted privileges: the L</set_keys>
cannot be revoked anymore. This facet is suitable to pass to a "regular"
controller which has no rights to modify the CA keys.

Instead of returning an object which could do nothing, I<facet_operational>
throw an exception if L</is_operational> is not true.

=cut

sub facet_operational {
    my ($self) = @_;
    throw App::CamelPKI::Error::State
        ("cannot make operational facet "
         . "of non-operational CA") unless $self->is_operational;
    return bless { delegate => $self }, "App::CamelPKI::CA::FacetOperational";

    package App::CamelPKI::CA::FacetOperational;
    BEGIN { our @ISA = qw(App::CamelPKI::CA::FacetReadonly); }

    use Class::Facet delegate => [qw(issue revoke commit issue_crl get_certificates_issued get_certificates_revoked get_certificate_by_serial)];
}

=begin internals

=cut

=head1 INTERNAL METHODS

=head2 _certificate_path

=head2 _key_path

Retrun respectives access paths to the certificate and private keys, in
the directory passed to L</load>.

=cut

sub _certificate_path { catfile(shift->{cryptdir}, "ca.crt") }
sub _key_path { catfile(shift->{cryptdir}, "ca.key") }

=head2 _private_key

Returns an instance of 
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::PrivateKey> which modelise the
CA private key.

=cut

sub _private_key {
    my ($self) = @_;
    $self->{private_key} ||=
        Crypt::OpenSSL::CA::PrivateKey->parse
            (scalar(read_file($self->_key_path)));
}

require My::Tests::Below unless caller;

1;

__END__

=head1 TEST SUITE

=cut

use Test::More qw(no_plan);
use Test::Group;
use File::Spec::Functions qw(catdir catfile);
use Fatal qw(mkdir);
use App::CamelPKI::Certificate;
use App::CamelPKI::PrivateKey;
use App::CamelPKI::Test qw(%test_rootca_certs %test_keys_plaintext
                      %test_public_keys);
use App::CamelPKI::Error;
use App::CamelPKI::CADB;

=pod

If the following code is activated (replacing C<if (0)> by 
C<if (1)>), SQL requests done by L<App::CamelPKI::CADB> will be printed
during tests execution.

=cut

App::CamelPKI::CADB->debug_statements(sub {
    my ($sql, @bind_values) = @_;
    map { $_ = "<der>" if m/[\000-\010]/ } @bind_values;
    diag join(" / ", $sql, @bind_values) . "\n";
}) if (0);

my $cadir = catdir(My::Tests::Below->tempdir, "test-CA");
mkdir($cadir);

sub load_ca {
    my $cadb = load App::CamelPKI::CADB($cadir);
    return load App::CamelPKI::CA($cadir, $cadb);
}

test "creation and key ceremony for a CA" => sub {
    my $ca = load_ca;
    ok(! $ca->is_operational);
    try {
        $ca->certificate;
        fail;
    } catch Error with {
        pass;
    };
    my $cert = parse App::CamelPKI::Certificate($test_rootca_certs{"rsa1024"});
    my $key = parse App::CamelPKI::PrivateKey($test_keys_plaintext{"rsa1024"});
    $ca->set_keys(-certificate => $cert, -key => $key);
    ok($ca->is_operational);
    ok($ca->certificate->equals($cert));
};

=pod

The I<App::CamelPKI::CertTemplate::Foo> class has been copy-pasted from
L<App::CamelPKI::CertTemplate/SYNOPSIS> in its march 22 2007 release. Thats
not that bad if the two code pieces are to diverge one of these days.

=cut

{
    package App::CamelPKI::CertTemplate::Foo;

    use base "App::CamelPKI::CertTemplate";
    use Crypt::OpenSSL::CA;

    sub list_keys { qw(name uid) }

    sub prepare_certificate {
        my ($class, $cacert, $cert, %opts) = @_;
        $class->copy_from_ca_cert($cacert, $cert);
        $cert->set_notBefore($opts{time});
        $cert->set_notAfter($cacert->get_notAfter());
        $cert->set_subject_DN
            (Crypt::OpenSSL::CA::X509_NAME->new_utf8
             ("2.5.4.11" => "Internet widgets",
              CN => $opts{name}, x500UniqueIdentifier => $opts{uid}));
        # ...
    }

    # Only one certificate may be valid at one time for a given UID:
    sub test_certificate_conflict {
        my ($class, $db, %opts) = @_;
        return $db->search(uid => $opts{uid});
    }

    # Sample coherency enforcement: no duplicate names, no duplicate
    # UIDs.
    sub test_issued_certs_coherent {
        my ($class, $db, @opts_array) = @_;
        $class->test_no_duplicates(["uid"], @opts_array);
        $class->test_no_duplicates(["name"], @opts_array);
    }
}

test "synopsis" => sub {
    my $code = My::Tests::Below->pod_code_snippet("synopsis");
    $code =~ s/my //g;
    my $directory = $cadir;
    my $pubkey = App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"});
    my ($ca, $joecert, $fredcert, $crl);
    my $cadb = load App::CamelPKI::CADB($cadir);
    eval $code; die $@ if $@;

    ok($joecert->isa("App::CamelPKI::Certificate"));
    like($joecert->get_subject_DN->to_string, qr/Joe/);
    ok($fredcert->isa("App::CamelPKI::Certificate"));
    like($fredcert->get_subject_DN->to_string, qr/Fred/);
    ok($crl->isa("App::CamelPKI::CRL"));
    ok($crl->is_member($joecert));
    ok(! $crl->is_member($fredcert));
};

test "->facet_operational" => sub {
    my $ca = load_ca->facet_operational;
    my $cacert = $ca->certificate;
    try {
        $ca->set_keys(-certificate => $cacert);
        fail("this method is not allowed by the facet");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };
    ok($ca->issue_crl->isa("App::CamelPKI::CRL"),
       "the facet_operational is operational");
    ok($ca->facet_operational->facet_operational->certificate
       ->isa("App::CamelPKI::Certificate"), "facet_operational idempotent");
};

test "Coherence and forced revocation" => sub {
    my $ca = load_ca;
    my $pubkey = App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"});
    $ca->issue("App::CamelPKI::CertTemplate::Foo", $pubkey,
               name => "user1", uid => 1);

    # I freely pick in the $cert private fields: 
    my $cert = $ca->{signed}->[0]->{cert};
    is(ref($cert), "App::CamelPKI::Certificate");
    try {
        $ca->revoke("App::CamelPKI::CertTemplate::Foo", $cert);
        fail("It's prohibited to revoke certificates "
             . "in the current transaction");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };

    # This operation may have made the $ca object unusable, so we
    # try again:
    $ca = load_ca->facet_certtemplate("App::CamelPKI::CertTemplate::Foo");
    $ca->issue("App::CamelPKI::CertTemplate::Foo", $pubkey,
               name => "user1", uid => 1);

    # A new certificate for UID 43 must revoke the old one:
    my $cursor = $ca->database->search(name => "Fred");
    is($cursor->revocation_time(), undef,
       "The Fred's certificate is not yet revoked");
    is(my $fredid = $cursor->infos->{uid}->[0], 43,
       "Using CADB to get the Fred's UID")
        or warn Data::Dumper::Dumper(scalar($cursor->infos));
    # Fred got his operation, so he need a new certificate:
    $ca->issue("App::CamelPKI::CertTemplate::Foo", $pubkey,
               name => "Frida", uid => $fredid);
    $cursor = $ca->database->search(name => "Fred", -revoked => undef);
    isnt($cursor->revocation_time(), undef,
       "the Fred certificate is revoked");
    is($ca->database->search(-revoked => undef, name => "Frida")->count, 0,
       q"No means to use $ca->databae to get "
       . q"new certificats in preview");

    $ca->issue("App::CamelPKI::CertTemplate::Foo", $pubkey,
               name => "Frida", uid => 555);
    pass("the template did not catched the trickery...");

    try {
        $ca->commit();
        fail("the coherence check should been triggered now");
    } catch App::CamelPKI::Error::User with {
        pass("two certificates for Frida, that's a bad thing");
    };
};

test "->facet_certtemplate" => sub {
    my $ca = load_ca->facet_certtemplate("No::Such::CertTemplate");
    my @no_certs = $ca->database->search(-revoked => 0);
    is(scalar(@no_certs), 0, "no certificate in the dummy template");
};

test "facets intersection" => sub {
    my $ca = load_ca->facet_certtemplate("No::Such::CertTemplate")
        ->facet_readonly;

    my @no_certs = $ca->database->search(-revoked => 0);
    is(scalar(@no_certs), 0, "no certificate in the dummy template");

    try {
        $ca->issue_crl();
        fail("this method is not in the facet");
    } catch App::CamelPKI::Error::Privilege with {
        pass;
    };
};

test "capability discipline "
    . "sur le CertTemplate->test_certificate_conflict" => sub {
    my $pubkey = App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"});
    our $ca = load_ca;
    our ($cert_in_other_template) = $ca->database->search();
    ok($cert_in_other_template->isa("App::CamelPKI::Certificate"));
    {
        package Bogus::CertTemplate;

        our @ISA = qw(App::CamelPKI::CertTemplate::Foo); # The same as
                                                    # hereafter
        sub test_certificate_conflict {
            my ($class, $db, @keyvals) = @_;

            use Test::More;
            is($db->search(-revoked => undef,
                           -certificate => $cert_in_other_template)
              ->count(), 0, <<"MESSAGE");
test_certificate_conflict must not see other templates's certificates.
MESSAGE
            foreach my $cert (map {$_->{cert}} @{$ca->{signed}}) {
                is($db->search(-revoked => undef,
                               -certificate => $cert)->count(), 0,
                   <<"MESSAGE");
test_certificate_conflict must not see certificates of the current
transaction.
MESSAGE
            }
            return $class->SUPER::test_certificate_conflict($db, @keyvals);
        }
    }
    #

    $ca->issue("Bogus::CertTemplate", $pubkey,
               name => "Harry", uid => 1001);
    $ca->issue("Bogus::CertTemplate", $pubkey,
               name => "Sally", uid => 1002);
    $ca->commit();
};

test "Evil CertTemplate" => sub {
    my $ca = load_ca;
    our ($oups_evil_certificat) = $ca->database->search();
    ok($oups_evil_certificat->isa("App::CamelPKI::Certificate"));
    {
        package Evil::CertTemplate;

        our @ISA = qw(App::CamelPKI::CertTemplate::Foo); # The one of L</SYNOPSIS>

        sub normalize_args {
            fail("GOTCHA!");
        }

        sub test_certificate_conflict {
            return $oups_evil_certificat;
        }
    }
    #

    my $pubkey = App::CamelPKI::PublicKey->parse($test_public_keys{"rsa1024"});
    try {
        $ca->issue("Evil::CertTemplate", $pubkey,
                   name => "zoinx", uid => 2000);
        fail("He sank my certificate!!!");
    } catch App::CamelPKI::Error::Privilege with {
        pass("Well tried, but boo, you failed!");
    };
};

=end internals

=cut

