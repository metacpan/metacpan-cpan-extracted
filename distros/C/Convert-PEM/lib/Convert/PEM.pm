package Convert::PEM;
use strict;
use 5.008_001;

use base qw( Class::ErrorHandler );

use MIME::Base64;
use Digest::MD5 qw( md5 );
use Convert::ASN1;
use Carp qw( croak );
use Convert::PEM::CBC;
use Crypt::PRNG qw( random_bytes );


use vars qw( $VERSION $DefaultCipher );
our $VERSION = '0.12'; # VERSION

our $DefaultCipher = 'DES-EDE3-CBC';

sub new {
    my $class = shift;
    my $pem = bless { }, $class;
    $pem->init(@_);
}

sub init {
    my $pem = shift;
    my %param = @_;
    unless (exists $param{Name}) {
        return (ref $pem)->error("init: Name is required");
    }
    else {
        $pem->{Name} = $param{Name};
        $pem->{ASN} = $param{ASN} if exists $param{ASN};
        $pem->{Cipher} = $param{Cipher} if exists $param{Cipher};
    }

    if (exists $pem->{ASN}) {
        $pem->{Macro} = $param{Macro};
        my $asn = $pem->{_asn} = Convert::ASN1->new;
        $asn->prepare( $pem->{ASN} ) or
            return (ref $pem)->error("ASN prepare failed: $asn->{error}");
    }

    $pem->_getform(%param) or return;
    $pem;
}

sub _getform {
    my $pem = shift;
    my %param = @_;

    my $in = uc($param{InForm}) || 'PEM';
    $in =~ m/^(PEM|DER)$/ or return $pem->error("Invalid InForm '$in': must be PEM or DER");
    $pem->{InForm} = $in;

    my $out = uc($param{OutForm}) || 'PEM';
    $out =~ m/^(PEM|DER)$/ or return $pem->error("Invalid OutForm '$out': must be PEM or DER");
    $pem->{OutForm} = $out;
    $pem;
}

sub asn {
    my $pem = shift;
    my $asn = $pem->{_asn} || return;
    my %prm = @_;
    my $m = $prm{Macro} || $pem->{Macro};
    $m ? $asn->find($m) : $asn;
}

sub ASN     { $_[0]->{ASN}     }
sub name    { $_[0]->{Name}    }
sub cipher  { $_[0]->{Cipher}  }
sub inform  { $_[0]->{InForm}  }
sub outform { $_[0]->{OutForm} }
sub macro   { $_[0]->{Macro}   }

sub read {
    my $pem = shift;
    my %param = @_;

    my $blob;
    my $fname = delete $param{Filename};
    open my $FH, $fname or
        return $pem->error("Can't open $fname: $!");
    binmode $FH;
    read($FH, $blob, -s $fname);
    close $FH;

    $pem->{InForm} eq 'DER'
        ? $pem->from_der( DER => $blob )
        : $pem->decode(%param, Content => $blob);
}

sub write {
    my $pem = shift;
    my %param = @_;

    my $fname = delete $param{Filename} or
        return $pem->error("write: Filename is required");

    my $blob = $pem->{OutForm} eq 'DER'
        ? $pem->to_der(%param)
        : $pem->encode(%param);

    open my $FH, ">$fname" or
        return $pem->error("Can't open $fname: $!");
    binmode $FH;
    print $FH $blob;
    close $FH;
    $blob;
}

sub from_der {
    my $pem = shift;
    my %param = @_;

    # should always be unencrypted at this point
    my $obj;
    if (exists $pem->{ASN}) {
        my $asn = $pem->asn;
        if (my $macro = ($param{Macro} || $pem->{Macro})) {
            $asn = $asn->find($macro) or
                return $pem->error("Can't find Macro $macro");
        }
        $obj = $asn->decode( $param{DER} ) or
            return $pem->error("ASN encode failed: $asn->{error}");
    }
    else {
        $obj = $param{DER};
    }
    $obj;
}

