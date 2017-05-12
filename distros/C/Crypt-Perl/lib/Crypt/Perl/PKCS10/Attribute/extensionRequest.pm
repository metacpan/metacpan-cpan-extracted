package Crypt::Perl::PKCS10::Attribute::extensionRequest;

use strict;
use warnings;

=encoding utf-8

=head1 NAME

Crypt::Perl::PKCS10::Attribute::extensionRequest - CSR “extensionRequest” attribute

=head1 SYNOPSIS

    #Each object passed should be an instance of a subclass of
    #Crypt::Perl::X509::Extension
    my $exreq = Crypt::Perl::PKCS10::Attribute::extensionRequest->new( @EXTN_OBJS );

    #...or:

    my $exreq = Crypt::Perl::PKCS10::Attribute::extensionRequest->new(
        [ $extn_type1 => @args1 ],
        [ $extn_type2 => @args2 ],
    );

    #...for example:

    my $exreq = Crypt::Perl::PKCS10::Attribute::extensionRequest->new(
        [ 'subjectAltName', dNSName => 'foo.com', dNSName => 'haha.tld' ],
    );

=head1 DESCRIPTION

Instances of this class represent an C<extensionRequest> attribute of a
PKCS #10 Certificate Signing Request (CSR).

You probably don’t need to
instantiate this class directly; instead, you can instantiate it
implicitly by listing out arguments to
L<Crypt::Perl::PKCS10>’s constructor. See that module’s
L<SYNOPSIS|Crypt::Perl::PKCS10/SYNOPSIS> for an example.

Look in the L<Crypt::Perl> distribution’s
C<Crypt::Perl::X509::Extension> namespace for supported extensions.

=cut

use Try::Tiny;

use parent qw( Crypt::Perl::PKCS10::Attribute );

use Module::Load ();

use Crypt::Perl::ASN1 ();
use Crypt::Perl::X ();

use constant OID => '1.2.840.113549.1.9.14';

use constant ASN1 => <<END;
    Extension ::= SEQUENCE {
      extnID    OBJECT IDENTIFIER,
      critical  BOOLEAN OPTIONAL,
      extnValue OCTET STRING
    }

    extensionRequest ::= SEQUENCE OF Extension
END

my $EXT_BASE = 'Crypt::Perl::X509::Extension';

sub new {
    my ($class, @extensions) = @_;

    for my $ext (@extensions) {
        if (!try { $ext->isa($EXT_BASE) }) {
            if ( 'HASH' eq ref $ext ) {
                if ( !try { $ext->{'extension'}->isa($EXT_BASE) }) {
                    if ( 'ARRAY' ne ref $ext ) {
                        die Crypt::Perl::X::create('Generic', "“extension” in HASH reference must be ARRAY reference or instance of $EXT_BASE, not “$ext”!");
                    }
                }
            }
            elsif ( 'ARRAY' ne ref $ext ) {
                die Crypt::Perl::X::create('Generic', "Extension must be HASH reference, ARRAY reference, or instance of $EXT_BASE, not “$ext”!");
            }
        }
    }

    return bless \@extensions, $class;
}

sub _new_parse_arrayref {
    my ($ext) = @_;
    my $module = $ext->[0];
    my $class = "Crypt::Perl::X509::Extension::$module";
    Module::Load::load($class);
    return $class->new( @{$ext}[ 1 .. $#$ext ] );
}

sub _encode_params {
    my ($self) = @_;

    my @exts_asn1;

    for my $ext ( @$self ) {
        my ($critical, $real_ext);
        if ('HASH' eq ref $ext) {
            ($critical, $real_ext) = @{$ext}{ qw(critical extension) };
        }
        elsif ('ARRAY' eq ref $ext) {
            $real_ext = _new_parse_arrayref($ext);
        }
        else {
            $real_ext = $ext;
        }

        push @exts_asn1, {
            extnID => $real_ext->OID(),
            ($critical ? (critical => Crypt::Perl::ASN1->ASN_BOOLEAN()) : ()),
            extnValue => $real_ext->encode(),
        },
    };

    return \@exts_asn1;
}

1;
