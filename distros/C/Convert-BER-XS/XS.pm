=head1 NAME

Convert::BER::XS - I<very> low level BER en-/decoding

=head1 SYNOPSIS

 use Convert::BER::XS ':all';

 my $ber = ber_decode $buf, $Convert::BER::XS::SNMP_PROFILE
    or die "unable to decode SNMP message";

 # The above results in a data structure consisting of
 #    (class, tag, flags, data)
 # tuples. Below is such a message, SNMPv1 trap
 # with a Cisco mac change notification.
 # Did you know that Cisco is in the news almost
 # every week because of some backdoor password
 # or other extremely stupid security bug?

 [ ASN_UNIVERSAL, ASN_SEQUENCE, 1,
   [
      [ ASN_UNIVERSAL, ASN_INTEGER, 0, 0 ], # snmp version 1
      [ ASN_UNIVERSAL, 4, 0, "public" ], # community
      [ ASN_CONTEXT, 4, 1, # CHOICE, constructed - trap PDU
         [
            [ ASN_UNIVERSAL, ASN_OBJECT_IDENTIFIER, 0, "1.3.6.1.4.1.9.9.215.2" ], # enterprise oid
            [ ASN_APPLICATION, SNMP_IPADDRESS, 0, "10.0.0.1" ], # SNMP IpAddress
            [ ASN_UNIVERSAL, ASN_INTEGER, 0, 6 ], # generic trap
            [ ASN_UNIVERSAL, ASN_INTEGER, 0, 1 ], # specific trap
            [ ASN_APPLICATION, SNMP_TIMETICKS, 0, 1817903850 ], # SNMP TimeTicks
            [ ASN_UNIVERSAL, ASN_SEQUENCE, 1, # the varbindlist
               [
                  [ ASN_UNIVERSAL, ASN_SEQUENCE, 1, # a single varbind, "key value" pair
                     [
                        [ ASN_UNIVERSAL, ASN_OBJECT_IDENTIFIER, 0, "1.3.6.1.4.1.9.9.215.1.1.8.1.2.1" ],
                        [ ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "...data..." # the value
                        ]
                     ]
                  ],
                  ...
 # let's dump it, for debugging

 ber_dump $ber, $Convert::BER::XS::SNMP_PROFILE;

 # let's decode it a bit with some helper functions

 my $msg = ber_is_seq $ber
    or die "SNMP message does not start with a sequence";

 ber_is $msg->[0], ASN_UNIVERSAL, ASN_INTEGER, 0
    or die "SNMP message does not start with snmp version\n";

 # message is SNMP v1 or v2c?
 if ($msg->[0][BER_DATA] == 0 || $msg->[0][BER_DATA] == 1) {

    # message is v1 trap?
    if (ber_is $msg->[2], ASN_CONTEXT, 4, 1) {
       my $trap = $msg->[2][BER_DATA];

       # check whether trap is a cisco mac notification mac changed message
       if (
          (ber_is_oid $trap->[0], "1.3.6.1.4.1.9.9.215.2") # cmnInterfaceObjects
          and (ber_is_int $trap->[2], 6)
          and (ber_is_int $trap->[3], 1) # mac changed msg
       ) {
          ... and so on

 # finally, let's encode it again and hope it results in the same bit pattern

 my $buf = ber_encode $ber, $Convert::BER::XS::SNMP_PROFILE;

=head1 DESCRIPTION

WARNING: Before release 1.0, the API is not considered stable in any way.

This module implements a I<very> low level BER/DER en-/decoder.

It is tuned for low memory and high speed, while still maintaining some
level of user-friendlyness.

=head2 EXPORT TAGS AND CONSTANTS

By default this module doesn't export any symbols, but if you don't want
to break your keyboard, editor or eyesight with extremely long names, I
recommend importing the C<:all> tag. Still, you can selectively import
things.

=over

=item C<:all>

All of the below. Really. Recommended for at least first steps, or if you
don't care about a few kilobytes of wasted memory (and namespace).

=item C<:const>

All of the strictly ASN.1-related constants defined by this module, the
same as C<:const_asn :const_index>. Notably, this does not contain
C<:const_ber_type> and C<:const_snmp>.

A good set to get everything you need to decode and match BER data would be
C<:decode :const>.

=item C<:const_index>

The BER tuple array index constants:

        BER_CLASS BER_TAG BER_FLAGS BER_DATA

=item C<:const_asn>

ASN class values (these are C<0>, C<1>, C<2> and C<3>, respectively -
exactly the two topmost bits from the identifier octet shifted 6 bits to
the right):

      ASN_UNIVERSAL ASN_APPLICATION ASN_CONTEXT ASN_PRIVATE

ASN tag values (some of which are aliases, such as C<ASN_OID>). Their
numerical value corresponds exactly to the numbers used in BER/X.690.

      ASN_BOOLEAN ASN_INTEGER ASN_BIT_STRING ASN_OCTET_STRING ASN_NULL ASN_OID
      ASN_OBJECT_IDENTIFIER ASN_OBJECT_DESCRIPTOR ASN_EXTERNAL ASN_REAL ASN_SEQUENCE ASN_ENUMERATED
      ASN_EMBEDDED_PDV ASN_UTF8_STRING ASN_RELATIVE_OID ASN_SET ASN_NUMERIC_STRING
      ASN_PRINTABLE_STRING ASN_TELETEX_STRING ASN_T61_STRING ASN_VIDEOTEX_STRING ASN_IA5_STRING
      ASN_ASCII_STRING ASN_UTC_TIME ASN_GENERALIZED_TIME ASN_GRAPHIC_STRING ASN_VISIBLE_STRING
      ASN_ISO646_STRING ASN_GENERAL_STRING ASN_UNIVERSAL_STRING ASN_CHARACTER_STRING ASN_BMP_STRING

=item C<:const_ber_type>

The BER type constants, explained in the PROFILES section.

      BER_TYPE_BYTES BER_TYPE_UTF8 BER_TYPE_UCS2 BER_TYPE_UCS4 BER_TYPE_INT
      BER_TYPE_OID BER_TYPE_RELOID BER_TYPE_NULL BER_TYPE_BOOL BER_TYPE_REAL
      BER_TYPE_IPADDRESS BER_TYPE_CROAK

=item C<:const_snmp>

Constants only relevant to SNMP. These are the tag values used by SNMP in
the C<ASN_APPLICATION> namespace and have the exact numerical value as in
BER/RFC 2578.

      SNMP_IPADDRESS SNMP_COUNTER32 SNMP_UNSIGNED32 SNMP_GAUGE32
      SNMP_TIMETICKS SNMP_OPAQUE SNMP_COUNTER64

=item C<:decode>

C<ber_decode> and the match helper functions:

      ber_decode ber-decode_prefix
      ber_is ber_is_seq ber_is_int ber_is_oid
      ber_dump

=item C<:encode>

C<ber_encode> and the construction helper functions:

      ber_encode
      ber_int

=back

=head2 ASN.1/BER/DER/... BASICS

ASN.1 is a strange language that can be used to describe protocols and
data structures. It supports various mappings to JSON, XML, but most
importantly, to a various binary encodings such as BER, that is the topic
of this module, and is used in SNMP, LDAP or X.509 for example.

While ASN.1 defines a schema that is useful to interpret encoded data,
the BER encoding is actually somewhat self-describing: you might not know
whether something is a string or a number or a sequence or something else,
but you can nevertheless decode the overall structure, even if you end up
with just a binary blob for the actual value.

This works because BER values are tagged with a type and a namespace,
and also have a flag that says whether a value consists of subvalues (is
"constructed") or not (is "primitive").

Tags are simple integers, and ASN.1 defines a somewhat weird assortment
of those - for example, you have one integers and 16(!) different
string types, but there is no Unsigned32 type for example. Different
applications work around this in different ways, for example, SNMP defines
application-specific Gauge32, Counter32 and Unsigned32, which are mapped
to two different tags: you can distinguish between Counter32 and the
others, but not between Gause32 and Unsigned32, without the ASN.1 schema.

Ugh.

=head2 DECODED BER REPRESENTATION

This module represents every BER value as a 4-element tuple (actually an
array-reference):

   [CLASS, TAG, FLAGS, DATA]

For example:

   [ASN_UNIVERSAL, ASN_INTEGER, 0, 177]       # the integer 177
   [ASN_UNIVERSAL, ASN_OCTET_STRING, 0, "john"] # the string "john"
   [ASN_UNIVERSAL, ASN_OID, 0, "1.3.6.133"]     # some OID
   [ASN_UNIVERSAL, ASN_SEQUENCE, 1, [ [ASN_UNIVERSAL... # a sequence

To avoid non-descriptive hardcoded array index numbers, this module
defines symbolic constants to access these members: C<BER_CLASS>,
C<BER_TAG>, C<BER_FLAGS> and C<BER_DATA>.

Also, the first three members are integers with a little caveat: for
performance reasons, these are readonly and shared, so you must not modify
them (increment, assign to them etc.) in any way. You may modify the
I<DATA> member, and you may re-assign the array itself, e.g.:

   $ber = ber_decode $binbuf;

   # the following is NOT legal:
   $ber->[BER_CLASS] = ASN_PRIVATE; # ERROR, CLASS/TAG/FLAGS are READ ONLY(!)

   # but all of the following are fine:
   $ber->[BER_DATA] = "string";
   $ber->[BER_DATA] = [ASN_UNIVERSAL, ASN_INTEGER, 0, 123];
   @$ber = (ASN_APPLICATION, SNMP_TIMETICKS, 0, 1000);

I<CLASS> is something like a namespace for I<TAG>s - there is the
C<ASN_UNIVERSAL> namespace which defines tags common to all ASN.1
implementations, the C<ASN_APPLICATION> namespace which defines tags for
specific applications (for example, the SNMP C<Unsigned32> type is in this
namespace), a special-purpose context namespace (C<ASN_CONTEXT>, used e.g.
for C<CHOICE>) and a private namespace (C<ASN_PRIVATE>).

The meaning of the I<TAG> depends on the namespace, and defines a
(partial) interpretation of the data value. For example, SNMP defines
extra tags in the C<ASN_APPLICATION> namespace, and to take full advantage
of these, you need to tell this module how to handle those via profiles.

The most common tags in the C<ASN_UNIVERSAL> namespace are
C<ASN_INTEGER>, C<ASN_BIT_STRING>, C<ASN_NULL>, C<ASN_OCTET_STRING>,
C<ASN_OBJECT_IDENTIFIER>, C<ASN_SEQUENCE>, C<ASN_SET> and
C<ASN_IA5_STRING>.

The most common tags in SNMP's C<ASN_APPLICATION> namespace are
C<SNMP_COUNTER32>, C<SNMP_UNSIGNED32>, C<SNMP_TIMETICKS> and
C<SNMP_COUNTER64>.

The I<FLAGS> value is really just a boolean at this time (but might
get extended) - if it is C<0>, the value is "primitive" and contains
no subvalues, kind of like a non-reference perl scalar. If it is C<1>,
then the value is "constructed" which just means it contains a list of
subvalues which this module will en-/decode as BER tuples themselves.

The I<DATA> value is either a reference to an array of further tuples
(if the value is I<FLAGS>), some decoded representation of the value, if
this module knows how to decode it (e.g. for the integer types above) or
a binary string with the raw octets if this module doesn't know how to
interpret the namespace/tag.

Thus, you can always decode a BER data structure and at worst you get a
string in place of some nice decoded value.

See the SYNOPSIS for an example of such an encoded tuple representation.

=head2 DECODING AND ENCODING

=over

=item $tuple = ber_decode $bindata[, $profile]

Decodes binary BER data in C<$bindata> and returns the resulting BER
tuple. Croaks on any decoding error, so the returned C<$tuple> is always
valid.

How tags are interpreted is defined by the second argument, which must
be a C<Convert::BER::XS::Profile> object. If it is missing, the default
profile will be used (C<$Convert::BER::XS::DEFAULT_PROFILE>).

In addition to rolling your own, this module provides a
C<$Convert::BER::XS::SNMP_PROFILE> that knows about the additional SNMP
types.

Example: decode a BER blob using the default profile - SNMP values will be
decided as raw strings.

   $tuple = ber_decode $data;

Example: as above, but use the provided SNMP profile.

   $tuple = ber_encode $data, $Convert::BER::XS::SNMP_PROFILE;

=item ($tuple, $bytes) = ber_decode_prefix $bindata[, $profile]

Works like C<ber_decode>, except it doesn't croak when there is data after
the BER data, but instead returns the decoded value and the number of
bytes it decoded.

This is useful when you have BER data at the start of a buffer and other
data after, and you need to find the length.

Also, since BER is self-delimited, this can be used to decode multiple BER
values joined together.

=item $bindata = ber_encode $tuple[, $profile]

Encodes the BER tuple into a BER/DER data structure. As with
Cyber_decode>, an optional profile can be given.

The encoded data should be both BER and DER ("shortest form") compliant
unless the input says otherwise (e.g. it uses constructed strings).

=back

=head2 HELPER FUNCTIONS

Working with a 4-tuple for every value can be annoying. Or, rather, I<is>
annoying. To reduce this a bit, this module defines a number of helper
functions, both to match BER tuples and to construct BER tuples:

=head3 MATCH HELPERS

These functions accept a BER tuple as first argument and either partially
or fully match it. They often come in two forms, one which exactly matches
a value, and one which only matches the type and returns the value.

They do check whether valid tuples are passed in and croak otherwise. As
a ease-of-use exception, they usually also accept C<undef> instead of a
tuple reference, in which case they silently fail to match.

=over

=item $bool = ber_is $tuple, $class, $tag, $flags, $data

This takes a BER C<$tuple> and matches its elements against the provided
values, all of which are optional - values that are either missing or
C<undef> will be ignored, the others will be matched exactly (e.g. as if
you used C<==> or C<eq> (for C<$data>)).

Some examples:

   ber_is $tuple, ASN_UNIVERSAL, ASN_SEQUENCE, 1
      orf die "tuple is not an ASN SEQUENCE";

   ber_is $tuple, ASN_UNIVERSAL, ASN_NULL
      or die "tuple is not an ASN NULL value";

   ber_is $tuple, ASN_UNIVERSAL, ASN_INTEGER, 0, 50
      or die "BER integer must be 50";

=item $seq = ber_is_seq $tuple

Returns the sequence members (the array of subvalues) if the C<$tuple> is
an ASN SEQUENCE, i.e. the C<BER_DATA> member. If the C<$tuple> is not a
sequence it returns C<undef>. For example, SNMP version 1/2c/3 packets all
consist of an outer SEQUENCE value:

   my $ber = ber_decode $snmp_data;

   my $snmp = ber_is_seq $ber
      or die "SNMP packet invalid: does not start with SEQUENCE";

   # now we know $snmp is a sequence, so decode the SNMP version

   my $version = ber_is_int $snmp->[0]
      or die "SNMP packet invalid: does not start with version number";

=item $bool = ber_is_int $tuple, $int

Returns a true value if the C<$tuple> represents an ASN INTEGER with
the value C<$int>.

=item $int = ber_is_int $tuple

Returns true (and extracts the integer value) if the C<$tuple> is an
C<ASN_INTEGER>. For C<0>, this function returns a special value that is 0
but true.

=item $bool = ber_is_oid $tuple, $oid_string

Returns true if the C<$tuple> represents an ASN_OBJECT_IDENTIFIER
that exactly matches C<$oid_string>. Example:

   ber_is_oid $tuple, "1.3.6.1.4"
      or die "oid must be 1.3.6.1.4";

=item $oid = ber_is_oid $tuple

Returns true (and extracts the OID string) if the C<$tuple> is an ASN
OBJECT IDENTIFIER. Otherwise, it returns C<undef>.

=back

=head3 CONSTRUCTION HELPERS

=over

=item $tuple = ber_int $value

Constructs a new C<ASN_INTEGER> tuple.

=back

=head2 RELATIONSHIP TO L<Convert::BER> and L<Convert::ASN1>

This module is I<not> the XS version of L<Convert::BER>, but a different
take at doing the same thing. I imagine this module would be a good base
for speeding up either of these, or write a similar module, or write your
own LDAP or SNMP module for example.

=cut

package Convert::BER::XS;

use common::sense;

use XSLoader ();
use Exporter qw(import);

use Carp ();

our $VERSION;

BEGIN {
   $VERSION = 1.21;
   XSLoader::load __PACKAGE__, $VERSION;
}

our %EXPORT_TAGS = (
   const_index => [qw(
      BER_CLASS BER_TAG BER_FLAGS BER_DATA
   )],
   const_asn_class => [qw(
      ASN_UNIVERSAL ASN_APPLICATION ASN_CONTEXT ASN_PRIVATE
   )],
   const_asn_tag => [qw(
      ASN_BOOLEAN ASN_INTEGER ASN_BIT_STRING ASN_OCTET_STRING ASN_NULL ASN_OID ASN_OBJECT_IDENTIFIER
      ASN_OBJECT_DESCRIPTOR ASN_EXTERNAL ASN_REAL ASN_SEQUENCE ASN_ENUMERATED
      ASN_EMBEDDED_PDV ASN_UTF8_STRING ASN_RELATIVE_OID ASN_SET ASN_NUMERIC_STRING
      ASN_PRINTABLE_STRING ASN_TELETEX_STRING ASN_T61_STRING ASN_VIDEOTEX_STRING ASN_IA5_STRING
      ASN_ASCII_STRING ASN_UTC_TIME ASN_GENERALIZED_TIME ASN_GRAPHIC_STRING ASN_VISIBLE_STRING
      ASN_ISO646_STRING ASN_GENERAL_STRING ASN_UNIVERSAL_STRING ASN_CHARACTER_STRING ASN_BMP_STRING
   )],
   const_ber_type => [qw(
      BER_TYPE_BYTES BER_TYPE_UTF8 BER_TYPE_UCS2 BER_TYPE_UCS4 BER_TYPE_INT
      BER_TYPE_OID BER_TYPE_RELOID BER_TYPE_NULL BER_TYPE_BOOL BER_TYPE_REAL
      BER_TYPE_IPADDRESS BER_TYPE_CROAK
   )],
   const_snmp => [qw(
      SNMP_IPADDRESS SNMP_COUNTER32 SNMP_GAUGE32 SNMP_UNSIGNED32
      SNMP_TIMETICKS SNMP_OPAQUE SNMP_COUNTER64
   )],
   decode => [qw(
      ber_decode ber_decode_prefix
      ber_is ber_is_seq ber_is_int ber_is_oid
      ber_dump
   )],
   encode => [qw(
      ber_encode
      ber_int
   )],
);

our @EXPORT_OK = map @$_, values %EXPORT_TAGS;

$EXPORT_TAGS{all}       = \@EXPORT_OK;
$EXPORT_TAGS{const_asn} = [map @{ $EXPORT_TAGS{$_} }, qw(const_asn_class const_asn_tag)];
$EXPORT_TAGS{const}     = [map @{ $EXPORT_TAGS{$_} }, qw(const_index const_asn)];

our $DEFAULT_PROFILE = new Convert::BER::XS::Profile;

$DEFAULT_PROFILE->_set_default;

# additional SNMP application types
our $SNMP_PROFILE = new Convert::BER::XS::Profile;

$SNMP_PROFILE->set (ASN_APPLICATION, SNMP_IPADDRESS , BER_TYPE_IPADDRESS);
$SNMP_PROFILE->set (ASN_APPLICATION, SNMP_COUNTER32 , BER_TYPE_INT);
$SNMP_PROFILE->set (ASN_APPLICATION, SNMP_UNSIGNED32, BER_TYPE_INT);
$SNMP_PROFILE->set (ASN_APPLICATION, SNMP_TIMETICKS , BER_TYPE_INT);

# decodes REAL values according to ECMA-63
# this is pretty strict, except it doesn't catch -0.
# I don't have access to ISO 6093 (or BS 6727, or ANSI X.3-42)), so this is all guesswork.
sub _decode_real_decimal {
   my ($format, $val) = @_;

   $val =~ y/,/./; # probably not in ISO-6093

   if ($format == 1) {
      $val =~ /^ \ * [+-]? [0-9]+ \z/x
         or Carp::croak "BER_TYPE_REAL NR1 value not in NR1 format ($val) (X.690 8.5.8)";
   } elsif ($format == 2) {
      $val =~ /^ \ * [+-]? (?: [0-9]+\.[0-9]* | [0-9]*\.[0-9]+ ) \z/x
         or Carp::croak "BER_TYPE_REAL NR2 value not in NR2 format ($val) (X.690 8.5.8)";
   } elsif ($format == 3) {
      $val =~ /^ \ * [+-] (?: [0-9]+\.[0-9]* | [0-9]*\.[0-9]+ ) [eE] [+-]? [0-9]+ \z/x
         or Carp::croak "BER_TYPE_REAL NR3 value not in NR3 format ($val) (X.690 8.5.8)";
   } else {
      Carp::croak "BER_TYPE_REAL invalid decimal numerical representation format $format";
   }

   $val
}

# this is a mess, but perl's support for floating point formatting is nearly nonexistant
sub _encode_real_decimal {
   my ($val, $nvdig) = @_;

   $val = sprintf "%.*G", $nvdig + 1, $val;

   if ($val =~ /E/) {
      $val =~ s/E(?=[^+-])/E+/;
      $val =~ s/E/.E/ if $val !~ /\./;
      $val =~ s/^/+/  unless $val =~ /^-/;

      return "\x03$val" # NR3
   }

   $val =~ /\./
     ? "\x02$val" # NR2
     : "\x01$val" # NR1
}

=head2 DEBUGGING

To aid debugging, you can call the C<ber_dump> function to print a "nice"
representation to STDOUT.

=over

=item ber_dump $tuple[, $profile[, $prefix]]

In addition to specifying the BER C<$tuple> to dump, you can also specify
a C<$profile> and a C<$prefix> string that is printed in front of each line.

If C<$profile> is C<$Convert::BER::XS::SNMP_PROFILE>, then C<ber_dump>
will try to improve its output for SNMP data.

The output usually contains three columns, the "human readable" tag, the
BER type used to decode it, and the data value.

This function is somewhat slow and uses a number of heuristics and tricks,
so it really is only suitable for debug prints.

Example output:

   SEQUENCE
   | OCTET_STRING     bytes  800063784300454045045400000001
   | OCTET_STRING     bytes
   | CONTEXT (7)      CONSTRUCTED
   | | INTEGER          int    1058588941
   | | INTEGER          int    0
   | | INTEGER          int    0
   | | SEQUENCE
   | | | SEQUENCE
   | | | | OID              oid    1.3.6.1.2.1.1.3.0
   | | | | TIMETICKS        int    638085796

=back

=cut

# reverse enum, very slow and ugly hack
sub _re {
   my ($export_tag, $value) = @_;

   for my $symbol (@{ $EXPORT_TAGS{$export_tag} }) {
      $value == eval $symbol
         and return $symbol;
   }

   "($value)"
}

$SNMP_PROFILE->set (ASN_APPLICATION, SNMP_COUNTER64 , BER_TYPE_INT);

sub _ber_dump {
   my ($ber, $profile, $indent) = @_;

   if (my $seq = ber_is_seq $ber) {
      printf "%sSEQUENCE\n", $indent;
      &_ber_dump ($_, $profile, "$indent| ")
         for @$seq;
   } else {
      my $asn = $ber->[BER_CLASS] == ASN_UNIVERSAL;

      my $class = _re const_asn_class => $ber->[BER_CLASS];
      my $tag   = $asn ? _re const_asn_tag => $ber->[BER_TAG] : $ber->[BER_TAG];
      my $type  = _re const_ber_type => $profile->get ($ber->[BER_CLASS], $ber->[BER_TAG]);
      my $data  = $ber->[BER_DATA];

      if ($profile == $SNMP_PROFILE and $ber->[BER_CLASS] == ASN_APPLICATION) {
         $tag = _re const_snmp => $ber->[BER_TAG];
      } elsif (!$asn) {
         $tag = "$class ($tag)";
      }

      $class =~ s/^ASN_//;
      $tag   =~ s/^(ASN_|SNMP_)//;
      $type  =~ s/^BER_TYPE_//;

      if ($ber->[BER_FLAGS]) {
         printf "$indent%-16.16s\n", $tag;
         &_ber_dump ($_, $profile, "$indent| ")
            for @$data;
      } else {
         if ($data =~ y/\x20-\x7e//c / (length $data || 1) > 0.2 or $data =~ /\x00./s) {
            # assume binary
            $data = unpack "H*", $data;
         } else {
            $data =~ s/[^\x20-\x7e]/./g;
            $data = "\"$data\"" if $tag =~ /string/i || !length $data;
         }

         substr $data, 40, 1e9, "..." if 40 < length $data;

         printf "$indent%-16.16s %-6.6s %s\n", $tag, lc $type, $data;
      }
   }
}

sub ber_dump($;$$) {
   _ber_dump $_[0], $_[1] || $DEFAULT_PROFILE, $_[2];
}

=head1 PROFILES

While any BER data can be correctly encoded and decoded out of the box, it
can be inconvenient to have to manually decode some values into a "better"
format: for instance, SNMP TimeTicks values are decoded into the raw octet
strings of their BER representation, which is quite hard to decode. With
profiles, you can change which class/tag combinations map to which decoder
function inside C<ber_decode> (and of course also which encoder functions
are used in C<ber_encode>).

This works by mapping specific class/tag combinations to an internal "ber
type".

The default profile supports the standard ASN.1 types, but no
application-specific ones. This means that class/tag combinations not in
the base set of ASN.1 are decoded into their raw octet strings.

C<Convert::BER::XS> defines two profile variables you can use out of the box:

=over

=item C<$Convert::BER::XS::DEFAULT_PROFILE>

This is the default profile, i.e. the profile that is used when no
profile is specified for de-/encoding.

You can modify it, but remember that this modifies the defaults for all
callers that rely on the default profile.

=item C<$Convert::BER::XS::SNMP_PROFILE>

A profile with mappings for SNMP-specific application tags added. This is
useful when de-/encoding SNMP data.

Example:

   $ber = ber_decode $data, $Convert::BER::XS::SNMP_PROFILE;

=back

=head2 The Convert::BER::XS::Profile class

=over

=item $profile = new Convert::BER::XS::Profile

Create a new profile. The profile will be identical to the default
profile.

=item $profile->set ($class, $tag, $type)

Sets the mapping for the given C<$class>/C<$tag> combination to C<$type>,
which must be one of the C<BER_TYPE_*> constants.

Note that currently, the mapping is stored in a flat array, so large
values of C<$tag> will consume large amounts of memory.

Example:

   $profile = new Convert::BER::XS::Profile;
   $profile->set (ASN_APPLICATION, SNMP_COUNTER32, BER_TYPE_INT);
   $ber = ber_decode $data, $profile;

=item $type = $profile->get ($class, $tag)

Returns the BER type mapped to the given C<$class>/C<$tag> combination.

=back

=head2 BER Types

This lists the predefined BER types. BER types are formatters used
internally to format and encode BER values. You can assign any C<BER_TYPE>
to any C<CLASS>/C<TAG> combination tgo change how that tag is decoded or
encoded.

=over

=item C<BER_TYPE_BYTES>

The raw octets of the value. This is the default type for unknown tags and
de-/encodes the value as if it were an octet string, i.e. by copying the
raw bytes.

=item C<BER_TYPE_UTF8>

Like C<BER_TYPE_BYTES>, but decodes the value as if it were a UTF-8 string
(without validation!) and encodes a perl unicode string into a UTF-8 BER
string.

=item C<BER_TYPE_UCS2>

Similar to C<BER_TYPE_UTF8>, but treats the BER value as UCS-2 encoded
string.

=item C<BER_TYPE_UCS4>

Similar to C<BER_TYPE_UTF8>, but treats the BER value as UCS-4 encoded
string.

=item C<BER_TYPE_INT>

Encodes and decodes a BER integer value to a perl integer scalar. This
should correctly handle 64 bit signed and unsigned values.

=item C<BER_TYPE_OID>

Encodes and decodes an OBJECT IDENTIFIER into dotted form without leading
dot, e.g. C<1.3.6.1.213>.

=item C<BER_TYPE_RELOID>

Same as C<BER_TYPE_OID> but uses relative object identifier
encoding: ASN.1 has this hack of encoding the first two OID components
into a single integer in a weird attempt to save an insignificant amount
of space in an otherwise wasteful encoding, and relative OIDs are
basically OIDs without this hack. The practical difference is that the
second component of an OID can only have the values 1..40, while relative
OIDs do not have this restriction.

=item C<BER_TYPE_NULL>

Decodes an C<ASN_NULL> value into C<undef>, and always encodes a
C<ASN_NULL> type, regardless of the perl value.

=item C<BER_TYPE_BOOL>

Decodes an C<ASN_BOOLEAN> value into C<0> or C<1>, and encodes a perl
boolean value into an C<ASN_BOOLEAN>.

=item C<BER_TYPE_REAL>

Decodes/encodes a BER real value. NOT IMPLEMENTED.

=item C<BER_TYPE_IPADDRESS>

Decodes/encodes a four byte string into an IPv4 dotted-quad address string
in Perl. Given the obsolete nature of this type, this is a low-effort
implementation that simply uses C<sprintf> and C<sscanf>-style conversion,
so it won't handle all string forms supported by C<inet_aton> for example.

=item C<BER_TYPE_CROAK>

Always croaks when encountered during encoding or decoding - the
default behaviour when encountering an unknown type is to treat it as
C<BER_TYPE_BYTES>. When you don't want that but instead prefer a hard
error for some types, then C<BER_TYPE_CROAK> is for you.

=back

=head2 Example Profile

The following creates a profile suitable for SNMP - it's exactly identical
to the C<$Convert::BER::XS::SNMP_PROFILE> profile.

   our $SNMP_PROFILE = new Convert::BER::XS::Profile;

   $SNMP_PROFILE->set (ASN_APPLICATION, SNMP_IPADDRESS , BER_TYPE_IPADDRESS);
   $SNMP_PROFILE->set (ASN_APPLICATION, SNMP_COUNTER32 , BER_TYPE_INT);
   $SNMP_PROFILE->set (ASN_APPLICATION, SNMP_UNSIGNED32, BER_TYPE_INT);
   $SNMP_PROFILE->set (ASN_APPLICATION, SNMP_TIMETICKS , BER_TYPE_INT);
   $SNMP_PROFILE->set (ASN_APPLICATION, SNMP_OPAQUE    , BER_TYPE_BYTES);
   $SNMP_PROFILE->set (ASN_APPLICATION, SNMP_COUNTER64 , BER_TYPE_INT);

=head2 LIMITATIONS/NOTES

This module can only en-/decode 64 bit signed and unsigned
integers/tags/lengths, and only when your perl supports those. So no UUID
OIDs for now (unless you map the C<OBJECT IDENTIFIER> tag to something
other than C<BER_TYPE_OID>).

This module does not generally care about ranges, i.e. it will happily
de-/encode 64 bit integers into an C<SNMP_UNSIGNED32> value, or a negative
number into an C<SNMP_COUNTER64>.

OBJECT IDENTIFIEERs cannot have unlimited length, although the limit is
much larger than e.g. the one imposed by SNMP or other protocols, and is
about 4kB.

Constructed strings are decoded just fine, but there should be a way to
join them for convenience.

REAL values will always be encoded in decimal form and ssometimes is
forced into a perl "NV" type, potentially losing precision.

=head2 ITHREADS SUPPORT

This module is unlikely to work in any other than the loading thread when
the (officially discouraged) ithreads are in use.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://software.schmorp.de/pkg/Convert-BER-XS

=cut

1;