sub decode {
    my $pem = shift;
    my %param = @_;
    if (exists $param{DER}) { return $pem->from_der(%param) }
    my $blob = $param{Content} or
        return $pem->error("'Content' is required");
    chomp $blob;

    my $dec = $pem->explode($blob) or return;
    my $name = $param{Name} || $pem->name;
    return $pem->error("Object $dec->{Object} does not match " . $name)
        unless $dec->{Object} eq $name;

    my $head = $dec->{Headers};
    my $buf = $dec->{Content};
    my %headers = map { $_->[0] => $_->[1] } @$head;
    if (%headers && $headers{'Proc-Type'} eq '4,ENCRYPTED') {
        $buf = $pem->decrypt( Ciphertext => $buf,
                              Info       => $headers{'DEK-Info'},
                              Password   => $param{Password} )
            or return;
    }

    my $obj = $pem->from_der( DER => $buf )
        or return;

    $obj;
}

sub to_der {
    my $pem = shift;
    my %param = @_;

    my $buf;
    if (exists $pem->{ASN}) {
        my $asn = $pem->asn;
        if (my $macro = ($param{Macro} || $pem->{Macro})) {
            $asn = $asn->find($macro) or
                return $pem->error("Can't find Macro $macro");
        }
        $buf = $asn->encode( $param{Content} ) or
            return $pem->error("ASN encode failed: $asn->{error}");
    }
    else {
        $buf = $param{Content}
    }
    $buf;
}

sub encode {
    my $pem = shift;
    my %param = @_;

    my $buf = $param{DER} || $pem->to_der(%param);
    my (@headers);
    if ($param{Password}) {
        my ($info);
        ($buf, $info) = $pem->encrypt( Plaintext => $buf,
                                       %param )
            or return;
        push @headers, [ 'Proc-Type' => '4,ENCRYPTED' ];
        push @headers, [ 'DEK-Info'  => $info ];
    }

    $pem->implode( Object  => $param{Name} || $pem->name,
                   Headers => \@headers,
                   Content => $buf );
}

sub explode {
    my $pem = shift;
    my ($message) = @_;

    # Canonicalize line endings into "\n".
    $message =~ s/\r\n|\n|\r/\n/g;

    my ($head, $object, $headers, $content, $tail) = $message =~ 
        m:(-----BEGIN ([^\n\-]+)-----)\n(.*?\n\n)?(.+)(-----END .*?-----)$:s;
    my $buf = decode_base64($content);

    my @headers;
    if ($headers) {
        for my $h ( split /\n/, $headers ) {
            my ($k, $v) = split /:\s*/, $h, 2;
            push @headers, [ $k => $v ] if $k;
        }
    }

    { Content => $buf,
      Object  => $object,
      Headers => \@headers }
}

sub implode {
    my $pem = shift;
    my %param = @_;
    my $head = "-----BEGIN $param{Object}-----"; 
    my $tail = "-----END $param{Object}-----";
    my $content = encode_base64( $param{Content}, '' );
    $content =~ s!(.{1,64})!$1\n!g;
    my $headers = join '',
                  map { "$_->[0]: $_->[1]\n" }
                  @{ $param{Headers} };
    $headers .= "\n" if $headers;
    "$head\n$headers$content$tail\n";
}

