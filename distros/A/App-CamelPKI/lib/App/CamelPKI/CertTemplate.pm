#!perl -w

package App::CamelPKI::CertTemplate;
use strict;

=head1 NAME

App::CamelPKI::CertTemplate - A certificate template for Camel-PKI
(abstract class - not instanciable).

=head1 SYNOPSIS

=for My::Tests::Below "synopsis" begin

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

    # Only one certificate must be valid for a given UID:
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

=for My::Tests::Below "synopsis" end

=head1 DESCRIPTION

A B<certificate template> is a certificate "with holes": it fix the rules
used to generate certificates (see L<App::CamelPKI::CA>).

Each subclasses of I<App::CamelPKI::CertTemplate> represent a certificate
template, to be (mainly) used as classes; no object is created as instance
of I<App::CamelPKI::CertTemplate> or one of its subclasses. Moreover, 
I<App::CamelPKI::CertTemplate> is an abstract class; only its subclasses
must be used as templates.

=head1 CAPABILITY DISCIPLINE

Classes inherited from I<App::CamelPKI::CertTemplate> do not encapsulate
any state; they are therefore neutral from a security point of view
and don't carry any privileges.  On the other hand, an
I<App::CamelPKI::CertTemplate> may be used to restrict the rights of an
I<App::CamelPKI::CA> instance; see L<App::CamelPKI::CA/facet_certtemplate>.

=head1 METHODS TO OVERLOAD

Barring an explicit contrary statement, every class that inherits from
I<App::CamelPKI::CertTemplate> must define the following methods:

=head2 prepare_certificate($cacertobj, $eecertobj, $key1 => $val1, ...)

Prepares a certificate for L<App::CamelPKI::CA/sign>, using $key1 => $val1,
... to fill out the variable fields.  Keys ($key1, etc.) are always
among those listed by L</list_keys>. Values are character strings or
references to lists of character strings for templates allowing
multi-valued fields (not implemented yet).

The method is called in a scalar context; it shall modify
I<$eecertobj>, an instance of
L<Crypt::OpenSSL::CA/Crypt::OpenSSL::CA::X509> initially empty, by
calling mutator methods on it, until $eecertobj is ready to be signed
by the CA.  To perform this task, I<prepare_certificate> may use
$cacertobj, an instance of L<App::CamelPKI::Certificate> (B<not>
I<Crypt::OpenSSL:CA::X509>) which represents the CA certificate,
and/or the key-value data passed in parameters.

Keys names ($key1, ...) are mostly chosen freely by the certificate
template implementor, except for a short number that are "well known"
and always provided by L<App::CamelPKI::CA>:

=over

=item I<< time => $zulutime >>

The date and time to be considered as the current time, in "Zulu"
format.  Typically, the certificate validity period start at
$zulutime.

=back

=cut

# abstract method

=head2 list_keys()

Called in list context, returns the valid nominative informations keys
list to be passed to L</prepare_certificate> and
L</test_certificate_conflict>. 

The CA will not give any key to this methods unless these keys are
present in the return value of I<list_keys()>, excepted C<time> which
will be passed even if the template do not mention it.

The base class implementation returns the empty list, which is only
appropriate for Camel-PKI internal certificates.

=cut

sub list_keys { return }

=head2 signature_hash

Returns the cryptographic algorithm to use for certificates
signing, under the form of a name ("md5" or "sha1", for example).

