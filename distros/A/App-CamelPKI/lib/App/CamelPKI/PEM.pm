#!perl -w

package App::CamelPKI::PEM;
use strict;

=head1 NAME

B<App::CamelPKI::PEM> - Base class for all model classes that manipulate
PEM strings

=head1 DESCRIPTION

L<Crypt::OpenSSL::CA::AlphabetSoup/PEM> means I<Privacy Enhanced
Mail>. The PEM system and protocol suite, an early precursor to PGP,
is all but fallen into oblivion these days; in the PKIX world, it
survives as an SMTP-safe cryptographic payload encapsulation format
that states the type of the payload (which "native" ASN.1 format like
DER, don't). The general syntax is:

   -----BEGIN FOO----
   <Base64-encoded ASN.1>
   -----END FOO----

The I<App::CamelPKI::PEM> class is a superclass to all model classes which
manipulate such formats, such as L<App::CamelPKI::PrivateKey>,
L<App::CamelPKI::PublicKey>, L<App::CamelPKI::Certificate> and L<App::CamelPKI::CRL>.

=cut

use MIME::Base64;
use File::Slurp;

=head1 METHODS

=head2 parse($text, %args)

Decodes $text, a plain string, and returns an object of the class in
which this method his invoked.  Available named arguments are:

=over

=item I< -format => "PEM" >

=item I< -format => "DER" >

The format of $text. By default, an automatic detection is performed.

=back

=cut

sub parse {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        if (@_ % 2);
    my ($class, $text, %args) = @_;
    throw App::CamelPKI::Error::Internal("ABSTRACT_METHOD")
        if ($class eq __PACKAGE__);

    # Some JSON objects stringify to undef!  In this case, Perl
    # converts them into the null string, with a warning.
    { no warnings; $text = "$text" if defined $text; }
    throw App::CamelPKI::Error::Internal("INCORRECT_ARGS")
        if (! $text);

    if (! exists $args{-format}) {
        $args{-format} = ($text =~ m/^-+BEGIN/) ?
            "PEM" : "DER";
    }

    # The canonical format is DER because it is smaller, plus it's The
    # Right Thing for structural equality tests.
    if ($args{-format} eq "DER") {
        return bless { der => $text }, $class;
    } elsif ($args{-format} eq "PEM") {
        my $marker = $class->_marker;
        unless ($text =~ m/-+BEGIN\ \Q$marker\E-+$
                           (.*?)
                           ^-+END\ \Q$marker\E-+$/gmsx) {
            throw App::CamelPKI::Error::Internal("INCORRECT_ARGS");
        }
        return bless { der => decode_base64($1) }, $class;
    } else {
        throw App::CamelPKI::Error::Internal
            ("INCORRECT_ARGS",
             -details => "Unknown $class format $args{-format}");
    }
}

=head2 load($fileName, %args)

Loads an object from a file on the file system.  Named arguments are
the same as for L</parse>.

=cut

sub load {
	my($class, $filename, %args) = @_;
	$class->parse(scalar(read_file($filename)), %args);
}

=head2 serialize(%args)

Returns a string representation of the object.  Available named
arguments are:

=over

=item I< -format => "PEM" >

=item I< -format => "DER" >

The format to use for serialization. Default value is "PEM".

=back

=cut

sub serialize {
    throw App::CamelPKI::Error::Internal("WRONG_NUMBER_ARGS")
        unless (@_ % 2);
    my ($self, %args) = @_;
    $args{-format} ||= "PEM";
    if ($args{-format} eq "DER") {
        return $self->{der};
    } elsif ($args{-format} eq "PEM") {
        my $foldedpem = encode_base64($self->{der});
        $foldedpem =~ s/\n//g;
        $foldedpem =~ s/(.{64})/$1\n/g;
        $foldedpem =~ s/\n$//g;
        my $marker = $self->_marker;
        return <<"CERT";
-----BEGIN $marker-----
$foldedpem
-----END $marker-----
CERT
    } else {
        my $class = ref($self);
        throw App::CamelPKI::Error::Internal
            ("INCORRECT_ARGS",
             -details => "unknown $class format $args{-format}");
    }
}


=head2 _marker

This abstract method returns the character chain to use as delimiter
(for example C<RSA PRIVATE KEY> for L<App::CamelPKI::PrivateKey>).

=cut

# Abstract

1;