use vars qw( %CTYPES );
%CTYPES = (
    'DES-CBC'           =>    {c => 'Crypt::DES',         ks=>8,  bs=>8,  },
    'DES-EDE3-CBC'      =>    {c => 'Crypt::DES_EDE3',    ks=>24, bs=>8,  },
    'AES-128-CBC'       =>    {c => 'Crypt::Rijndael',    ks=>16, bs=>16, },
    'AES-192-CBC'       =>    {c => 'Crypt::Rijndael',    ks=>24, bs=>16, },
    'AES-256-CBC'       =>    {c => 'Crypt::Rijndael',    ks=>32, bs=>16, },
    'CAMELLIA-128-CBC'  =>    {c => 'Crypt::Camellia',    ks=>16, bs=>16, },
    'CAMELLIA-192-CBC'  =>    {c => 'Crypt::Camellia',    ks=>24, bs=>16, },
    'CAMELLIA-256-CBC'  =>    {c => 'Crypt::Camellia',    ks=>32, bs=>16, },
    'IDEA-CBC'          =>    {c => 'Crypt::IDEA',        ks=>16, bs=>8,  },
    'SEED-CBC'          =>    {c => 'Crypt::SEED',        ks=>16, bs=>16, },
);

#### cipher module support and configuration
sub list_ciphers { return wantarray ? sort keys %CTYPES : join(':', sort keys %CTYPES); }

sub list_cipher_modules {
    # expect a cipher name, if found, return the module name used for encryption/decryption
    my $pem = ref($_[0]) || $_[0] eq __PACKAGE__ ? shift : '';
    if (defined $_[0]) {
        my $cn = has_cipher(shift) || return undef;
        return $CTYPES{$cn}->{c};
    }
    return wantarray
        ? map { $CTYPES{$_}->{c} } sort keys %CTYPES
        : join(':', map { $CTYPES{$_}->{c} } sort keys %CTYPES);
}

sub has_cipher {
    # expect a cipher name, return the cipher name if found
    my $pem = ref($_[0]) || $_[0] eq __PACKAGE__ ? shift : '';
    my $cn = uc(+shift);
    return $cn if exists $CTYPES{$cn} && exists $CTYPES{$cn}->{c};
    # try to figure out what cipher is meant in an overkill fashion
    $cn =~ s/(DES.*3|3DES|EDE)|(DES)|([a-zA-Z]+)(?:-?(\d+)(?:-?(\w+))?)/
        if ($1) {
            'DES-EDE3-CBC'
        } elsif ($2) {
            'DES-CBC'
        }
        else {
            $3.($4 ? "-".$4 : "").($5 ? "-$5" : "")
        }
    /e;
    my @c = sort grep { $_ =~ m/$cn/ } keys %CTYPES;
    # return undef unless @c;
    $c[0];
}

sub has_cipher_module
{
    my $pem = ref($_[0]) || $_[0] eq __PACKAGE__ ? shift : '';
    if (my $cn = has_cipher($_[0])) {
        eval "use $CTYPES{$cn}->{c};";
        if ($@) { undef $@; return undef; }
        return $CTYPES{$cn}->{c};
    }
}

sub set_cipher_module
{
    my $pem = ref($_[0]) || $_[0] eq __PACKAGE__ ? shift : '';
    # cipher name, cipher module name, replace all
    my ($cn,$cm,$all) = @_;
    $all = 1 unless defined $all;
    # when setting ciphers, must use exact name
    if (exists $CTYPES{$cn}) {
        eval "use $cm ;";
        if ($@) { undef $@; return undef; }
        if ($all && exists $CTYPES{$cn}->{c}) {
            my $old_cm = $CTYPES{$cn}->{c};
            foreach my $def (values %CTYPES) {
                $def->{c} = $cm if $def->{c} eq $old_cm;
            }
        }
        else {
            $CTYPES{$cn}->{c} = $cm;
        }
        return $cm;
    }
    return undef;
}

#### cipher functions
sub decrypt {
    my $pem = shift;
    my %param = @_;
    my $passphrase = $param{Password} || "";
    my ($ctype, $iv) = split /,/, $param{Info};
    my $cmod = $CTYPES{$ctype} or
        return $pem->error("Unrecognized cipher: '$ctype'");
    $iv = pack "H*", $iv;
    eval "use $cmod->{c}; 1;" || croak "Failed loading cipher module '$cmod->{c}'";
    my $key = Convert::PEM::CBC::bytes_to_key($passphrase,$iv,\&md5,$cmod->{ks});
    my $cm = $cmod->{c}; $cm =~ s/^Crypt::(?=IDEA$)//; # fix IDEA
    my $cbc = Convert::PEM::CBC->new(
                   Cipher     => $cm->new($key),
                   IV         => $iv );
    my $buf = $cbc->decrypt($param{Ciphertext}) or
        return $pem->error("Decryption failed: " . $cbc->errstr);
    $buf;
}

