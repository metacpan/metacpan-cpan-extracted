package App::CamelPKI::Model::CA;

use strict;
use warnings;

=head1 NAME

B<App::CamelPKI::Model::CA> - Constructor of CA instances used by the whole
application.

=head1 DESCRIPTION

The I<App::CamelPKI::Model::CA> object is a singleton owned by Catalyst to
construct instances of L<App::CamelPKI::CA> following the application
configuration, and distribute them to the controllers at the
L<App::CamelPKI/model> initiative.
I<App::CamelPKI::Model::CA> have some methods on its own like 
L</certification_chain> to modelise the Camel-PKI Operational CA in what
is particular.

=head1 CAPABILITY DISCIPLINE

An instance of I<App::CamelPKI::Model::CA> modelise nearly the same 
amount of privileges than an instance of L<App::CamelPKI::CA> that she
embeds (excepted for the L</certification_chain> that is a
I<App::CamelPKI::Model::CA> particularism). In the same way,
I<App::CamelPKI::Model::CA> have the same facet set as I<App::CamelPKI::CA>.

=cut

use base 'Catalyst::Model';
use Class::Facet;
use App::CamelPKI::RestrictedClassMethod qw(:Restricted);
use App::CamelPKI::PrivateKey;
use App::CamelPKI::Certificate;
use App::CamelPKI::CADB;
use App::CamelPKI::CA;

=head1 CONFIGURATION

The following variables are configurable in
I<App::CamelPKI::Model::CA>:

=over

=item I<db_dir>

The directory where the AC database and its cryptographic
material (certificates and keys) are to be installed.

=item I<keysize>

The size of keys used for the Key Ceremony.

=back

=cut


=head1 METHODS

=head2 new

Constuctor of the singleton called by Catalyst. Overloaded to use
L<App::CamelPKI::RestrictedClassMethod>, so that it cannot be called from
anywere, except from the application's initialization sequence.

=cut

sub new : Restricted { shift->SUPER::new(@_) }

=head2 set_brands($ca_brand, $cadb_brand)

Conveys authority to create instances of L<App::CamelPKI::CA> and
L<App::CamelPKI::CADB> to this class when the restricted class method
discipline is enabled (see L<App::CamelPKI::RestrictedClassMethod>). Called
by L<App::CamelPKI/setup> after restricting all the constructors in the
application .  $ca_brand and $cadb_brand are the respective brands for
classes B<App::CamelPKI::CA> and B<App::CamelPKI::CADB>, as created by
L<App::CamelPKI::RestrictedClassMethod/grab>.

This class method is in turn restricted, so that only the application
initialization code may call it.  By default (eg in tests),
B<App::CamelPKI::Model::CA> uses fake brands (see
L<App::CamelPKI::RestrictedClassMethod/fake_grab>).

=cut

{
    my ($cabrand, $cadbbrand) =
        map { App::CamelPKI::RestrictedClassMethod->fake_grab($_) }
            qw(App::CamelPKI::CA App::CamelPKI::CADB);
    sub set_brands : Restricted {
        (undef, $cabrand, $cadbbrand) = @_;
    }

    sub _invoke_on_CA   { $cabrand->invoke(@_) }
    sub _invoke_on_CADB { $cadbbrand->invoke(@_) }
}

=head2 instance

Verify this CA has already undergone its Key Ceremony, or else throw an
exception; then create and returns an App::CamelPKI::CA instance which has
all privileges and represents the (unique) Operational CA installed on
this host.

Note that I<instance> is B<not> idempotent, and returns different
instances at each invocation. Were it not the case, constructors could
construct a covert channel using the shared instance, which is
mutable, and so a malicious controller could hide some information for
constructors that will later run in the same UNIX process.

=cut

sub instance {
    my ($self) = @_;
    my $ca = $self->_make_ca;
    unless ($ca->is_operational) {
        throw App::CamelPKI::Error::State(<<"MESSAGE");
The AC is not operational, please run
script/camel_pki_keyceremony.pl
MESSAGE
    }
    return $ca;
}

=head2 db_dir()

Returns the directory where are stored the App-PKI Certificate
Authority informations (certification chain, certificate, private
keys and AC database).

=cut

sub db_dir { shift->{db_dir} }

=head2 do_ceremony($privdir, $webserver)

Runs the B<Key Ceremony> for the Camel-PKI Certificate Authority. The
Operational CA and Root CA certificates are recorded in the private
directory configured with the I<db_dir> key (see L</CONFIGURATION>).
The Root CA certificate and key, and the administrator credentials are
written into $privdir, under the respective names C<ca0.key>,
C<ca0.crt>, C<admin.key> and C<admin.pem>. Last but not least, the Web
server certificate and key are installed in $webserver, an
L<App::CamelPKI::SysV::Apache> instance.

=cut