The base class implementation returns "sha256", as "md5" and "sha1"
are now not recommanded because of progress done on their cryptanalysis
(L<http://www.win.tue.nl/~bdeweger/CollidingCertificates/>).

=cut

sub signature_hash { "sha256" }

=head2 test_certificate_conflict($db, $key1 => $val1, ...)

FIXME-TR: ouch, du pour une sommeillant comme moi - � faire la t�te fraiche
Doit se terminer avec succès si et seulement si le gabarit de
certificat considère qu'il est légitime d'ajouter à la base $db (une
instance de L<App::CamelPKI::CADB>) un certificat avec les options
nominatives $key1 => $val1, ... tel que L</prepare_certificate> le
créerait, et lancer une exception dans le cas contraire.  Plus
précisément, I<certificate_test_conflict> est appelé en contexte liste
et doit

=over

=item *

return an empty list if the certificate creation is unconditionnaly
valid, due the to actual $db status;

=item *

or must return a certificates list (in the form of L<App::CamelPKI::Certificates>
instances) if I<certificate_test_conflict> thinks to be conflict with
the new putative certificate. The calling CA then decides its have to
cancel the transaction, revoke certificates, or bypass the restriction
(see L<App::CamelPKI::CA/Coherence>);

=item *

or must throw an exception if there is no means to consider such a 
certificate compliant in terms of the certificate policy.

=back

FIXME-TR: creuv�...
Noter que le principe de moindre privilège s'applique à
I<test_certificate_conflict>, et que la version de $db qu'il récupère
est en réalité une facette de la véritable base de données de CA, en
lecture seule et dont le contenu est de surcroît filtré sur la base
d'un I<need-to-know>: typiquement, I<test_certificate_conflict> ne
pourra voir que les certificats qu'il a lui-même fabriqués par le
passé.

The base class implementation is always happy, and always returns
the empty list.

=cut

sub test_certificate_conflict { return }

=head2 test_issued_certs_coherent( \%data1, \%data2, ... )

TODO-TR: stoppedhere
Doit se terminer avec succès si et seulement si le gabarit de
certificat considère qu'il est légitime d'émettre B<en une seule
transaction> les certificats dont les données nominatives figurent en
argument.  I<test_issued_certs_coherent> doit se terminer
normalement s'il estime que les certificats qui seraient créés en
appelant C<prepare_certificate(%data1)>,
C<prepare_certificate(%data2)>, etc sont cohérents les uns avec les
autres, et lever une exception dans le cas contraire.  L'AC prend
cette information en compte comme il est décrit dans
L<App::CamelPKI::CA/Cohérence>.

The base class implementation is always happy, and always ends
with success.

=cut

sub test_issued_certs_coherent { return }

=head1 METHODS PROVIDED BY THE BASE CLASS

Dans sa tâche d'implémenter les L</MÉTHODES À SURCHARGER>, le
programmeur est aidé par les méthodes suivantes, dont il bénéficie par
voie d'héritage:

=head2 normalize_opts($template, $key1 => $val1, ...)

Lorsqu'on invoque cette méthode (indifféremment de classe ou
d'instance) en contexte liste, elle renvoie la liste associative
passée en paramètre ($key1 => $val1, ...) après l'avoir «nettoyée» de
la façon suivante :

=over

=item *

les clefs ($key1, $key2, ...) qui ne valident pas l'expression
rationnelle qr/^[a-z0-9_]+$/i provoquent une exception; celles qui ne
font pas partie de la liste des clefs reconnues par $template (d'après
L<App::CamelPKI::CertTemplate/list_keys>) sont supprimées.

=item *

les valeurs ($val1, $val2, ...) doivent être soit des chaînes de
caractères soit des références sur des tableaux de chaînes de
caractères, et ne pas contenir C<undef>. Toutes les valeurs sont
chaînifiées, et si une même clef apparaît plusieurs fois dans la liste
d'arguments de I<normalize_opts> seule sa dernière occurence est prise
en compte.

=back

La valeur de retour est une liste associative dont toutes les valeurs
sont soit des vraies chaînes, soit des références vers des tableaux de
vraies chaînes (pas C<undef>, pas d'objet chaînifiable).

Cette méthode est également utilisée directement par L<App::CamelPKI::CA>
pour préparer les arguments avant d'infoquer
L</test_certificate_conflict> et L</test_issued_certs_coherent>; dans
ce cas, pour des raisons de sécurité, cette méthode doit être invoquée
B<explicitement> dans la classe de base à l'aide de l'idiome suivant :

=for My::Tests::Below "explicit class idiom" begin

  my %opts = $template->App::CamelPKI::CertTemplate::normalize_opts(@opts);

=for My::Tests::Below "explicit class idiom" end

sans quoi le gabarit de certificat aurait le droit de modifier
l'implémentation de cette méthode à sa guise.

=cut

sub normalize_opts {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, %opts) = @_;
    return map {
        throw App::CamelPKI::Error::Internal("INCORRECT_ARGS",
                                        -details => "Wrong key $_")
            unless m/^([a-z0-9_]+)$/i;
        my $k = $1; # Déteinté
        if (! defined $opts{$k}) {
            throw App::CamelPKI::Error::Internal
                ("INCORRECT_ARGS",
                 -details => "Undef value for $k not allowed");
        } elsif (ref($opts{$k}) eq "ARRAY") {
            ( $k => [ map {
                defined or throw App::CamelPKI::Error::Internal
                    ("INCORRECT_ARGS",
                     -details => "Undef value found in value list for $k");
                "$_";
            } @{$opts{$k}} ] );
        } else {
            ( $k => "$opts{$k}" );
        }
    } ($self->list_keys);
}

=head2 copy_from_ca_cert($cacertobj, $eecertobj, %options)

Copie automatiquement de $cacertobj dans $eecertobj les champs qui
sont nécessaires à la validation du nouveau certificat $eecertobj au
sens de RFC3280. Les copies suivantes sont faites inconditionnellement:

=over

=item *

l'C<issuer> de $cacertobj est copié en tant que C<subject> de
$eecertobj;

=item *

si le certificat $cacertobj possède un C<subjectKeyIdentifier>, alors
celui-ci sera inscrit en tant que C<keyid> dans
l'C<authorityKeyIdentifier> de $eecertobj.

=back

Les options nommées suivantes permettent d'altérer le comportement de
cette méthode :

=over

=item I<< -authoritykeyid_issuer => 1 >>

Copie également l'C<issuer> et le numéro de série du certificat d'AC
sous la forme des champs de même nom dans l'extension
C<authorityKeyIdentifier> de $eecertobj. Noter que cette pratique est
décommandée par le I<X509 style guide>.

=back

=cut

sub copy_from_ca_cert {
    my ($class, $cacert, $eecert, %opts) = @_;

    $eecert->set_issuer_DN($cacert->get_subject_DN);
    my %keyidstuff;
    if (defined(my $keyid = $cacert->get_subject_keyid)) {
        $keyidstuff{keyid} = $keyid;
    }
    if ($opts{-authoritykeyid_issuer}) {
        $keyidstuff{issuer} = $cacert->get_issuer_DN;
        $keyidstuff{serial} = $cacert->get_serial;
    }
    $eecert->set_extension
        ("authorityKeyIdentifier" => \%keyidstuff) if %keyidstuff;
}

=head2 test_no_duplicates(\@keys, \%hash1, \%hash2, ...)

An usefull primitive to implement L</test_issued_certs_coherent>:
test there is no two certificates with the same keys in the @keys
subset, among \%hash1, \%hash2, ... tables.
I<test_no_duplicates> triggers an exception if it's the case.

Order of multi-valuated fields is not relevant, so that the following
call fails:

=for My::Tests::Below "test_no_duplicates fail" begin

   App::CamelPKI::CertTemplate->test_no_duplicates
      ([qw(foo bar)], { foo => [ 1, 2 ], bar => "bo", quux => 42 },
                      { foo => [ 2, 1 ], bar => "bo", quux => "Bah." });

=for My::Tests::Below "test_no_duplicates fail" end

On the other end, the cardinal is important, so that the following call
succeeds:

=for My::Tests::Below "test_no_duplicates success" begin

   App::CamelPKI::CertTemplate->test_no_duplicates
      ([qw(foo baz)], { foo => [ 1, 1 ] }, { foo => [ 1 ] });

=for My::Tests::Below "test_no_duplicates success" end

=cut

sub test_no_duplicates {
    my ($class, $keysref, @hashes) = @_;

    my $approx_collisions = {};
    foreach my $hash (@hashes) {
        my $approxkey = join("/", map {
            ($_, ( ref($hash->{$_}) eq "ARRAY" ? sort @{$hash->{$_}} :
                   defined($hash->{$_}) ? $hash->{$_} : '<undef>' ));
        } @$keysref);
        LOOKALIKE: foreach my $lookalike
            (@{$approx_collisions->{$approxkey}}) {
                foreach my $key (@$keysref) {
                    my ($v1, $v2) = ($lookalike->{$key},
                                     $hash->{$key});
                    next LOOKALIKE if (defined($v1) xor defined($v2));
                    next LOOKALIKE if ((ref($v1) eq "ARRAY") xor
                                       (ref($v2) eq "ARRAY"));
                    if (! defined($v1)) {
                        # Rien du tout
                    } elsif (ref($v1) eq "ARRAY") {
                        my @v1 = sort @$v1; my @v2 = sort @$v2;
                        next LOOKALIKE if (@v1 != @v2);
                        foreach my $i (0..$#v1) {
                            next LOOKALIKE if $v1[$i] ne $v2[$i];
                        }
                    } else {
                        next LOOKALIKE if ($v1 ne $v2);
                    }
                }
                throw App::CamelPKI::Error::User
                    ("Duplicate certificate in transaction",
                     -nominative_data1 => $hash,
                     -nominative_data2 => $lookalike);
            }
        push @{$approx_collisions->{$approxkey}}, $hash;
    }
}

1;

__END__

# Fixes Emacs indentation.  Go figure.
sub foo {
}

use Test::More qw(no_plan);
use Test::Group;
use App::CamelPKI::Test
    qw(%test_rootca_certs %test_keys_plaintext %test_public_keys
       certificate_chain_ok);
use App::CamelPKI::Certificate;
use App::CamelPKI::Error;

test "synopsis" => sub {
    my $synopsis = My::Tests::Below->pod_code_snippet("synopsis");
    eval $synopsis; die $@ if $@;
    my $cacert = App::CamelPKI::Certificate->parse
        ($test_rootca_certs{rsa1024});
    my $eecert = Crypt::OpenSSL::CA::X509->new
        (Crypt::OpenSSL::CA::PublicKey->parse_RSA
         ($test_public_keys{rsa1024}));
    App::CamelPKI::CertTemplate::Foo->prepare_certificate
        ($cacert, $eecert, time => "20041005102000Z",
         name => "Jean-Baptiste", uid => 2);
    my $pem = $eecert->sign
        (Crypt::OpenSSL::CA::PrivateKey->parse
         ($test_keys_plaintext{rsa1024}), "sha256");
    certificate_chain_ok($pem, [ $test_rootca_certs{rsa1024} ]);
};



test "normalize_opts" => sub {
    use JSON;
    sub Bogus::Template::list_keys { qw(foo bar main) };

    my %got = Bogus::Template->App::CamelPKI::CertTemplate::normalize_opts
         (bar => [ qw( ba pa pa ) ],
         foo => JSON::from_json('"yourself"'),
         main => "screen",
         turn => "on");
    is_deeply(\%got, {
                      foo => "yourself",
                      bar => [qw(ba pa pa)],
                      main => "screen",
                     });

    try {
        Bogus::Template->App::CamelPKI::CertTemplate::normalize_opts
            (foo => [ "quux", undef ]);
        fail;
    } catch App::CamelPKI::Error::Internal with {
        pass;
    };

    try {
        Bogus::Template->App::CamelPKI::CertTemplate::normalize_opts
            ("fo+o" => "bar");
        fail;
    } catch App::CamelPKI::Error::Internal with {
        pass;
    };
};

test "explicit idiom of class for ->normalize_opts" => sub {
    {
        package Rogue::CertTemplate;
        sub list_keys { return }
        sub normalize_opts { fail("GOTCHA!") }
    }
    #

    my $template = "Rogue::CertTemplate";
    my @opts;
    eval My::Tests::Below->pod_code_snippet("explicit class idiom");
    die $@ if $@;
    pass;
};

test "->test_no_duplicates" => sub {
    my $code_yes = My::Tests::Below->pod_code_snippet
        ("test_no_duplicates success");
    eval $code_yes; die $@ if $@;
    pass;

    my $code_no = My::Tests::Below->pod_code_snippet
        ("test_no_duplicates fail");
    ok(! eval $code_no);
    is(ref($@), "App::CamelPKI::Error::User")
        or diag $@;
};