sub encrypt {
    my $pem = shift;
    my %param = @_;
    $param{Password} or return $param{Plaintext};

    $param{Cipher} = $DefaultCipher if !$param{Cipher};
    my $ctype = $pem->has_cipher( $param{Cipher} );
    my $cmod = $CTYPES{$ctype} or
        return $pem->error("Unrecognized cipher: '$ctype'");
    eval "use $cmod->{c}; 1;" || croak "Error loading cypher module '$cmod->{c}'";

    ## allow custom IV for encryption
    my $iv = $pem->_getiv(%param, bs => $cmod->{bs}) or return;
    my $key = Convert::PEM::CBC::bytes_to_key( $param{Password}, $iv, \&md5, $cmod->{ks} );
    my $cm = $cmod->{c}; $cm =~ s/^Crypt::(?=IDEA$)//; # fix IDEA
    my $cbc = Convert::PEM::CBC->new(
                    IV            =>    $iv,
                    Cipher        =>    $cm->new($key) );
    my $iv = uc join '', unpack "H*", $cbc->iv;
    my $buf = $cbc->encrypt($param{Plaintext}) or
        return $pem->error("Encryption failed: " . $cbc->errstr);
    ($buf, "$ctype,$iv");
}

sub _getiv {
    my $pem = shift;
    my %p = @_;

    my $iv;
    if (exists $p{IV}) {
        if ($p{IV} =~ m/^[a-fA-F\d]+$/) {
            $iv = pack("H*",$p{IV});
            return length($iv) == $p{bs}
                ? $iv
                : $pem->error("Provided IV length is invalid");
        }
        else {
            return $pem->error("Provided IV must be in hex format");
        }
    }
    $iv = random_bytes($p{bs});
    croak "Internal error: unexpected IV length" if length($iv) != $p{bs};
    $iv;
}

1;
__END__

=head1 NAME

Convert::PEM - Read/write encrypted ASN.1 PEM files

=head1 SYNOPSIS

    use Convert::PEM;
    my $pem = Convert::PEM->new(
                   Name => "DSA PRIVATE KEY",
                   Macro => "DSAPrivateKey",
                   ASN => qq(
                       DSAPrivateKey SEQUENCE {
                           version INTEGER,
                           p INTEGER,
                           q INTEGER,
                           g INTEGER,
                           pub_key INTEGER,
                           priv_key INTEGER
                       }
                  ));

    my $keyfile = 'private-key.pem';
    my $pwd = 'foobar';

    my $pkey = $pem->read(
                   Filename => $keyfile,
                   Password => $pwd
             );

    $pem->write(
                   Content  => $pkey,
                   Password => $pwd,
                   Filename => $keyfile
             );

=head1 DESCRIPTION

I<Convert::PEM> reads and writes PEM files containing ASN.1-encoded
objects. The files can optionally be encrypted using a symmetric
cipher algorithm, such as 3DES. An unencrypted PEM file might look
something like this:

    -----BEGIN DH PARAMETERS-----
    MB4CGQDUoLoCULb9LsYm5+/WN992xxbiLQlEuIsCAQM=
    -----END DH PARAMETERS-----

The string beginning C<MB4C...> is the Base64-encoded, ASN.1-encoded
"object."

An encrypted file would have headers describing the type of
encryption used, and the initialization vector:

    -----BEGIN DH PARAMETERS-----
    Proc-Type: 4,ENCRYPTED
    DEK-Info: DES-EDE3-CBC,C814158661DC1449

    AFAZFbnQNrGjZJ/ZemdVSoZa3HWujxZuvBHzHNoesxeyqqidFvnydA==
    -----END DH PARAMETERS-----