sub do_ceremony {
    use File::Slurp;
    use File::Spec::Functions qw(catfile);
    use App::CamelPKI::CertTemplate::CA;
    use App::CamelPKI::CertTemplate::PKI;
    use Sys::Hostname ();

    my ($self, $privdir, $webserver) = @_;

    throw App::CamelPKI::Error::Internal("INCORRECT_ARGS")
        unless (-d $privdir);

    # REFACTORME: use a complete App::CamelPKI::CA instance for the
    # Root CA
    my $privKeyCA0 = App::CamelPKI::PrivateKey->genrsa($self->{keysize});
    write_file(catfile($privdir, "ca0.key"),
               $privKeyCA0->serialize(-format => "PEM"));
    $privKeyCA0 = $privKeyCA0->as_crypt_openssl_ca_privatekey;
    my $certCA0 = Crypt::OpenSSL::CA::X509->new
        ($privKeyCA0->get_public_key);
    App::CamelPKI::CertTemplate::CA0->prepare_self_signed_certificate
        ($certCA0);
    my $pemCA0 = $certCA0->sign($privKeyCA0,"sha256");
    write_file(catfile($privdir, "ca0.crt"), $pemCA0);
    write_file($self->_root_ca_cert_path, $pemCA0);

    my $privKeyCA1 = App::CamelPKI::PrivateKey->genrsa($self->{keysize});
    my $certCA1 = Crypt::OpenSSL::CA::X509->new
        ($privKeyCA1->as_crypt_openssl_ca_privatekey->get_public_key);
    App::CamelPKI::CertTemplate::CA1->prepare_certificate($certCA0, $certCA1);
    $certCA1->set_serial("0x2"); # RFC3280 § 4.1.2.2 forbids zero
    my $pemCA1 = $certCA1->sign($privKeyCA0, "sha256");

    my $CA0 = App::CamelPKI::Certificate->parse($pemCA0);
    my $CA1 = App::CamelPKI::Certificate->parse($pemCA1);

    my $ca = $self->_make_ca;
    
    $ca->set_keys (-certificate => $CA1, -key =>  $privKeyCA1);

    my $webserverkey = App::CamelPKI::PrivateKey->genrsa($self->{keysize});
    my $web_dns = exists($self->{dns_webserver}) ? 
    	 $self->{dns_webserver} : "undef";
    $ca->issue
        ("App::CamelPKI::CertTemplate::PKI1", $webserverkey->get_public_key,
         dns => $web_dns);
    my ($webservercert) = $ca->commit;
    $webserver->set_keys
        (-certificate => $webservercert,
         -key => $webserverkey,
         -certification_chain => [ $CA1, $CA0 ]);

    my ($admincert, $adminkey) = $self->make_admin_credentials;
    write_file(catfile($privdir, "admin.pem"), $admincert->serialize);
    write_file(catfile($privdir, "admin.key"), $adminkey->serialize);

    return $self;
}

=head2 make_admin_credentials

Regenerate an initial administrator certificate and private key, and
returns a pair ($cert, $key) which are respectively
L<App::CamelPKI::Certificate> and L<App::CamelPKI::PrivateKey> instances. Old
administrator certificates are revoked.

=cut

sub make_admin_credentials {
    my ($self) = @_;

    my $ca = $self->instance;
    my $adminkey = App::CamelPKI::PrivateKey->genrsa($self->{keysize});
    my $admintemplate = "App::CamelPKI::CertTemplate::PKI2";
    $ca->issue($admintemplate, $adminkey->get_public_key);
    $ca->revoke($admintemplate, $_)
        for $ca->database->search(template => $admintemplate);
    my ($admincert) = $ca->commit;
    return ($admincert, $adminkey);
}

=head2 certification_chain

Returns an L<App::CamelPKI::Certificate> objects list which represents
certificates that have been signed by this Certificate Authority, excluding
this CA certificate itself (which is accessible using
L<App::CamelPKI::CA/certificate>).
Returns an empty list for an autosigned Certicate Authority.

=cut

sub certification_chain {
    my ($self) = @_;
    return App::CamelPKI::Certificate->load($self->_root_ca_cert_path);
}

=head1 FACETS

=head2 facet_readonly

=head2 facet_crl_only

=head2 facet_certtemplate($template)

=head2 facet_operational

These methods create and return a new I<App::CamelPKI::Model::CA>
object with restricted rights, using the following way:

=over

=item L</do_ceremony>

This method is made inaccessible in all facets.

=item L</instance>

The underlying I<App::CamelPKI::CA> instance returned is restricted in
exactly the same ways as the facet of the same name in
L<App::CamelPKI::CA>.

=back

=cut