The two headers (C<Proc-Type> and C<DEK-Info>) indicate information
about the type of encryption used, and the string starting with
C<AFAZ...> is the Base64-encoded, encrypted, ASN.1-encoded
contents of this "object."

The initialization vector (C<C814158661DC1449>) is chosen randomly.

=head1 USAGE

=head2 $pem = Convert::PEM->new( %arg )

Constructs a new I<Convert::PEM> object designed to read/write an
object of a specific type (given in I<%arg>, see below). Returns the
new object on success, C<undef> on failure (see I<ERROR HANDLING> for
details).

I<%arg> can contain:

=over 4

=item * Name

The name of the object; when decoding a PEM-encoded stream, the name
in the encoding will be checked against the value of I<Name>.
Similarly, when encoding an object, the value of I<Name> will be used
as the name of the object in the PEM-encoded content. For example, given
the string C<FOO BAR>, the output from I<encode> will start with a
header like:

    -----BEGIN FOO BAR-----

I<Name> is a required argument.

=item * ASN

An ASN.1 description of the content to be either encoded or decoded.

I<ASN> is an optional argument.

=item * Macro

If your ASN.1 description (in the I<ASN> parameter) includes more than
one ASN.1 macro definition, you will want to use the I<Macro> parameter
to specify which definition to use when encoding/decoding objects.
For example, if your ASN.1 description looks like this:

    Foo ::= SEQUENCE {
        x INTEGER,
        bar Bar
    }

    Bar ::= INTEGER

If you want to encode/decode a C<Foo> object, you will need to tell
I<Convert::PEM> to use the C<Foo> macro definition by using the I<Macro>
parameter and setting the value to C<Foo>.

I<Macro> is an optional argument when an ASN.1 description is provided.

=item * InForm

Specify what type of file to expect when using the I<read> method.  Value
may be either B<PEM> or B<DER>. Default is "PEM".

If "DER" is specified, encryption options are ignored when using the
I<read> method and file is read as an unencrypted blob. This option does
not affect the I<decode> behavior.

I<InForm> is an optional argument.

=item * OutForm

Specify what type of file the I<write> method should output.  Value may be
either B<PEM> or B<DER>. Default is "PEM".

If "DER" is specified, encryption options are ignored when using the
I<write> method and the file is written as an uncrypted blob. This option
does not affect the I<encode> behavior.

I<OutForm> is an optional argument.

=back

=head2 $obj = $pem->decode(%args)

Decodes, and, optionally, decrypts a PEM file, returning the
object as decoded by I<Convert::ASN1>. The difference between this
method and I<read> is that I<read> reads the contents of a PEM file
on disk; this method expects you to pass the PEM contents as an
argument.

If an error occurs while reading the file or decrypting/decoding
the contents, the function returns I<undef>, and you should check
the error message using the I<errstr> method (below).

I<%args> can contain:

=over 4

=item * Content

The PEM contents.

=item * Password

The password with which the file contents were encrypted.

If the file is encrypted, this is a mandatory argument (well, it's
not strictly mandatory, but decryption isn't going to work without
it). Otherwise it's not necessary.

=back

=head2 $blob = $pem->encode(%args)

Constructs the contents for the PEM file from an object: ASN.1-encodes
the object, optionally encrypts those contents.

Returns I<undef> on failure (encryption failure, file-writing failure,
etc.); in this case you should check the error message using the
I<errstr> method (below). On success returns the constructed PEM string.

I<%args> can contain:

=over 4

=item * Content

This method requires either Content or DER.  An error will be generated
if one of these arguments are not present.

A hash reference that will be passed to I<Convert::ASN1::encode>,
and which should correspond to the ASN.1 description you gave to the
I<new> method. The hash reference should have the exact same format
as that returned from the I<read> method.

This is required unless DER is specified.

=item * DER

A string containing actual binary of the contents to be encoded. This
bypasses ASN.1 encoding.

May be used in lieu of Content.  If specified, will override Content.

=item * Password

A password used to encrypt the contents of the PEM file. This is an
optional argument; if not provided the contents will be unencrypted.

=item * Cipher

The Cipher to use if a password is provided.  This is an optional
argument; if not provided, the default of B<DES-EDE3-CBC> will be used
or the cipher configured is B<$Convert::PEM::DefaultCipher>. See below
for a list of supported ciphers.

=back

=head2 $obj = $pem->read(%args)

Reads, decodes, and, optionally, decrypts a PEM file, returning
the object as decoded by I<Convert::ASN1> (or binary blob if ASN.1
description was not provided). This is implemented as a wrapper
around I<decode>, with the bonus of reading the PEM file from disk
for you.

If an error occurs while reading the file or decrypting/decoding
the contents, the function returns I<undef>, and you should check
the error message using the I<errstr> method (below).

In addition to the arguments that can be passed to the I<decode>
method (minus the I<Content> argument), I<%args> can contain:

=over 4

=item * Filename

The location of the PEM file that you wish to read.

=item * InForm

Specify what file type to read.  Description can be found under I<new>
method.  If specified, will override InForm provided in I<new> method.

=back

=head2 $pem->write(%args)

Constructs the contents for the PEM file from an object: ASN.1-encodes
the object, optionally encrypts those contents; then writes the file
to disk. This is implemented as a wrapper around I<encode>, with the
bonus of writing the file to disk for you.

Returns I<undef> on failure (encryption failure, file-writing failure,
etc.); in this case you should check the error message using the
I<errstr> method (below). On success returns the constructed PEM string.

In addition to the arguments for I<encode>, I<%args> can contain:

=over 4

=item * Filename

The location on disk where you'd like the PEM file written.

=item * OutForm

Specify format to write out. Description can be found under I<new> method.
If specified, will override OutForm provided in I<new> method.

=back

=head2 $pem->from_der(%args)

Method used internally, but may be accessed directly decode an ASN.1 string
into a perl structure object.  If the Convert::PEM object has no ASN.1
definition, this method has no effect.

=over 4

=item * DER

Binary string to convert to an object.

This option is required.

=item * Macro

If the object has an ASN definition, a Macro may be specified. If specified,
it will override the object's Macro if one exists.

Macro is an optional argument.

=back

=head2 $pem->to_der(%args)

Method used internally, but may be accessed directly to encode Content into
binary data.  If the Convert::PEM object has no ASN.1 definition, this
method has no effect.

=over 4

=item * Content

An object to be ASN.1 encoded to a binary string.

=item * Macro

If the object has an ASN definition, a Macro may be specified. If specified,
it will override the object's Macro if one exists.

Macro is an optional argument.

=back

=head2 $pem->errstr

Returns the value of the last error that occurred. This should only
be considered meaningful when you've received I<undef> from one of
the functions above; in all other cases its relevance is undefined.

=head2 $pem->asn

Returns the I<Convert::ASN1> object used internally to decode and
encode ASN.1 representations. This is useful when you wish to
interact directly with that object; for example, if you need to
call I<configure> on that object to set the type of big-integer
class to be used when decoding/encoding big integers:

    $pem->asn->configure( decode => { bigint => 'Math::Pari' },
                          encode => { bigint => 'Math::Pari' } );


=head2 $pem->inform

Retruns the I<InForm> configured for the object.

=head2 $pem->outform

Retruns the I<OutForm> configured for the object.

=head2 $pem->cipher

Returns the I<Cipher> configured for the object.

=head2 $pem->name

Returns the PEM I<Name> of the object.

=head1 CONFIGURATION

To support any encryption/decryption, the appropriate cipher module needs
to be installed.

Some settings may be viewed or configured through variables or methods.