foreach my $method (qw(facet_readonly facet_crl_only facet_certtemplate
                       facet_operational)) {
    no strict "refs";
    *{$method} = sub {
        my $self = shift;
        my $facet = Class::Facet->make
            ("App::CamelPKI::Model::CA::FacetAny", $self);
        $facet->{instance} = $self->instance->$method(@_);
        return $facet;
    };
}

{
    package App::CamelPKI::Model::CA::FacetAny;

    sub instance { shift->{instance} }

    use Class::Facet from => "App::CamelPKI::Model::CA",
        delegate => [qw(db_dir certification_chain)];
}

=begin internals

=head2 _make_ca

Build the L<App::CamelPKI::CA> instance which is returned by
L</instance>.

=cut

sub _make_ca {
    my ($self) = @_;
    my $dbdir = $self->db_dir;
    return _invoke_on_CA("load", $dbdir,
                         _invoke_on_CADB("load", $dbdir));
}

=head2 _root_ca_cert_path

As its name indicates it, return the path under I<db_dir>
(see L</CONFIGURATION>) where the AC certificate is stored.

=cut

sub _root_ca_cert_path {
    my ($self) = @_;
    return catfile($self->db_dir, "rootca.crt");
}

require My::Tests::Below unless caller;

1;

__END__

=head1 TEST SUITE

=cut

use Fatal qw(mkdir);
use File::Spec::Functions qw(catfile catdir);
use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Error;
use App::CamelPKI::Test;
use App::CamelPKI::SysV::Apache;
use App::CamelPKI::PrivateKey;
use App::CamelPKI::Certificate;

test "do_ceremony" => sub {
    mkdir(my $ceremonydir = catdir(My::Tests::Below->tempdir, "ceremony0"));
    mkdir(my $cadir = catdir($ceremonydir, "ca"));
    mkdir(my $privdir = catdir($ceremonydir, "priv"));
    mkdir(my $webdir = catdir($ceremonydir, "webserver"));

    my $model_ca = bless { db_dir => $cadir, keysize => 512 },
        "App::CamelPKI::Model::CA";
    try {
        $model_ca->instance;
        fail("->instance should not succeed as the CA is "
             . "not yet operational");
    } catch App::CamelPKI::Error::State with {
        pass;
    };

    my $webserver = App::CamelPKI::SysV::Apache->load($webdir);
    ok(! $webserver->is_operational);

    $model_ca->do_ceremony($privdir, $webserver);
    ok($model_ca->instance->is_operational);
    ok($webserver->is_operational);

    my $ca0key = App::CamelPKI::PrivateKey->load(catfile($privdir, "ca0.key"));
    my $ca0cert = App::CamelPKI::Certificate->load(catfile($privdir, "ca0.crt"));
    ok($ca0key->isa("App::CamelPKI::PrivateKey"));
    ok($ca0cert->isa("App::CamelPKI::Certificate"));
    ok($ca0key->get_public_key->equals($ca0cert->get_public_key));
    $ca0cert->as_crypt_openssl_ca_x509->verify
        ($ca0cert->as_crypt_openssl_ca_x509->get_public_key);
    certificate_chain_ok($model_ca->instance->certificate->serialize,
                         [$ca0cert->serialize]);

    my $adminkey = App::CamelPKI::PrivateKey->load
        (catfile($privdir, "admin.key"));
    my $admincert = App::CamelPKI::Certificate->load
        (catfile($privdir, "admin.pem"));
    ok($adminkey->isa("App::CamelPKI::PrivateKey"));
    ok($admincert->isa("App::CamelPKI::Certificate"));
    ok($adminkey->get_public_key->equals($admincert->get_public_key));
    my @certchain = ($model_ca->instance->certificate->serialize,
                     $ca0cert->serialize);
    certificate_chain_ok($admincert->serialize, \@certchain);

    certificate_chain_ok($webserver->certificate->serialize, \@certchain);
};

test "->make_admin_credentials" => sub {
    mkdir(my $dir = catdir(My::Tests::Below->tempdir, "ceremony1"));
    my $model_ca = bless { db_dir => $dir, keysize => 512 },
        "App::CamelPKI::Model::CA";
    $model_ca->do_ceremony($dir, App::CamelPKI::SysV::Apache->load($dir));
    my $admincert = App::CamelPKI::Certificate->load
        (catfile($dir, "admin.pem"));
    ok(! $model_ca->instance->issue_crl->is_member($admincert));

    my ($anotheradmincert, $anotheradminkey) =
        $model_ca->make_admin_credentials();
    ok($anotheradminkey->get_public_key
       ->equals($anotheradmincert->get_public_key));
    ok(! $anotheradmincert->get_public_key
       ->equals($admincert->get_public_key));
    ok(! $model_ca->instance->issue_crl->is_member($anotheradmincert));
    ok($model_ca->instance->issue_crl->is_member($admincert),
       "implicit revocation of previous admin certificates");
};

=end internals

=cut

1;