Configuration settings are global to the package. If a setting is changed,
it affects all Convert::PEM objects.

=head2 $Convert::PEM::DefaultCipher I<or> $OBJ->DefaultCipher(I<[NEW_CIPHER]>)

Used to configure a default cipher when writing to the disk. When using
the method form C< $OBJ->DefaultCipher([NEW_CIPHER]) >, if NEW_CIPHER
is not specified, will return the current setting.  If the specified
cipher is not recognized/valid, an error will be raised.

To list supported ciphers, use C<Convert::PEM::list_ciphers>. Here is a
list of supported Ciphers:

=over 4

=item * DES-CBC

=item * DES-EDE3-CBC

=item * AES-128-CBC

=item * AES-192-CBC

=item * AES-256-CBC

=item * CAMELLIA-128-CBC

=item * CAMELLIA-192-CBC

=item * CAMELLIA-256-CBC

=item * IDEA-CBC

=item * SEED-CBC

=back

=head2 Convert::PEM->has_cipher(I<$cipher_name>)

Will see if the cipher is supported and is configured with an encryption
module.

=head2 Convert::PEM->has_cipher_module(I<$cipher_name>)

Will see if the cipher is supported and if the configured encryption
module is usable.  If it is not usable, will return C<undef>.  If it is
usable, will return the name of the cipher module.

=head2 Convert::PEM->set_cipher_module($cipher,$module[,$all])

This function/method  is used to specify a module name for a supported
cipher.  It accepts 2 or 3 arguments.

    Convert::PEM->set_cipher_module(<cipher_name>, <module_name>[,0])
    or
    $OBJ->set_cipher_module(<cipher_name>, <module_name>[,0])

=over 4

=item C<cipher_name>

A supported cipher name. Use Convert::PEM::list_ciphers() to retrieve a
list of supported ciphers.

=item C<module_name>

A cipher module.  The module must support the following methods:

    $cipher_object = Cipher->new($key)
    $cipher_object->encrypt($plaintext)
    $cipher_object->decrypt($ciphertext)
    $cipher_object->blocksize()

=item C<all>

An optional boolean argument.  If true will replace the modules for all
supported ciphers matching the cipher being set.  Default is true. If
setting a cipher, only set this to false if it is desired to use a
separate cipher for different key lengths of the same algorithm.

=back

=head2 Convert::PEM->list_cipher_modules([$cipher_name])

If a I<cipher_name> is provided, will return the module configured for
the matching cipher name or C<undef> if cipher is not supported.
If I<cipher_name> is not provided, will return a list of modules names
configured as an array in array context or as a colon separated list in
scalar context.

Here is a list of the cipher modules used by default.

=over 4

=item * L<Crypt::DES>

=item * L<Crypt::DES_EDE3>

=item * L<Crypt::Rijndael> - C<AES-128-CBC, AES-192-CBC and AES-256-CBC>

=item * L<Crypt::Camellia> - C<CAMELLIA-128-CBC, CAMELLIA-192-CBC and CAMELLIA-256-CBC>

=item * Crypt::L<IDEA>

=item * L<Crypt::SEED>

=back

=head1 ERROR HANDLING

If an error occurs in any of the above methods, the method will return
C<undef>. You should then call the method I<errstr> to determine the
source of the error:

    $pem->errstr

In the case that you do not yet have a I<Convert::PEM> object (that is,
if an error occurs while creating a I<Convert::PEM> object), the error
can be obtained as a class method:

    Convert::PEM->errstr

For example, if you try to decode an encrypted object, and you do not
give a passphrase to decrypt the object:

    my $obj = $pem->read( Filename => "encrypted.pem" )
        or die "Decryption failed: ", $pem->errstr;

=head1 LICENSE

Convert::PEM is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHTS

Except where otherwise noted, Convert::PEM is Copyright Benjamin
Trott, cpan@stupidfool.org. All rights reserved.

=cut
